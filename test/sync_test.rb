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
      when /period=past/ then JSON.dump(entries: [luma("Berlin.rb #2 (in person)", "2026-10-13T16:30:00Z", "offline", 64), luma("Berlin.rb #2 (livestream)", "2026-10-13T16:30:00Z", "online", 12)])
      when /period=future/ then JSON.dump(entries: [luma("Berlin.rb #3 (in person)", "2026-11-10T17:30:00Z", "offline", 20, city_only: true), luma("Berlin.rb #3 (livestream)", "2026-11-10T17:30:00Z", "online", 5)])
      when /lu\.ma\/url/ then JSON.dump(data: { description_mirror: { type: "doc", content: [
        { type: "paragraph", content: [{ type: "text", text: "With " }, { type: "text", text: "Andrzej Krzywda", marks: [{ type: "bold" }] },
                                       { type: "text", text: " <script>", marks: [{ type: "link", attrs: { href: "javascript:alert(1)" } }] }] }
      ] } })
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
    assert_equal 1, @meetups.find(1)["talks"].size, "a video without a Basecamp talk is not added"
    assert File.exist?(File.join(@dir, "talk1.jpg"))
  end

  def test_luma_fills_meetups_and_announces_named_speakers
    sync.run(%i[luma])

    two = @meetups.find(2)
    assert_equal ["2026-10-13", "18:30", "Venue", "Street 1, Berlin", 64, 12], two.values_at("date", "starts_at", "venue", "address", "signups_in_person", "signups_online")
    three = @meetups.find(3)
    assert_nil three["signups_in_person"], "upcoming signups change daily and stay off the site"
    assert_nil three["venue"], "a city alone is not a venue"
    assert_equal "3online", three["livestream_luma"]
    assert_equal "<p>With <strong>Andrzej Krzywda</strong> &lt;script&gt;</p>", three["about"]
  end

  def test_basecamp_scheduled_and_done_cards_become_talks
    cards = [
      { "title" => "Andrzej Krzywda: Rails at scale", "due_on" => "2026-11-10", "parent" => { "title" => "Scheduled" },
        "content" => "<p><strong>Format:</strong> Talk (40 min)\n<strong>Title:</strong> Rails at scale\n<strong>Abstract:</strong> One\n\nTwo\n<strong>Contact:</strong> secret@example.com</p>" },
      { "title" => "Someone: Idea", "due_on" => nil, "parent" => { "title" => "Ideas" }, "content" => "" }
    ]
    sync(cards: cards).run(%i[basecamp])

    talks = @meetups.find(3)["talks"]
    assert_equal ["Andrzej Krzywda"], talks.map { _1["speaker"] }, "Marco has no card, so he is off #3"
    assert_equal ["Rails at scale", "One\n\nTwo", "Talk (40 min)"], talks.first.values_at("title", "abstract", "format")
    refute_includes talks.first.to_s, "secret@example.com"
    assert_empty @meetups.find(1)["talks"], "no Done card for #1 either"
  end

  def test_basecamp_keeps_recordings_and_drops_removed_fields
    @meetups.find(1)["talks"].first.merge!("video" => "talk1", "abstract" => "Old")
    card = { "title" => "Paweł Strzałkowski: HiFuMi", "due_on" => "2026-09-08", "parent" => { "title" => "Done" },
             "content" => "<p><strong>Title:</strong> HiFuMi</p>" }
    sync(cards: [card]).run(%i[basecamp])

    assert_equal [{ "speaker" => "Paweł Strzałkowski", "title" => "HiFuMi", "video" => "talk1" }], @meetups.find(1)["talks"]
  end

  def test_basecamp_api_reads_scheduled_and_done_columns_with_a_token
    sync = Berlinrb::Sync.new(@meetups)
    responses = {
      "https://3.basecampapi.com/6219432/buckets/47498411/card_tables/10403432462.json" =>
        { "lists" => [{ "title" => "Ideas", "cards_url" => "ideas" }, { "title" => "Done", "cards_url" => "done" }] },
      "done" => [{ "title" => "Pawel Strzalkowski: HiFuMi", "due_on" => "2026-09-08", "content" => "" }]
    }
    sync.define_singleton_method(:basecamp_request) do |_method, url, _body = nil|
      Struct.new(:body, :link) { def [](_) = link }.new(JSON.dump(responses.fetch(url)), nil)
    end

    cards = with_env("BASECAMP_TOKEN" => "token") { sync.basecamp_cards }

    assert_equal [["Pawel Strzalkowski: HiFuMi", "Done"]], cards.map { [_1["title"], _1.dig("parent", "title")] }
  end

  def test_luma_todos_ask_for_changed_descriptions_and_complete_matching_ones
    @meetups.find(3).merge!("luma" => "05tfdlpk", "about" => "<p>Talks to be announced</p>")
    four = @meetups.find_or_create(4).merge!("date" => "2026-12-08", "luma" => "wbdh6v2d")
    four["about"] = Berlinrb::LumaDescription.html(four)
    sync = sync()
    sync.instance_variable_set(:@basecamp_token, "token")
    calls = []
    sync.define_singleton_method(:basecamp_pages) do |url|
      url.end_with?("todolists.json") ? [{ "id" => 7, "name" => "Luma descriptions" }] :
        [{ "id" => 9, "content" => "Update the Luma description for Berlin.rb #4" }]
    end
    sync.define_singleton_method(:basecamp_api) { |path, method: :get, body: nil| calls << [method, path, body&.fetch(:content)] }

    sync.run(%i[luma_todos])

    assert_equal [[:post, "buckets/47498411/todolists/7/todos.json", "Update the Luma description for Berlin.rb #3"],
                  [:post, "buckets/47498411/todos/9/completion.json", nil]], calls
  end

def test_luma_todos_space_their_paragraphs_and_respace_an_unspaced_one
  @meetups.find(3).merge!("luma" => "05tfdlpk", "about" => "<p>Talks to be announced</p>")
  wanted = Berlinrb::LumaDescription.html(@meetups.find(3))
  unspaced = %(<p>Luma's description no longer matches the talks in Basecamp. Copy everything below the line into the description of <a href="https://luma.com/05tfdlpk">Berlin.rb #3 on Luma</a>, replacing what is there. This to-do completes itself once Luma matches.</p><hr>#{wanted.delete("\n")})
  sync = sync()
  sync.instance_variable_set(:@basecamp_token, "token")
  calls = []
  sync.define_singleton_method(:basecamp_pages) do |url|
    url.end_with?("todolists.json") ? [{ "id" => 7, "name" => "Luma descriptions" }] :
      [{ "id" => 9, "content" => "Update the Luma description for Berlin.rb #3", "description" => unspaced, "assignees" => [{ "id" => 52488656 }] }]
  end
  sync.define_singleton_method(:basecamp_api) { |path, method: :get, body: nil| calls << [method, path, body&.fetch(:description)] }

  sync.run(%i[luma_todos])

  assert_equal [[:put, "buckets/47498411/todos/9.json"]], calls.map { _1.first(2) }
  description = calls.first.last
  assert_includes description, "<hr><p>Berlin.rb is a regular meetup"
  assert_includes description, "</p><p><br></p><p><strong>Talks</strong></p><p><br></p><ul>"
  assert_equal wanted.count("\n"), description.scan("<p><br></p>").size
end

  def test_basecamp_is_skipped_when_the_cli_is_not_signed_in
    sync = sync(cards: nil)
    sync.instance_variable_set(:@basecamp, -> {})
    sync.run(%i[basecamp])

    assert_match(/skipped/, sync.log.first)
  end

  private

  def with_env(values)
    old = values.keys.to_h { [_1, ENV[_1]] }
    values.each { ENV[_1] = _2 }
    yield
  ensure
    old.each { ENV[_1] = _2 }
  end

  def stub_const(mod, name, value)
    old = mod.send(:remove_const, name)
    mod.const_set(name, value)
    yield
  ensure
    mod.send(:remove_const, name)
    mod.const_set(name, old)
  end
end
