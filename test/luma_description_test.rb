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

  def test_compares_words_not_markup
    assert Berlinrb::LumaDescription.same?("<p>Talks: <strong>Rosa</strong></p>", "<ul><li>Talks Rosa</li></ul>")
    refute Berlinrb::LumaDescription.same?("<p>Rosa</p>", "<p>Marco</p>")
  end
end
