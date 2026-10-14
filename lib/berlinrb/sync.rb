# frozen_string_literal: true

require "cgi"
require "json"
require "net/http"
require "open3"
require "rexml/document"
require "time"
require_relative "meetups"

module Berlinrb
  # Pulls meetups from Luma, talks from the Basecamp Talks card table, and
  # recordings from the YouTube channel into data/meetups.yml.
  class Sync
    LUMA_CALENDAR   = "cal-21caVAhECUCuGR6"
    YOUTUBE_CHANNEL = "UCXkuEpnMwzTqGiXRYavRnjw"
    BASECAMP        = %w[basecamp -a 6219432 -p 47498411]
    TALKS_TABLE     = "10403432462"
    THUMBNAILS      = File.expand_path("../../assets/videos", __dir__)
    TIME_ZONE       = "Europe/Berlin"

    attr_reader :log

    def initialize(meetups, today: Date.today, http: method(:get), basecamp: method(:basecamp_cards))
      @meetups = meetups
      @today = today
      @http = http
      @basecamp = basecamp
      @log = []
    end

    def run(sources = %i[basecamp luma youtube])
      ENV["TZ"] = TIME_ZONE
      sources.each { send(:"sync_#{_1}") }
      @meetups
    end

    # Basecamp: Scheduled and Done cards are talks, dated by their due date.

    def sync_basecamp
      cards = @basecamp.call
      return @log << "Basecamp: skipped, the basecamp CLI is not signed in" unless cards
      cards.each do |card|
        next unless %w[Scheduled Done].include?(card.dig("parent", "title")) && card["due_on"]
        meetup = @meetups.on(card["due_on"])
        next @log << "Basecamp: no meetup on #{card["due_on"]} for #{card["title"]}" unless meetup
        fields = self.class.card_fields(card["content"])
        speaker = card["title"].split(": ", 2).first.strip
        talk = meetup["talks"].find { Meetups.same_person?(_1["speaker"], speaker) } || (meetup["talks"] << { "speaker" => speaker }).last
        talk["title"] = fields["Title"] if fields["Title"]
        talk["abstract"] = fields["Abstract"] if fields["Abstract"]
        talk["format"] = fields["Format"] if fields["Format"]
        talk["short_title"] = fields["Short title"] if fields["Short title"]
      end
      @log << "Basecamp: read #{cards.size} cards"
    end

    def self.card_fields(html)
      text = CGI.unescapeHTML(html.gsub(%r{<br\s*/?>|</p>|</div>}, "\n").gsub(/<[^>]+>/, ""))
      fields = {}
      current = nil
      text.each_line do |line|
        line = line.strip
        if (match = line.match(/\A([A-Z][a-z ]+):\s*(.*)\z/))
          current = match[1]
          fields[current] = match[2]
        elsif current && !line.empty?
          fields[current] += "\n\n#{line}"
        end
      end
      fields.transform_values(&:strip).reject { _2.empty? }
    end

    def basecamp_cards
      out, status = Open3.capture2(*BASECAMP, "cards", "list", "--card-table", TALKS_TABLE, "-q", err: File::NULL)
      JSON.parse(out) if status.success?
    rescue Errno::ENOENT, JSON::ParserError
      nil
    end

    # Luma: every Berlin.rb #N event. In person events give the date, venue and
    # signups; online ones are the livestream. A talk on an upcoming meetup is
    # published once the Luma page names its speaker.

    def sync_luma
      events = %w[past future].flat_map { luma_events(_1) }
      events.each do |entry|
        event = entry.fetch("event")
        number = event["name"][/#(\d+)/, 1]&.to_i
        next unless number && event["visibility"] == "public"
        meetup = @meetups.find_or_create(number)
        starts_at = Time.iso8601(event["start_at"]).localtime
        over = starts_at.to_date < @today
        if event["location_type"] == "offline"
          meetup["date"] = starts_at.to_date.to_s
          meetup["starts_at"] = starts_at.strftime("%H:%M")
          meetup["ends_at"] = Time.iso8601(event["end_at"]).localtime.strftime("%H:%M") if event["end_at"]
          meetup["luma"] = event["url"]
          address = event["geo_address_info"] || {}
          # Until a venue is set, Luma only knows the city.
          if address["short_address"].to_s.include?(",")
            meetup["venue"] ||= address["address"]
            meetup["address"] = address["short_address"]
          end
          signups(meetup, "signups_in_person", entry) if over
          describe(meetup) if !over || !meetup["about"]
        else
          meetup["livestream_luma"] = event["url"]
          signups(meetup, "signups_online", entry) if over
        end
      end
      @log << "Luma: read #{events.size} events"
    end

    def luma_events(period)
      entries = []
      cursor = nil
      loop do
        query = { calendar_api_id: LUMA_CALENDAR, period: period, pagination_limit: 50, pagination_cursor: cursor }.compact
        data = JSON.parse(@http.call("https://api.lu.ma/calendar/get-items?#{URI.encode_www_form(query)}"))
        entries.concat(data.fetch("entries"))
        break unless data["has_more"] && (cursor = data["next_cursor"])
      end
      entries
    end

    # Signups only count once a meetup is over: until then they change daily.
    def signups(meetup, key, entry)
      return unless entry["guest_count"].to_i.positive?
      meetup.delete("signups")
      meetup[key] = entry["guest_count"]
    end

    # The Luma page's description becomes the meetup's About section, and a
    # talk on an upcoming meetup is announced once the description names its
    # speaker.
    def describe(meetup)
      data = JSON.parse(@http.call("https://api.lu.ma/url?url=#{URI.encode_www_form_component(meetup["luma"])}")).fetch("data")
      doc = data["description_mirror"] or return
      meetup["about"] = self.class.prose_html(doc)
      text = Meetups.slug(self.class.prose_text(doc))
      meetup["talks"].each { _1["announced"] = true if !_1["announced"] && text.include?(Meetups.slug(_1["speaker"])) }
    rescue StandardError => error
      @log << "Luma: could not read the description of ##{meetup["number"]} (#{error.message})"
    end

    BLOCKS = { "paragraph" => "p", "bullet_list" => "ul", "ordered_list" => "ol", "list_item" => "li", "blockquote" => "blockquote" }.freeze

    # Luma descriptions are ProseMirror documents. Only a known set of nodes
    # and marks becomes HTML, and every text is escaped.
    def self.prose_html(node)
      case node["type"]
      when "doc" then (node["content"] || []).map { prose_html(_1) }.reject(&:empty?).join("\n")
      when "text" then marked(CGI.escapeHTML(node["text"].to_s), node["marks"] || [])
      when "hard_break" then "<br>"
      when "heading" then "<h3>#{inline(node)}</h3>"
      when *BLOCKS.keys
        tag = BLOCKS[node["type"]]
        inner = %w[paragraph].include?(node["type"]) ? inline(node) : (node["content"] || []).map { prose_html(_1) }.join
        inner = inner.delete_prefix("<p>").delete_suffix("</p>") if node["type"] == "list_item" && node["content"]&.size == 1
        inner.strip.empty? ? "" : "<#{tag}>#{inner}</#{tag}>"
      else (node["content"] || []).map { prose_html(_1) }.join
      end
    end

    def self.inline(node) = (node["content"] || []).map { prose_html(_1) }.join

    def self.marked(html, marks)
      marks.reduce(html) do |result, mark|
        case mark["type"]
        when "bold" then "<strong>#{result}</strong>"
        when "italic" then "<em>#{result}</em>"
        when "code" then "<code>#{result}</code>"
        when "link"
          href = mark.dig("attrs", "href").to_s
          href.match?(%r{\Ahttps?://}) ? %(<a href="#{CGI.escapeHTML(href)}">#{result}</a>) : result
        else result
        end
      end
    end

    def self.prose_text(node)
      node["type"] == "text" ? node["text"].to_s : (node["content"] || []).map { prose_text(_1) }.join(" ")
    end

    # YouTube: "Title – Speaker | Berlin.rb" is a talk, "Berlin.rb #N
    # Livestream" is the whole evening.

    def sync_youtube
      feed = REXML::Document.new(@http.call("https://www.youtube.com/feeds/videos.xml?channel_id=#{YOUTUBE_CHANNEL}"))
      videos = feed.get_elements("//entry").map do |entry|
        {
          id: entry.get_text("yt:videoId").to_s,
          title: entry.get_text("title").to_s.strip,
          published: Time.iso8601(entry.get_text("published").to_s).localtime.to_date
        }
      end
      videos.each { attach(_1) }
      @log << "YouTube: read #{videos.size} videos"
    end

    def attach(video)
      if (number = video[:title][/\ABerlin\.rb #(\d+) Livestream\z/i, 1])
        meetup = @meetups.find(number.to_i) or return
        meetup["livestream"] = video[:id]
      elsif (match = video[:title].match(/\A(?<title>.+?)\s+[–—-]\s+(?<speaker>[^–—|]+?)\s*\|\s*Berlin\.rb\z/))
        talk = talk_for(match[:speaker], video) or return
        talk["title"] ||= match[:title]
        talk["video"] = video[:id]
      else
        return
      end
      thumbnail(video[:id])
    end

    def talk_for(speaker, video)
      candidates = @meetups.list
        .select { _1["date"] && Date.parse(_1["date"].to_s) <= video[:published] }
        .sort_by { _1["date"].to_s }
      talks = candidates.flat_map { |meetup| meetup["talks"].map { [meetup, _1] } }
      found = talks.find { |_, talk| talk["video"] == video[:id] } ||
              talks.find { |_, talk| !talk["video"] && Meetups.same_person?(talk["speaker"], speaker) }
      return found.last if found
      meetup = candidates.last or return
      @log << "YouTube: added #{speaker} to ##{meetup["number"]} from #{video[:id]}"
      (meetup["talks"] << { "speaker" => speaker.strip }).last
    end

    def thumbnail(id)
      path = File.join(THUMBNAILS, "#{id}.jpg")
      return if File.exist?(path)
      image = %w[maxresdefault hqdefault].lazy.filter_map { |size| @http.call("https://i.ytimg.com/vi/#{id}/#{size}.jpg") rescue nil }.first
      return unless image
      Dir.mkdir(THUMBNAILS) unless Dir.exist?(THUMBNAILS)
      File.binwrite(path, image)
    end

    def get(url, attempts: 4)
      uri = URI(url)
      attempts.times do |attempt|
        response = Net::HTTP.get_response(uri, { "User-Agent" => "berlinrb.org sync" })
        return response.body if response.is_a?(Net::HTTPSuccess)
        raise "#{uri.host} responded with #{response.code}" unless response.code == "429" && attempt < attempts - 1
        sleep 30 * (attempt + 1)
      end
    end
  end
end
