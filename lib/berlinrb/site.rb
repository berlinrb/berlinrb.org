# frozen_string_literal: true

require "erb"
require "fileutils"
require "json"
require_relative "meetups"
require_relative "photos"
require_relative "luma_description"

module Berlinrb
  # Builds the site into _site: the hand-written pages as they are, the home
  # page's meetup lists, a page per meetup and per talk, and the sitemap.
  class Site
    ROOT      = File.expand_path("../..", __dir__)
    TEMPLATES = File.join(ROOT, "templates")
    STATIC    = %w[index.html styles.css assets photos press imprint privacy cfp CNAME robots.txt .nojekyll].freeze
    ORIGIN    = "https://berlinrb.org"
    API       = ENV.fetch("BERLINRB_API", "https://api.berlinrb.org")
    MARKERS   = {
      "upcoming-meetups" => "home_upcoming",
      "past-meetups" => "home_past",
      "next-meetup" => "home_next",
      "latest-talk" => "home_latest_talk",
      "recent-photos" => "home_photos",
      "site-header" => "header"
    }.freeze

    include ERB::Util

    attr_reader :meetups, :today

    def initialize(meetups, today: Date.today, root: ROOT, out: File.join(ROOT, "_site"))
      @meetups = meetups.list
        .select { _1["date"] }
        .map { |meetup| meetup.merge("date" => Date.parse(meetup["date"].to_s)) }
        .sort_by { _1["date"] }
      @today = today
      @root = root
      @out = out
      @photos = Photos.new(File.join(root, "photos"))
    end

    def build
      FileUtils.rm_rf(@out)
      FileUtils.mkdir_p(@out)
      STATIC.each { |path| FileUtils.cp_r(File.join(@root, path), @out) if File.exist?(File.join(@root, path)) }
      write("index.html", fill(File.read(File.join(@root, "index.html")), "/"))
      %w[press imprint privacy].each do |dir|
        source = File.join(@root, dir, "index.html")
        write("#{dir}/index.html", fill(File.read(source), "/#{dir}/")) if File.exist?(source)
      end
      @meetups.each { |meetup| write("meetups/#{meetup["number"]}/index.html", page("meetup", meetup: meetup)) }
      talks.select { _1["title"] }.each { |talk| write("#{talk_path(talk)}index.html", page("talk", talk: talk)) }
      write("talks/index.html", page("talks"))
      write("photos/index.html", page("photos"))
      write("meetups/index.html", page("meetups"))
      write("get-involved/index.html", page("get_involved"))
      write("sitemap.xml", sitemap)
      @written
    end

    # Data the templates use

    def upcoming = @meetups.select { _1["date"] >= today }
    def past = @meetups.select { _1["date"] < today }.reverse
    def upcoming?(meetup) = meetup["date"] >= today

    # Every Scheduled card is public. Talks follow the order the Luma
    # description lists their speakers (the running order), then Basecamp's.
    def public_talks(meetup)
      text = Meetups.slug(about(meetup).to_s.gsub(/<[^>]+>/, " "))
      meetup["talks"]
        .select { upcoming?(meetup) || _1["title"] }
        .each_with_index
        .sort_by { |talk, index| [text.index(Meetups.slug(talk["speaker"])) || text.size, index] }
        .map(&:first)
    end

    def talks
      @talks ||= past.flat_map { |meetup| public_talks(meetup).map { _1.merge("meetup" => meetup) } } +
                 upcoming.flat_map { |meetup| public_talks(meetup).map { _1.merge("meetup" => meetup) } }
    end

    def recorded_talks = talks.select { _1["video"] }

    def photos(meetup) = (@photo_cache ||= {})[meetup["number"]] ||= @photos.for(meetup["number"])

    def talks_for(meetup)
      talks.select { _1["meetup"].equal?(meetup) }
    end

    # Upcoming meetups show the description written from Basecamp, which Luma
    # catches up with; past ones show what Luma said.
    def about(meetup)
      upcoming?(meetup) ? LumaDescription.html(meetup) : meetup["about"]
    end

    STAGE_MINUTES = 80
    FORMATS = { "Lightning (5 min)" => 5, "Short (20 min)" => 20, "Talk (40 min)" => 40, "Long (55 min)" => 55 }.freeze

    # Minutes of stage time a meetup still has, from its Scheduled cards. A
    # card without a known format counts as a full talk.
    def free_minutes(meetup)
      used = meetup["talks"].sum { _1["format"].to_s[/\((\d+) min\)/, 1]&.to_i || 40 }
      [STAGE_MINUTES - used, 0].max
    end

    def next_meetup = upcoming.first
    def api(path) = "#{API}#{path}"
    def formats = FORMATS
    def latest_talk = past.lazy.flat_map { talks_for(_1).select { |talk| talk["video"] } }.first
    def recent_photos(count) = past.flat_map { |meetup| photos(meetup).map { _1.merge("meetup" => meetup) } }.first(count)

    def signups(meetup)
      parts = meetup.values_at("signups_in_person", "signups_online", "signups").compact
      parts.sum if parts.any?
    end

    # "RubyLLM 2.0: Beyond Agents" is "RubyLLM 2.0" in lists, unless the card
    # sets a short title.
    def short_title(talk)
      talk["short_title"] || talk["title"]&.split(/:\s|\s[-–—]\s/)&.first&.strip
    end

    def talk_names(meetup)
      talks_for(meetup).map { _1["title"] ? "#{short_title(_1)} (#{_1["speaker"]})" : _1["speaker"] }
    end

    def meetup_path(meetup) = "/meetups/#{meetup["number"]}/"
    def talk_path(talk) = "/talks/#{talk["slug"] || Meetups.slug(talk["speaker"], talk["title"])}/"
    def video_url(id) = "https://www.youtube.com/watch?v=#{id}"
    def thumbnail(id) = "/assets/videos/#{id}.jpg"
    def thumbnail?(id) = File.exist?(File.join(@root, "assets/videos/#{id}.jpg"))
    def luma_url(slug) = "https://luma.com/#{slug}"

    def neighbours(meetup)
      index = @meetups.index(meetup)
      [index.positive? ? @meetups[index - 1] : nil, @meetups[index + 1]]
    end

    def long_date(date) = date.strftime("%A %-d %B %Y")
    def short_date(date) = date.strftime("%-d %b %Y")

    def paragraphs(text)
      text.to_s.split(/\n{2,}/).map { "<p>#{h(_1.strip).gsub("\n", "<br>")}</p>" }.join("\n")
    end

    def excerpt(text, words = 40)
      list = text.to_s.split
      list.size > words ? "#{list.first(words).join(" ")}…" : list.join(" ")
    end

    def render_gallery(meetup)
      render("gallery", meetup: meetup).strip
    end

    def render_talk_card(talk, meetup: false)
      render("talk_card", talk: talk, show_meetup: meetup).strip
    end

    def json_ld(data) = JSON.pretty_generate(data).gsub("</", "<\\/")

    def place(meetup)
      { "@type" => "Place", "name" => meetup["venue"] || meetup["address"] || "Berlin",
        "address" => { "@type" => "PostalAddress", "streetAddress" => meetup["address"].to_s.sub(/,\s*Berlin\z/, ""),
                       "addressLocality" => "Berlin", "addressCountry" => "DE" } }
    end

    def event_ld(meetup)
      starts = meetup["starts_at"] ? "#{meetup["date"]}T#{meetup["starts_at"]}:00#{offset(meetup["date"])}" : meetup["date"].to_s
      {
        "@type" => "Event",
        "@id" => "#{ORIGIN}#{meetup_path(meetup)}#event",
        "name" => "Berlin.rb ##{meetup["number"]}",
        "url" => "#{ORIGIN}#{meetup_path(meetup)}",
        "startDate" => starts,
        "endDate" => (meetup["ends_at"] ? "#{meetup["date"]}T#{meetup["ends_at"]}:00#{offset(meetup["date"])}" : nil),
        "eventStatus" => "https://schema.org/EventScheduled",
        "eventAttendanceMode" => meetup["livestream_luma"] ? "https://schema.org/MixedEventAttendanceMode" : "https://schema.org/OfflineEventAttendanceMode",
        "location" => place(meetup),
        "organizer" => { "@id" => "#{ORIGIN}/#organization" },
        "isAccessibleForFree" => true,
        "offers" => meetup["luma"] && { "@type" => "Offer", "url" => luma_url(meetup["luma"]), "price" => 0, "priceCurrency" => "EUR", "availability" => "https://schema.org/InStock" },
        "image" => "#{ORIGIN}/assets/og.png",
        "description" => description(meetup)
      }.compact
    end

    def description(meetup)
      list = talks_for(meetup).map { _1["title"] ? "#{_1["title"]} by #{_1["speaker"]}" : _1["speaker"] }
      at = meetup["venue"] ? " at #{meetup["venue"]}" : ""
      if upcoming?(meetup)
        "Berlin.rb ##{meetup["number"]}, the Ruby meetup for the Berlin Ruby community, on #{long_date(meetup["date"])}#{at}." +
          (list.any? ? " Talks: #{list.join("; ")}." : " Free and open to everyone.")
      else
        "Talks, recordings and photos from Berlin.rb ##{meetup["number"]} on #{long_date(meetup["date"])}#{at}." +
          (list.any? ? " #{list.join("; ")}." : "")
      end
    end

    private

    def offset(date)
      zone = ENV["TZ"]
      ENV["TZ"] = "Europe/Berlin"
      Time.local(date.year, date.month, date.day, 12).strftime("%:z")
    ensure
      ENV["TZ"] = zone
    end

    def page(name, **locals)
      body = render(name, **locals)
      render("layout", body: body, **head(name, **locals))
    end

    def head(name, meetup: nil, talk: nil)
      case name
      when "meetup"
        { title: "Berlin.rb ##{meetup["number"]}: #{talks_for(meetup).map { short_title(_1) || _1["speaker"] }.join(", ").then { _1.empty? ? short_date(meetup["date"]) : _1 }}", description: description(meetup),
          path: meetup_path(meetup), image: photos(meetup).first&.fetch("src") || talks_for(meetup).find { _1["video"] && thumbnail?(_1["video"]) }&.then { thumbnail(_1["video"]) },
          ld: [event_ld(meetup), breadcrumbs([["Meetups", "/#past-meetups"], ["Berlin.rb ##{meetup["number"]}", meetup_path(meetup)]])] }
      when "talk"
        { title: "#{talk["title"]} · #{talk["speaker"]} · Berlin.rb", description: excerpt(talk["abstract"], 30).then { _1.empty? ? "#{talk["title"]}, a talk by #{talk["speaker"]} at Berlin.rb ##{talk["meetup"]["number"]}." : _1 },
          path: talk_path(talk), image: talk["video"] && thumbnail?(talk["video"]) ? thumbnail(talk["video"]) : nil,
          ld: [talk_ld(talk), breadcrumbs([["Berlin.rb ##{talk["meetup"]["number"]}", meetup_path(talk["meetup"])], [talk["title"], talk_path(talk)]])] }
      when "photos"
        { title: "Photos \u00b7 Berlin.rb", description: "Photos from every Berlin.rb, the Ruby meetup for the Berlin Ruby community.",
          path: "/photos/", image: past.lazy.map { photos(_1).first }.find(&:itself)&.fetch("src"), ld: [breadcrumbs([["Photos", "/photos/"]])] }
      when "meetups"
        { title: "Meetups \u00b7 Berlin.rb", description: "Every Berlin.rb meetup, past and upcoming, with talks, recordings and photos.",
          path: "/meetups/", image: nil, ld: [breadcrumbs([["Meetups", "/meetups/"]])] }
      when "get_involved"
        { title: "Get involved \u00b7 Berlin.rb", description: "Give a talk at Berlin.rb, host a meetup at your office, or sponsor one. Tell us and an organizer gets back to you.",
          path: "/get-involved/", image: nil, ld: [breadcrumbs([["Get involved", "/get-involved/"]])] }
      when "talks"
        { title: "Talks · Berlin.rb", description: "Every talk given at Berlin.rb, the Ruby meetup for the Berlin Ruby community, with recordings.",
          path: "/talks/", image: nil, ld: [breadcrumbs([["Talks", "/talks/"]])] }
      end
    end

    def talk_ld(talk)
      return { "@type" => "CreativeWork", "name" => talk["title"], "author" => { "@type" => "Person", "name" => talk["speaker"] } } unless talk["video"]
      {
        "@type" => "VideoObject",
        "name" => "#{talk["title"]} by #{talk["speaker"]}",
        "description" => talk["abstract"].to_s.empty? ? "#{talk["title"]}, a talk by #{talk["speaker"]} at Berlin.rb ##{talk["meetup"]["number"]}." : talk["abstract"],
        "thumbnailUrl" => "#{ORIGIN}#{thumbnail(talk["video"])}",
        "uploadDate" => (talk["video_published"] || talk["meetup"]["date"]).to_s,
        "contentUrl" => video_url(talk["video"]),
        "embedUrl" => "https://www.youtube-nocookie.com/embed/#{talk["video"]}",
        "recordedAt" => { "@id" => "#{ORIGIN}#{meetup_path(talk["meetup"])}#event" }
      }
    end

    def breadcrumbs(items)
      { "@type" => "BreadcrumbList",
        "itemListElement" => ([["Berlin.rb", "/"]] + items).each_with_index.map { |(name, path), i| { "@type" => "ListItem", "position" => i + 1, "name" => name, "item" => "#{ORIGIN}#{path}" } } }
    end

    # Hand-written pages carry markers; each is filled from a template.
    def fill(html, current)
      MARKERS.reduce(html) do |result, (marker, partial)|
        pattern = /(<!-- #{marker}:start -->).*?(\n *<!-- #{marker}:end -->)/m
        next result unless result.match?(pattern)
        indent = result[/\n( *)<!-- #{marker}:start -->/, 1]
        content = render(partial, current: current).strip.lines.map { "#{indent}#{_1}".rstrip }.join("\n")
        result.sub(pattern) { "#{$1}\n#{content}#{$2}" }
      end
    end

    def render(name, **locals)
      scope = binding
      scope.local_variable_set(:site, self)
      locals.each { |key, value| scope.local_variable_set(key, value) }
      template(name).result(scope)
    end

    def template(name)
      @templates ||= {}
      @templates[name] ||= ERB.new(File.read(File.join(TEMPLATES, "#{name}.html.erb")), trim_mode: "-")
    end

    def write(path, content)
      file = File.join(@out, path)
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, content)
      (@written ||= []) << path
    end

    def sitemap
      pages = %w[index.html press/index.html imprint/index.html privacy/index.html].map { [_1.delete_suffix("index.html"), lastmod(_1)] }
      data = lastmod("data/meetups.yml")
      pages += @meetups.map { [meetup_path(_1).delete_prefix("/"), data] }
      pages += talks.select { _1["title"] }.map { [talk_path(_1).delete_prefix("/"), data] }
      pages << ["talks/", data]
      pages << ["photos/", data]
      pages << ["meetups/", data]
      pages << ["get-involved/", data]
      urls = pages.map { |path, date| "  <url><loc>#{ORIGIN}/#{path}</loc>#{date && "<lastmod>#{date}</lastmod>"}</url>" }
      %(<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n#{urls.join("\n")}\n</urlset>\n)
    end

    def lastmod(path)
      date = IO.popen(["git", "-C", @root, "log", "-1", "--format=%cs", "--", path], err: File::NULL, &:read).strip
      date.empty? ? nil : date
    end
  end
end
