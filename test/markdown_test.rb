# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/berlinrb/markdown"

class MarkdownTest < Minitest::Test
  def test_renders_headings_paragraphs_and_lists
    html = Berlinrb::Markdown.html(<<~MD)
      ### The codebase is the prompt
      Code is cheap now,
      and that matters.

      - one
      - two,
        continued
    MD
    assert_equal <<~HTML.chomp, html
      <h3>The codebase is the prompt</h3>
      <p>Code is cheap now, and that matters.</p>
      <ul>
      <li>one</li>
      <li>two, continued</li>
      </ul>
    HTML
  end

  def test_renders_bold_code_and_links
    html = Berlinrb::Markdown.html("**Types.** Use `map` and [Literal](https://literal.fun), not `<b>`.")
    assert_equal '<p><strong>Types.</strong> Use <code>map</code> and <a href="https://literal.fun">Literal</a>, not <code>&lt;b&gt;</code>.</p>', html
  end

  def test_escapes_html_and_drops_links_that_are_not_web_links
    html = Berlinrb::Markdown.html(%(<script>alert(1)</script>\n\n[click](javascript:alert(1)) and [quote](https://x.org/"onmouseover=")))
    refute_includes html, "<script>"
    refute_includes html, 'href="javascript'
    assert_includes html, "&lt;script&gt;"
    assert_includes html, %(<a href="https://x.org/&quot;onmouseover=&quot;">quote</a>)
  end

  def test_links_may_contain_parentheses
    html = Berlinrb::Markdown.html("[Monad](https://en.wikipedia.org/wiki/Monad_(functional_programming)), a pattern.")
    assert_equal '<p><a href="https://en.wikipedia.org/wiki/Monad_(functional_programming)">Monad</a>, a pattern.</p>', html
    assert_equal "Monad, a pattern.", Berlinrb::Markdown.plain("[Monad](https://en.wikipedia.org/wiki/Monad_(functional_programming)), a pattern.")
  end

  def test_code_works_inside_links_and_bold
    assert_equal '<p><a href="https://literal.fun"><code>literal</code></a>: types</p>', Berlinrb::Markdown.html("[`literal`](https://literal.fun): types")
    assert_equal "<p><strong>Use <code>map</code>.</strong></p>", Berlinrb::Markdown.html("**Use `map`.**")
  end

  def test_keeps_timestamp_links_intact
    html = Berlinrb::Markdown.html("### Inhale, exhale [10:41](https://www.youtube.com/watch?v=abc&t=641s)")
    assert_equal '<h3>Inhale, exhale <a href="https://www.youtube.com/watch?v=abc&amp;t=641s">10:41</a></h3>', html
  end

  def test_splits_sections_at_level_two_headings
    sections = Berlinrb::Markdown.sections("## Chapters\n\n- a\n\n## Summary\n\nText\n\n### Part\n")
    assert_equal [["Chapters", "\n- a\n\n"], ["Summary", "\nText\n\n### Part\n"]], sections
  end

  def test_plain_strips_the_markup
    assert_equal "Stephen reads 5% at ZAR, a neobank.", Berlinrb::Markdown.plain("Stephen reads **5%** at [ZAR](https://zar.app),\na `neobank`.")
  end
end
