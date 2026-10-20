# frozen_string_literal: true

require "cgi"
require "json"
require "net/http"
require "open3"
require "rexml/document"
require "time"
require_relative "meetups"
require_relative "luma_description"

module Berlinrb
  # Pulls meetups from Luma, talks from the Basecamp Talks card table, and
  # recordings from the YouTube channel into data/meetups.yml.
  class Sync
    LUMA_CALENDAR   = "cal-21caVAhECUCuGR6"
    YOUTUBE_CHANNEL = "UCXkuEpnMwzTqGiXRYavRnjw"
    BASECAMP_ACCOUNT = "6219432"
    BASECAMP_PROJECT = "47498411"
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

    def run(sources = %i[basecamp luma youtube luma_todos])
      ENV["TZ"] = TIME_ZONE
      sources.each { send(:"sync_#{_1}") }
      @meetups
    end

    # Basecamp: Scheduled and Done cards are talks, dated by their due date.

    # Basecamp is the source of truth for talks: every meetup gets exactly
    # the Scheduled and Done cards due on its date. Fields only Basecamp knows
    # are replaced; a recording or slides found elsewhere are kept.
    CARD_FIELDS = { "Title" => "title", "Short title" => "short_title", "Abstract" => "abstract", "Format" => "format" }.freeze

    def sync_basecamp
      cards = @basecamp.call
      return @log << "Basecamp: skipped, no token (set BASECAMP_TOKEN or sign in the basecamp CLI)" unless cards
      talks = cards.select { %w[Scheduled Done].include?(_1.dig("parent", "title")) && _1["due_on"] }.group_by { _1["due_on"] }
      (talks.keys - @meetups.list.map { _1["date"].to_s }).each { @log << "Basecamp: no meetup on #{_1} for #{talks[_1].map { |card| card["title"] }.join(", ")}" }
      @meetups.list.each do |meetup|
        before = meetup["talks"]
        meetup["talks"] = (talks[meetup["date"].to_s] || []).map do |card|
          speaker = card["title"].split(": ", 2).first.strip
          talk = before.find { Meetups.same_person?(_1["speaker"], speaker) } || {}
          talk = talk.merge("speaker" => speaker).except("announced")
          fields = self.class.card_fields(card["content"].to_s)
          CARD_FIELDS.each { |label, key| fields[label] ? talk[key] = fields[label] : talk.delete(key) }
          talk
        end
        before.reject { |old| meetup["talks"].any? { Meetups.same_person?(_1["speaker"], old["speaker"]) } }
              .each { @log << "Basecamp: #{_1["speaker"]} is no longer on ##{meetup["number"]}" }
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

    # In CI the token comes from BASECAMP_TOKEN, locally from the signed-in
    # basecamp CLI.
    def basecamp_token
      @basecamp_token ||= ENV["BASECAMP_TOKEN"].to_s.empty? ? cli_token : ENV["BASECAMP_TOKEN"]
    end

    def cli_token
      out, status = Open3.capture2("basecamp", "auth", "token", err: File::NULL)
      out.strip if status.success? && !out.strip.empty?
    rescue Errno::ENOENT
      nil
    end

    def basecamp_cards
      return unless basecamp_token
      table = basecamp_api("buckets/#{BASECAMP_PROJECT}/card_tables/#{TALKS_TABLE}.json")
      table.fetch("lists").select { %w[Scheduled Done].include?(_1["title"]) }.flat_map do |column|
        basecamp_pages(column.fetch("cards_url")).map { _1.merge("parent" => { "title" => column["title"] }) }
      end
    rescue StandardError => error
      @log << "Basecamp: API failed (#{error.message})"
      nil
    end

    def basecamp_pages(url)
      items = []
      while url
        response = basecamp_request(:get, url)
        items.concat(JSON.parse(response.body))
        url = response["Link"].to_s[/<([^>]+)>;\s*rel="next"/, 1]
      end
      items
    end

    def basecamp_api(path, method: :get, body: nil)
      response = basecamp_request(method, "https://3.basecampapi.com/#{BASECAMP_ACCOUNT}/#{path}", body)
      response.body.to_s.empty? ? nil : JSON.parse(response.body)
    end

    def basecamp_request(method, url, body = nil)
      uri = URI(url)
      request = Net::HTTP.const_get(method.capitalize).new(uri, "Authorization" => "Bearer #{basecamp_token}",
                                                               "User-Agent" => "berlinrb.org sync (hello@berlinrb.org)",
                                                               "Content-Type" => "application/json")
      request.body = JSON.dump(body) if body
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { _1.request(request) }
      raise "Basecamp responded with #{response.code} to #{method.upcase} #{uri.path}" unless response.is_a?(Net::HTTPSuccess)
      response
    end

    # Luma descriptions: when an upcoming meetup's Luma text differs from the
    # one written from Basecamp, a to-do asks for it to be pasted into Luma.
    # The to-do is completed once Luma matches.
    LUMA_TODOLIST = "Luma descriptions"
    LUMA_ASSIGNEE = 52488656 # Viktor, who looks after Luma
    TODOSET       = "9950099724"

    def sync_luma_todos
      return @log << "Luma to-dos: skipped, no Basecamp token" unless basecamp_token
      list = luma_todolist
      open = basecamp_pages("https://3.basecampapi.com/#{BASECAMP_ACCOUNT}/buckets/#{BASECAMP_PROJECT}/todolists/#{list["id"]}/todos.json")
      @meetups.list.each do |meetup|
        next unless meetup["date"] && Date.parse(meetup["date"].to_s) >= @today
        LUMA_PAGES.each { |page| luma_todo(list, open, meetup, page) if meetup[page[:about]] }
      end
    rescue StandardError => error
      @log << "Luma to-dos: failed (#{error.message})"
    end

    LUMA_PAGES = [
      { url: "luma", about: "about", write: :html, name: "description" },
      { url: "livestream_luma", about: "livestream_about", write: :livestream_html, name: "livestream description" }
    ].freeze

    def luma_todo(list, open, meetup, page)
      title = "Update the Luma #{page[:name]} for Berlin.rb ##{meetup["number"]}"
      todo = open.find { _1["content"] == title }
      wanted = LumaDescription.public_send(page[:write], meetup)
      if LumaDescription.same?(wanted, meetup[page[:about]])
        return unless todo
        basecamp_api("buckets/#{BASECAMP_PROJECT}/todos/#{todo["id"]}/completion.json", method: :post)
        @log << "Luma to-dos: ##{meetup["number"]}'s #{page[:name]} matches Basecamp, completed the to-do"
      else
        description = %(<p>Luma's #{page[:name]} no longer matches the talks in Basecamp. Copy the Markdown below into the description of <a href="https://luma.com/#{meetup[page[:url]]}">Berlin.rb ##{meetup["number"]} on Luma</a>, replacing what is there. Luma turns it into formatting. This to-do completes itself once Luma matches.</p><pre>#{CGI.escapeHTML(LumaDescription.markdown(wanted))}</pre>)
        return if todo && LumaDescription.same?(todo["description"], description) &&
                  todo["assignees"]&.map { _1["id"] } == [LUMA_ASSIGNEE]
        body = { content: title, description: description, assignee_ids: [LUMA_ASSIGNEE] }
        if todo
          basecamp_api("buckets/#{BASECAMP_PROJECT}/todos/#{todo["id"]}.json", method: :put, body: body)
        else
          basecamp_api("buckets/#{BASECAMP_PROJECT}/todolists/#{list["id"]}/todos.json", method: :post, body: body.merge(notify: true))
        end
        @log << "Luma to-dos: asked for ##{meetup["number"]}'s #{page[:name]} to be updated"
      end
    end

    def luma_todolist
      lists = basecamp_pages("https://3.basecampapi.com/#{BASECAMP_ACCOUNT}/buckets/#{BASECAMP_PROJECT}/todosets/#{TODOSET}/todolists.json")
      lists.find { _1["name"] == LUMA_TODOLIST } ||
        basecamp_api("buckets/#{BASECAMP_PROJECT}/todosets/#{TODOSET}/todolists.json", method: :post,
                     body: { name: LUMA_TODOLIST, description: "<p>Written by the berlinrb.org sync when a meetup's talks change in Basecamp. Paste the text into Luma and the to-do completes itself.</p>" })
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
          describe(meetup, "livestream_luma", "livestream_about") if !over || !meetup["livestream_about"]
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

    # The Luma page's description becomes the meetup's About section.
    def describe(meetup, url = "luma", about = "about")
      data = JSON.parse(@http.call("https://api.lu.ma/url?url=#{URI.encode_www_form_component(meetup[url])}")).fetch("data")
      doc = data["description_mirror"] or return
      meetup[about] = self.class.prose_html(doc)
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
        talk["video"] = video[:id]
      else
        return
      end
      thumbnail(video[:id])
    end

    # Talks come from Basecamp. A video only attaches to a talk already there,
    # so recordings nobody scheduled (a host's welcome, say) stay off the site.
    def talk_for(speaker, video)
      talks = @meetups.list
        .select { _1["date"] && Date.parse(_1["date"].to_s) <= video[:published] }
        .flat_map { |meetup| meetup["talks"] }
      talk = talks.find { _1["video"] == video[:id] } ||
             talks.find { !_1["video"] && Meetups.same_person?(_1["speaker"], speaker) }
      @log << "YouTube: no talk by #{speaker.strip} for #{video[:id]}" unless talk
      talk
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
