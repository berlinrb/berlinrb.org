# frozen_string_literal: true

require "cgi"
require_relative "meetups"

module Berlinrb
  # The Luma description of an upcoming meetup, written from its Basecamp
  # talks. The site shows it, and bin/sync asks in Basecamp for Luma to be
  # updated when Luma's text differs.
  module LumaDescription
    SUBMIT   = %(<a href="https://berlinrb.org/get-involved/#speak">Submit it here</a>)
    WELCOME  = "Whether you&#39;ve been writing Ruby for 15 years or you&#39;re just curious about the language, everyone&#39;s welcome. Food and drinks provided."
    CONTACT  = "Interested in giving a talk at a future meetup, or hosting or sponsoring one? Reach out to hello@berlinrb.org."
    YOUTUBE  = %(<a href="https://www.youtube.com/@berlinrb_org">YouTube channel</a>)
    FILMING  = %(<strong>Filming:</strong> the talks are recorded and published on our #{YOUTUBE}. The camera stands behind the audience and points at the stage, so you may end up in the shot. Tell us at the door if you would rather not be, and we will keep you out of frame.)
    SEATS    = "Please only register here if you&#39;re coming to the venue, so we know how many seats and how much food we need."
    TALKS_PER_MEETUP = 2

    module_function

    def html(meetup)
      paragraphs = ["Berlin.rb is a regular meetup for Berlin&#39;s Ruby community. Join us for talks, food and time to get to know each other."]
      paragraphs.concat(talk_block(meetup["talks"]))
      paragraphs << WELCOME << CONTACT
      paragraphs << if meetup["livestream_luma"]
        %(<strong>Watching from home:</strong> the talks are streamed live. <a href="https://luma.com/#{h(meetup["livestream_luma"])}">Register for the livestream event</a> instead. #{SEATS})
      else
        %(<strong>Watching from home:</strong> the talks are streamed live, with a separate livestream event on <a href="https://luma.com/berlinrb">our calendar</a>. #{SEATS})
      end
      paragraphs << "<strong>Getting there:</strong> #{h(meetup["getting_there"])}" if meetup["getting_there"]
      paragraphs << FILMING
      join(paragraphs)
    end

    def livestream_html(meetup)
      paragraphs = ["Berlin.rb is a regular meetup for Berlin&#39;s Ruby community, and we stream the talks live."]
      paragraphs.concat(talk_block(meetup["talks"]))
      paragraphs << "The stream goes out on our #{YOUTUBE}. Register here and you&#39;ll get a reminder when we go live."
      paragraphs << %(The food and the rest of the evening happen in the room. If you&#39;re in Berlin, come in person instead: the in-person event is on <a href="https://luma.com/berlinrb">our calendar</a>.)
      paragraphs << CONTACT
      paragraphs << "<strong>Recording:</strong> the talks are published on our #{YOUTUBE} afterwards, so you can catch up if the time doesn&#39;t work for you."
      join(paragraphs)
    end

    def talk_block(talks)
      return ["Talks to be announced. Want to give one? #{SUBMIT}."] if talks.empty?

      list = talks.map { "<li><strong>#{h(_1["speaker"])}</strong>: #{_1["title"] ? "#{h(_1["title"])}." : "talk to be announced"}</li>" }
      block = ["<strong>Talks</strong>", "<ul>#{list.join}</ul>"]
      block << "Want to give the second one? #{SUBMIT}." if talks.size < TALKS_PER_MEETUP
      block
    end

    def join(paragraphs) = paragraphs.map { _1.start_with?("<ul>") ? _1 : "<p>#{_1}</p>" }.join("\n")

    def markdown(html)
      html.split("\n").map do |block|
        if block.start_with?("<ul>")
          block.scan(%r{<li>(.*?)</li>}).map { "- #{inline_markdown(_1.first)}" }.join("\n")
        else
          inline_markdown(block.delete_prefix("<p>").delete_suffix("</p>"))
        end
      end.join("\n\n")
    end

    def inline_markdown(html)
      href = nil
      html.split(/(<[^>]+>)/).map do |part|
        case part
        when "<strong>", "</strong>" then "**"
        when /\A<a href="([^"]*)">\z/ then (href = CGI.unescapeHTML(Regexp.last_match(1))) && "["
        when "</a>" then "](#{href})"
        else CGI.unescapeHTML(part).gsub(/([\\`*_\[\]<>])/) { "\\#{Regexp.last_match(1)}" }
        end
      end.join
    end

    # Two descriptions match when their words do, whatever the markup.
    def same?(a, b) = key(a) == key(b)

    def key(html) = Meetups.slug(CGI.unescapeHTML(html.to_s.gsub(/<[^>]+>/, " ")))

    def h(text) = CGI.escapeHTML(text.to_s)
  end
end
