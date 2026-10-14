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
    FILMING  = %(<strong>Filming:</strong> the talks are recorded and published on our <a href="https://www.youtube.com/@berlinrb_org">YouTube channel</a>. The camera stands behind the audience and points at the stage, so you may end up in the shot. Tell us at the door if you would rather not be, and we will keep you out of frame.)
    SEATS    = "Please only register here if you&#39;re coming to the venue, so we know how many seats and how much food we need."
    TALKS_PER_MEETUP = 2

    module_function

    def html(meetup)
      talks = meetup["talks"]
      paragraphs = ["Berlin.rb is a regular meetup for Berlin&#39;s Ruby community. Join us for talks, food and time to get to know each other."]
      if talks.empty?
        paragraphs << "Talks to be announced. Want to give one? #{SUBMIT}."
      else
        paragraphs << "<strong>Talks</strong>"
        list = talks.map { "<li><strong>#{h(_1["speaker"])}</strong>: #{_1["title"] ? "#{h(_1["title"])}." : "talk to be announced"}</li>" }
        paragraphs << "<ul>#{list.join}</ul>"
        paragraphs << "Want to give the second one? #{SUBMIT}." if talks.size < TALKS_PER_MEETUP
      end
      paragraphs << WELCOME << CONTACT
      paragraphs << if meetup["livestream_luma"]
        %(<strong>Watching from home:</strong> the talks are streamed live. <a href="https://luma.com/#{h(meetup["livestream_luma"])}">Register for the livestream event</a> instead. #{SEATS})
      else
        %(<strong>Watching from home:</strong> the talks are streamed live, with a separate livestream event on <a href="https://luma.com/berlinrb">our calendar</a>. #{SEATS})
      end
      paragraphs << "<strong>Getting there:</strong> #{h(meetup["getting_there"])}" if meetup["getting_there"]
      paragraphs << FILMING
      paragraphs.map { _1.start_with?("<ul>") ? _1 : "<p>#{_1}</p>" }.join("\n")
    end

    # Two descriptions match when their words do, whatever the markup.
    def same?(a, b) = key(a) == key(b)

    def key(html) = Meetups.slug(CGI.unescapeHTML(html.to_s.gsub(/<[^>]+>/, " ")))

    def h(text) = CGI.escapeHTML(text.to_s)
  end
end
