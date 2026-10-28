# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/berlinrb/site"

class SiteTest < Minitest::Test
  SLIDES = "/slides/2/rafal-cymerys.pdf"

  def setup
    @out = Dir.mktmpdir
    @root = Dir.mktmpdir
    FileUtils.cp_r(Dir[File.join(Berlinrb::Site::ROOT, "{index.html,templates,slides,press}")], @root)
    FileUtils.mkdir_p(File.join(@root, "photos/1/thumbs"))
    %w[photos/1/a.jpg photos/1/thumbs/a.jpg].each { FileUtils.cp(File.expand_path("fixtures/photo.jpg", __dir__), File.join(@root, _1)) }
    FileUtils.mkdir_p(File.join(@root, "data/talks"))
    File.write(File.join(@root, "data/talks/abc.md"), <<~MD)
      ## Chapters

      - [0:00](https://www.youtube.com/watch?v=abc&t=0s) Intro
      - [1:30](https://www.youtube.com/watch?v=abc&t=90s) Agents
      - [3:00](https://www.youtube.com/watch?v=abc&t=180s) Questions

      ## Summary

      Carmine shows how to ship **AI** in [Ruby](https://www.ruby-lang.org).

      ### Agents [1:30](https://www.youtube.com/watch?v=abc&t=90s)

      <script>alert(1)</script>

      ## Mentioned in the talk

      - [RubyLLM](https://rubyllm.com): the gem.
    MD
    File.write(File.join(@root, "data/talks/ghi.md"), "## Summary\n\n### Straight into a part\n\n- No opening paragraph\n")
    meetups = Berlinrb::Meetups.new([
      { "number" => 1, "date" => "2026-09-08", "starts_at" => "18:30", "venue" => "ablefy", "signups_in_person" => 100, "signups_online" => 11, "about" => "<p>From Luma</p>",
        "talks" => [{ "speaker" => "Carmine Paolino", "title" => "RubyLLM 2.0: Beyond Agents", "video" => "abc" }] },
      { "number" => 2, "date" => "2026-10-13", "about" => "<p><strong>Rafał Cymerys</strong>, then Stephen Margheim</p>",
        "talks" => [{ "speaker" => "Stephen Margheim", "title" => "The ZARchitecture: How", "abstract" => "Code is cheap now.", "video" => "ghi" },
                    { "speaker" => "Rafal Cymerys", "title" => "Let Your Software", "video" => "def", "slides" => SLIDES }] },
      { "number" => 3, "date" => "2026-11-10", "luma" => "05tfdlpk",
        "talks" => [{ "speaker" => "Marco Roth", "title" => "Herb", "slides" => "/slides/3/marco-roth.pdf" }, { "speaker" => "Alex Adam" }] }
    ])
    @site = Berlinrb::Site.new(meetups, today: Date.new(2026, 10, 14), root: @root, out: @out)
    @site.build
  end

  def teardown = FileUtils.rm_rf([@out, @root])

  def read(path) = File.read(File.join(@out, path))

  def test_header_uses_horizontal_logos_for_both_color_schemes
    home = read("index.html")
    assert_includes home, 'srcset="/assets/logotype-dark.svg" media="(prefers-color-scheme: dark)"'
    assert_includes home, 'src="/assets/logotype.svg" alt="Berlin.rb" width="618" height="195"'
    assert_includes home, 'aria-label="Berlin.rb home"'
    assert_includes home, 'rel="icon" href="assets/logo.svg"'
  end

  def test_footers_link_to_the_discord_channel
    link = '<a href="https://discord.gg/AxPaDEcfST">Discord</a>'
    %w[index.html talks/index.html meetups/1/index.html press/index.html].each { assert_includes read(_1), link, _1 }
    organization = JSON.parse(read("index.html")[%r{<script type="application/ld\+json">(.*?)</script>}m, 1])["@graph"].first
    assert_includes organization["sameAs"], "https://discord.gg/AxPaDEcfST"
  end

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

  def test_talk_pages_show_the_summary_and_play_the_recording_here
    talk = read("talks/carmine-paolino-rubyllm-2-0-beyond-agents/index.html")
    assert_includes talk, %(<div class="player" data-player="abc" data-title="RubyLLM 2.0: Beyond Agents">)
    assert_includes talk, %(<a class="video-link player-start" href="https://www.youtube.com/watch?v=abc">)
    assert_includes talk, %(<ul style="--rows: 2">)
    assert_includes talk, %(<li><a href="https://www.youtube.com/watch?v=abc&amp;t=0s">0:00</a> Intro</li>)
    assert_includes talk, %(<h3>Agents <a class="timestamp" href="https://www.youtube.com/watch?v=abc&amp;t=90s">1:30</a></h3>)
    assert_includes talk, %(<section class="page-section prose talk-notes" id="mentioned-in-the-talk")
    assert_includes talk, %(Written with AI</button><span id="ai-note" popover style="position-anchor: --ai-note">This summary was written with AI from the recording, then checked by Berlin.rb and Carmine Paolino.)
    assert_includes talk, "&lt;script&gt;alert(1)&lt;/script&gt;"
    refute_includes talk, "<script>alert"
  end

  def test_the_summary_opens_with_the_talk_in_short_for_search_engines
    talk = read("talks/carmine-paolino-rubyllm-2-0-beyond-agents/index.html")
    assert_includes talk, %(<meta name="description" content="Carmine shows how to ship AI in Ruby.">)
    assert_includes talk, %("description": "Carmine shows how to ship AI in Ruby.")
  end

  def test_talk_cards_without_an_abstract_describe_the_talk_from_its_summary
    card = %(<p class="talk-card-abstract">Carmine shows how to ship AI in Ruby.</p>)
    assert_includes read("talks/index.html"), card
    assert_includes read("meetups/1/index.html"), card
    assert_equal "In his own words.", @site.blurb({ "abstract" => "In his own words.", "video" => "abc" })
  end

  def test_a_summary_without_an_opening_paragraph_falls_back_to_the_abstract
    talk = read("talks/stephen-margheim-the-zarchitecture-how/index.html")
    assert_includes talk, %(<meta name="description" content="Code is cheap now.">)
    assert_includes talk, %("description": "Code is cheap now.")
  end

  def test_summary_styles_leave_other_prose_alone
    css = File.read(File.join(Berlinrb::Site::ROOT, "styles.css"))
    refute_match(/^\.prose (h3|h4|ul|li|code)\b/, css, "meetup pages use .prose for Luma's description")
    assert_includes read("talks/carmine-paolino-rubyllm-2-0-beyond-agents/index.html"), %(<section class="page-section prose talk-notes" id="summary")
  end

  def test_tips_anchor_each_note_to_its_own_pill
    tip = @site.render_tip("ai-note", "Q & A", %(<a href="/">Note</a>))
    assert_match %r{\A<span class="tip"><button type="button" popovertarget="ai-note" style="anchor-name: --ai-note"><svg [^>]+ aria-hidden="true">.+</svg>Q &amp; A</button>}, tip
    assert tip.end_with?(%(<span id="ai-note" popover style="position-anchor: --ai-note"><a href="/">Note</a></span></span>))
    assert_raises(ArgumentError) { @site.render_tip("AI note", "Label", "Note") }
  end

  def test_recorded_talks_without_a_summary_only_gain_the_player
    talk = read("talks/rafal-cymerys-let-your-software/index.html")
    assert_includes talk, %(data-player="def")
    refute_includes talk, %(class="page-section chapters")
    refute_includes talk, "ai-note"
    assert_includes talk, %(<meta name="description" content="Let Your Software, a talk by Rafal Cymerys at Berlin.rb #2.">)
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

  def test_meetup_photos_appear_on_the_meetup_and_photos_pages
    assert_includes read("meetups/1/index.html"), %(<a href="/photos/1/a.jpg"><img src="/photos/1/thumbs/a.jpg")
    assert_includes read("photos/index.html"), "/photos/1/thumbs/a.jpg"
    assert File.exist?(File.join(@out, "photos/1/a.jpg"))
    refute_includes read("meetups/3/index.html"), %(class="gallery")
  end

  def test_talks_follow_the_order_of_the_luma_description
    assert_equal ["Rafal Cymerys", "Stephen Margheim"], @site.talks_for(@site.meetups.find { _1["number"] == 2 }).map { _1["speaker"] }
  end

  def test_talk_pages_open_with_the_meetup_and_date_on_one_line
    hero = read("talks/rafal-cymerys-let-your-software/index.html")[/<section class="page-hero">.*?<\/section>/m]
    assert_includes hero, %(<p class="eyebrow"><span><a href="/meetups/2/">Berlin.rb #2</a>, <time datetime="2026-10-13">)
    refute_includes hero, %(class="back")
  end

  def test_talk_slides_are_published_and_linked
    assert File.exist?(File.join(@out, SLIDES))
    page = read("talks/rafal-cymerys-let-your-software/index.html")
    assert_includes page, %(<p class="player-links"><a href="#{SLIDES}">Slides</a></p>)
    refute_includes page, "See the slides"
  end

  def test_talk_slides_without_a_recording_are_linked_from_the_note
    page = read("talks/marco-roth-herb/index.html")
    assert_includes page, %(<a href="/slides/3/marco-roth.pdf">See the slides</a>. Want to speak too?)
    refute_includes page, "player-links"
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

  def test_talks_and_meetups_have_markdown_versions_for_agents
    talk = read("talks/carmine-paolino-rubyllm-2-0-beyond-agents.md")
    assert talk.start_with?("# RubyLLM 2.0: Beyond Agents\n")
    assert_includes talk, "given at [Berlin.rb #1](https://berlinrb.org/meetups/1.md)"
    assert_includes talk, "- Recording: https://www.youtube.com/watch?v=abc"
    assert_includes talk, "Carmine shows how to ship **AI** in [Ruby](https://www.ruby-lang.org)."
    assert_includes talk, "written with AI from the recording"
    assert_includes read("talks/rafal-cymerys-let-your-software.md"), "- Slides: https://berlinrb.org#{SLIDES}"
    assert_includes read("meetups/2.md"), "- [Let Your Software](https://berlinrb.org/talks/rafal-cymerys-let-your-software.md) by Rafal Cymerys"
    page = read("talks/carmine-paolino-rubyllm-2-0-beyond-agents/index.html")
    assert_includes page, %(<link rel="alternate" type="text/markdown" href="https://berlinrb.org/talks/carmine-paolino-rubyllm-2-0-beyond-agents.md">)
    assert_includes page, %(data-copy-markdown="/talks/carmine-paolino-rubyllm-2-0-beyond-agents.md")
  end

  def test_llms_txt_maps_the_markdown_versions
    llms = read("llms.txt")
    assert llms.start_with?("# Berlin.rb\n\n> ")
    assert_includes llms, "- [RubyLLM 2.0: Beyond Agents](https://berlinrb.org/talks/carmine-paolino-rubyllm-2-0-beyond-agents.md): by Carmine Paolino, Berlin.rb #1, 8 Sep 2026, recorded"
    assert_includes llms, "- [Berlin.rb #1](https://berlinrb.org/meetups/1.md): 8 Sep 2026, ablefy"
    assert_operator llms.index("Let Your Software"), :<, llms.index("RubyLLM 2.0")
    full = read("llms-full.txt")
    assert_includes full, "Carmine shows how to ship **AI**"
    assert_includes full, "# Berlin.rb #3"
  end

  def test_publishes_the_indexnow_key
    Berlinrb::Site.new(Berlinrb::Meetups.new([]), out: @out).build
    key = "0b4dad3050cd21cfba8b10d8d447abac"
    assert_equal key, File.read(File.join(@out, "#{key}.txt")).strip
  end

  def test_robots_txt_welcomes_ai_agents
    robots = File.read(File.join(Berlinrb::Site::ROOT, "robots.txt"))
    assert_includes robots, "Content-Signal: search=yes, ai-input=yes, ai-train=yes"
    assert_includes robots, "https://berlinrb.org/llms.txt"
  end

  def test_sitemap_lists_generated_pages
    sitemap = read("sitemap.xml")
    assert_includes sitemap, "https://berlinrb.org/meetups/1/"
    assert_includes sitemap, "https://berlinrb.org/talks/carmine-paolino-rubyllm-2-0-beyond-agents/"
  end
end
