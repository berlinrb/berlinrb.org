# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/berlinrb/sync"

class SyncTest < Minitest::Test
  FEED = <<~XML
    <feed xmlns:yt="http://www.youtube.com/xml/schemas/2015">
      <entry><yt:videoId>live2</yt:videoId><title>Berlin.rb #2 Livestream</title><published>2026-10-14T07:09:16+00:00</published></entry>
      <entry><yt:videoId>talk1</yt:videoId><title>HiFuMi - The story of building – Paweł Strzałkowski | Berlin.rb</title><published>2026-10-13T23:01:59+00:00</published></entry>
      <entry><yt:videoId>talk2</yt:videoId><title>Ablefy Digital Businesses – Viktor Schmidt | Berlin.rb</title><published>2026-09-10T17:24:47+00:00</published></entry>
    </feed>
  XML

  def setup
    @dir = Dir.mktmpdir
    @meetups = Berlinrb::Meetups.new([
      { "number" => 1, "date" => "2026-09-08", "talks" => [{ "speaker" => "Pawel Strzalkowski", "title" => "HiFuMi" }] },
      { "number" => 2, "date" => "2026-10-13" },
      { "number" => 3, "date" => "2026-11-10", "talks" => [{ "speaker" => "Andrzej Krzywda" }, { "speaker" => "Marco Roth" }] }
    ], File.join(@dir, "meetups.yml"))
    @requests = []
  end

  def teardown = FileUtils.rm_rf(@dir)

  def sync(cards: [])
    http = lambda do |url|
      @requests << url
      case url
      when /videos\.xml/ then FEED
      when /i\.ytimg\.com/ then "jpeg"
      when /period=past/ then JSON.dump(entries: [luma("Berlin.rb #2 (in person)", "2026-10-13T16:30:00Z", "offline", 64)])
      when /period=future/ then JSON.dump(entries: [luma("Berlin.rb #3 (in person)", "2026-11-10T17:30:00Z", "offline", 20, city_only: true), luma("Berlin.rb #3 (livestream)", "2026-11-10T17:30:00Z", "online", 5)])
      when /event\/get/ then JSON.dump(event: { description: "With Andrzej Krzywda from Arkency" })
      end
    end
    Berlinrb::Sync.new(@meetups, today: Date.new(2026, 10, 14), http: http, basecamp: -> { cards })
  end

  def luma(name, start, type, guests, city_only: false)
    place = city_only ? { address: "Berlin", short_address: "Berlin" } : { address: "Venue", short_address: "Street 1, Berlin" }
    { event: { api_id: "evt-#{name.hash}", name: name, url: name[/#(\d)/, 1] + type, start_at: start, end_at: start.sub(/T\d\d/, "T20"),
               location_type: type, visibility: "public", geo_address_info: place },
      guest_count: guests }
  end

  def test_youtube_attaches_videos_by_speaker_and_livestream_by_number
    stub_const(Berlinrb::Sync, :THUMBNAILS, @dir) { sync.run(%i[youtube]) }

    assert_equal "live2", @meetups.find(2)["livestream"]
    assert_equal "talk1", @meetups.find(1)["talks"].first["video"]
    assert_equal "HiFuMi", @meetups.find(1)["talks"].first["title"]
    viktor = @meetups.find(1)["talks"].last
    assert_equal ["Viktor Schmidt", "Ablefy Digital Businesses", "talk2"], viktor.values_at("speaker", "title", "video")
    assert File.exist?(File.join(@dir, "talk1.jpg"))
  end

  def test_luma_fills_meetups_and_announces_named_speakers
    sync.run(%i[luma])

    two = @meetups.find(2)
    assert_equal ["2026-10-13", "18:30", "Venue", "Street 1, Berlin", 64], two.values_at("date", "starts_at", "venue", "address", "signups")
    three = @meetups.find(3)
    assert_nil three["signups"], "upcoming signups change daily and stay off the site"
    assert_nil three["venue"], "a city alone is not a venue"
    assert_equal "3online", three["livestream_luma"]
    assert_equal [true, nil], three["talks"].map { _1["announced"] }
  end

  def test_basecamp_scheduled_and_done_cards_become_talks
    cards = [
      { "title" => "Andrzej Krzywda: Rails at scale", "due_on" => "2026-11-10", "parent" => { "title" => "Scheduled" },
        "content" => "<p><strong>Format:</strong> Talk (40 min)\n<strong>Title:</strong> Rails at scale\n<strong>Abstract:</strong> One\n\nTwo\n<strong>Contact:</strong> secret@example.com</p>" },
      { "title" => "Someone: Idea", "due_on" => nil, "parent" => { "title" => "Ideas" }, "content" => "" }
    ]
    sync(cards: cards).run(%i[basecamp])

    talk = @meetups.find(3)["talks"].first
    assert_equal ["Rails at scale", "One\n\nTwo", "Talk (40 min)"], talk.values_at("title", "abstract", "format")
    refute_includes talk.to_s, "secret@example.com"
    assert_equal 2, @meetups.find(3)["talks"].size
  end

  def test_basecamp_is_skipped_when_the_cli_is_not_signed_in
    sync = sync(cards: nil)
    sync.instance_variable_set(:@basecamp, -> {})
    sync.run(%i[basecamp])

    assert_match(/skipped/, sync.log.first)
  end

  private

  def stub_const(mod, name, value)
    old = mod.send(:remove_const, name)
    mod.const_set(name, value)
    yield
  ensure
    mod.send(:remove_const, name)
    mod.const_set(name, old)
  end
end
