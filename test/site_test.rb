# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/berlinrb/site"

class SiteTest < Minitest::Test
  def setup
    @out = Dir.mktmpdir
    @root = Dir.mktmpdir
    FileUtils.cp_r(Dir[File.join(Berlinrb::Site::ROOT, "{index.html,templates}")], @root)
    FileUtils.mkdir_p(File.join(@root, "photos/1/thumbs"))
    %w[photos/1/a.jpg photos/1/thumbs/a.jpg].each { FileUtils.cp(File.expand_path("fixtures/photo.jpg", __dir__), File.join(@root, _1)) }
    meetups = Berlinrb::Meetups.new([
      { "number" => 1, "date" => "2026-09-08", "starts_at" => "18:30", "venue" => "ablefy", "signups_in_person" => 100, "signups_online" => 11, "about" => "<p>From Luma</p>",
        "talks" => [{ "speaker" => "Carmine Paolino", "title" => "RubyLLM 2.0: Beyond Agents", "abstract" => "Ruby is where you ship AI.", "video" => "abc" }] },
      { "number" => 2, "date" => "2026-10-13", "about" => "<p><strong>Rafał Cymerys</strong>, then Stephen Margheim</p>",
        "talks" => [{ "speaker" => "Stephen Margheim", "title" => "The ZARchitecture: How" }, { "speaker" => "Rafal Cymerys", "title" => "Let Your Software" }] },
      { "number" => 3, "date" => "2026-11-10", "luma" => "05tfdlpk",
        "talks" => [{ "speaker" => "Marco Roth", "title" => "Herb" }, { "speaker" => "Alex Adam" }] }
    ])
    @site = Berlinrb::Site.new(meetups, today: Date.new(2026, 10, 14), root: @root, out: @out)
    @site.build
  end

  def teardown = FileUtils.rm_rf([@out, @root])

  def read(path) = File.read(File.join(@out, path))

  def test_builds_a_page_per_meetup_and_talk
    meetup = read("meetups/1/index.html")
    assert_includes meetup, "<h1>Berlin.rb #1</h1>"
    assert_includes meetup, %("@type": "Event")
    assert_includes meetup, "<title>Berlin.rb #1: RubyLLM 2.0</title>"
    assert_includes meetup, "<p>From Luma</p>"
    assert_includes meetup, "(100 in person, 11 online)"
    assert_includes meetup, "/talks/carmine-paolino-rubyllm-2-0-beyond-agents/"

    talk = read("talks/carmine-paolino-rubyllm-2-0-beyond-agents/index.html")
    assert_includes talk, "RubyLLM 2.0: Beyond Agents"
    assert_includes talk, "https://www.youtube.com/watch?v=abc"
    assert_includes talk, %("@type": "VideoObject")
  end

  def test_upcoming_talks_show_with_or_without_a_title
    upcoming = read("meetups/3/index.html")
    assert_includes upcoming, "Herb"
    assert_includes upcoming, "<h3>Alex Adam</h3>"
    assert_includes upcoming, "Talk to be announced"
    assert_includes upcoming, "https://luma.com/05tfdlpk"
    assert File.exist?(File.join(@out, "talks/marco-roth-herb/index.html"))
    refute Dir.exist?(File.join(@out, "talks/alex-adam"))
  end

  def test_home_lists_upcoming_and_past_meetups
    home = read("index.html")
    upcoming = home[/next-meetup:start.*next-meetup:end/m]
    past = home[/past-meetups:start.*past-meetups:end/m]
    assert_includes upcoming, "/meetups/3/"
    assert_includes upcoming, "<strong>Marco Roth</strong>: Herb"
    assert_includes upcoming, "<strong>Alex Adam</strong>, talk to be announced"
    assert_includes past, "/meetups/1/"
    assert_includes past, "111 signups"
    assert_includes past, "RubyLLM 2.0 (Carmine Paolino)"
    refute_includes past, "/meetups/3/"
  end

def test_meetup_cards_put_each_talk_on_its_own_line
  two = %(<span class="talk-line">Let Your Software (Rafal Cymerys)</span><span class="talk-line">The ZARchitecture (Stephen Margheim)</span>)
  assert_includes read("meetups/index.html"), two
  assert_includes read("index.html")[/past-meetups:start.*past-meetups:end/m], two
  refute_includes read("meetups/index.html"), "(Rafal Cymerys) · "
end

  def test_meetup_photos_appear_on_the_meetup_and_photos_pages
    assert_includes read("meetups/1/index.html"), %(<a href="/photos/1/a.jpg"><img src="/photos/1/thumbs/a.jpg")
    assert_includes read("photos/index.html"), "/photos/1/thumbs/a.jpg"
    assert File.exist?(File.join(@out, "photos/1/a.jpg"))
    refute_includes read("meetups/3/index.html"), %(class="gallery")
  end

  def test_talks_follow_the_order_of_the_luma_description
    assert_equal ["Rafal Cymerys", "Stephen Margheim"], @site.talks_for(@site.meetups.find { _1["number"] == 2 }).map { _1["speaker"] }
  end

  def test_get_involved_offers_dates_with_their_free_stage_time
    page = read("get-involved/index.html")
    assert_includes page, %(name="dates[]" value="2026-11-10" disabled)
    assert_includes page, "Full"
    assert_includes page, %(action="https://api.berlinrb.org/talks")
    assert_includes read("meetups/index.html"), "/meetups/1/"
    assert_includes read("index.html"), %(<header class="site-header">)
  end

  def test_upcoming_meetups_carry_live_hooks
    upcoming = read("meetups/3/index.html")
    assert_includes upcoming, %(data-live-stats="2026-11-10")
    assert_includes upcoming, %(data-live-start="2026-11-10T18:30:00+01:00")
    assert_includes upcoming, %(<meta name="berlinrb-api" content="https://api.berlinrb.org">)
    refute_includes upcoming, "Speak at this meetup", "#3 is full"
    refute_includes read("meetups/1/index.html"), "data-live-stats"
  end

  def test_talks_page_features_the_latest_recording_and_thanks_hosts
    talks = read("talks/index.html")
    assert_includes talks, %(class="featured-talk")
    assert_includes talks, %(data-kind="talk")
    meetup = read("meetups/1/index.html")
    assert_includes meetup, "<dt>Recorded talks</dt>"
  end

  def test_sitemap_lists_generated_pages
    sitemap = read("sitemap.xml")
    assert_includes sitemap, "https://berlinrb.org/meetups/1/"
    assert_includes sitemap, "https://berlinrb.org/talks/carmine-paolino-rubyllm-2-0-beyond-agents/"
  end
end
