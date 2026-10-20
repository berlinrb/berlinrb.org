# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/berlinrb/luma_description"

class LumaDescriptionTest < Minitest::Test
  def html(talks, **extra) = Berlinrb::LumaDescription.html({ "talks" => talks }.merge(extra.transform_keys(&:to_s)))

  def test_without_talks_asks_for_proposals
    assert_includes html([]), "Talks to be announced. Want to give one?"
  end

  def test_lists_talks_and_asks_for_a_second_one
    text = html([{ "speaker" => "Marco Roth" }])
    assert_includes text, "<li><strong>Marco Roth</strong>: talk to be announced</li>"
    assert_includes text, "Want to give the second one?"

    full = html([{ "speaker" => "Rosa <G>", "title" => "Kamal" }, { "speaker" => "Alex Adam", "title" => "Herb" }])
    assert_includes full, "<strong>Rosa &lt;G&gt;</strong>: Kamal."
    refute_includes full, "second one"
  end

  def test_links_the_livestream_event_and_adds_directions
    text = html([], livestream_luma: "abc", getting_there: "Fourth floor.")
    assert_includes text, %(<a href="https://luma.com/abc">Register for the livestream event</a>)
    assert_includes text, "<strong>Getting there:</strong> Fourth floor."
  end

  def test_markdown_keeps_paragraphs_lists_bold_and_links
    text = Berlinrb::LumaDescription.markdown(html([{ "speaker" => "Rosa", "title" => "Kamal & co" }, { "speaker" => "Alex Adam" }], livestream_luma: "abc"))
    assert text.start_with?("Berlin.rb is a regular meetup for Berlin's Ruby community.")
    assert_includes text, "**Talks**\n\n- **Rosa**: Kamal & co.\n- **Alex Adam**: talk to be announced\n\nWhether"
    assert_includes text, "[Register for the livestream event](https://luma.com/abc)"
    refute_match(/<|&#39;|&amp;/, text)
  end

  def test_markdown_escapes_markdown_characters_in_text_but_not_in_links
    text = Berlinrb::LumaDescription.markdown(%(<p><strong>Talks</strong> on snake_case, *splat* and [arrays] <a href="https://example.com/a_b?x=1&amp;y=2">read_me</a></p>))
    assert_equal '**Talks** on snake\_case, \*splat\* and \[arrays\] [read\_me](https://example.com/a_b?x=1&y=2)', text
  end

  def test_livestream_description_lists_the_same_talks_for_people_at_home
    text = Berlinrb::LumaDescription.livestream_html({ "talks" => [{ "speaker" => "Marco Roth", "title" => "Herb" }] })
    assert_includes text, "<li><strong>Marco Roth</strong>: Herb.</li>"
    assert_includes text, %(the in-person event is on <a href="https://luma.com/berlinrb">our calendar</a>.)
    assert_includes text, "<strong>Recording:</strong> the talks are published on our"
    refute_includes text, "Filming:"
  end

  def test_compares_words_not_markup
    assert Berlinrb::LumaDescription.same?("<p>Talks: <strong>Rosa</strong></p>", "<ul><li>Talks Rosa</li></ul>")
    refute Berlinrb::LumaDescription.same?("<p>Rosa</p>", "<p>Marco</p>")
    refute Berlinrb::LumaDescription.same?(%(<p><a href="https://tally.so/r/x">Submit it here</a></p>), %(<p><a href="https://berlinrb.org/get-involved/#speak">Submit it here</a></p>))
    assert Berlinrb::LumaDescription.same?(%(<p><a href="https://a.example/">Here</a></p>), %(<p><a target="_blank" href="https://a.example/" rel="noreferrer">Here</a></p>))
  end
end
