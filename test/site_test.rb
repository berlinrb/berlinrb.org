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
        "talks" => [{ "speaker" => "Andrzej Krzywda", "title" => "Secret", "announced" => false },
                    { "speaker" => "Marco Roth", "title" => "Herb", "announced" => true }] }
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

  def test_upcoming_talks_stay_hidden_until_announced
    upcoming = read("meetups/3/index.html")
    assert_includes upcoming, "Herb"
    refute_includes upcoming, "Secret"
    assert_includes upcoming, "https://luma.com/05tfdlpk"
    refute File.exist?(File.join(@out, "talks/andrzej-krzywda-secret/index.html"))
  end

  def test_home_lists_upcoming_and_past_meetups
    home = read("index.html")
    upcoming = home[/upcoming-meetups:start.*upcoming-meetups:end/m]
    past = home[/past-meetups:start.*past-meetups:end/m]
    assert_includes upcoming, "/meetups/3/"
    assert_includes upcoming, "Marco Roth"
    assert_includes past, "/meetups/1/"
    assert_includes past, "111 signups"
    assert_includes past, "RubyLLM 2.0 (Carmine Paolino)"
    refute_includes past, "/meetups/3/"
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

  def test_sitemap_lists_generated_pages
    sitemap = read("sitemap.xml")
    assert_includes sitemap, "https://berlinrb.org/meetups/1/"
    assert_includes sitemap, "https://berlinrb.org/talks/carmine-paolino-rubyllm-2-0-beyond-agents/"
  end
end
