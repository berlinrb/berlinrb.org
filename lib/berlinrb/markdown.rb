# frozen_string_literal: true

require "erb"

module Berlinrb
  # Renders the Markdown that talk summaries use: ## to #### headings,
  # paragraphs, "- " lists, **bold**, `code` and [links](https://...).
  # Anything else stays text. Every character from the file is escaped before
  # these become tags, so a summary cannot inject HTML or script links.
  module Markdown
    # A URL may hold one level of parentheses, as Wikipedia's often do.
    URL = %r{https?://(?:[^\s()]|\([^\s()]*\))+}
    LINK = %r{\[([^\]]+)\]\((#{URL})\)}

    module_function

    def html(text)
      blocks(text).map do |block|
        if (heading = block.match(/\A(\#{2,4}) (.+)\z/))
          level = heading[1].size
          "<h#{level}>#{inline(heading[2])}</h#{level}>"
        elsif block.start_with?("- ")
          items = block.split(/^- /).reject(&:empty?).map { "<li>#{inline(_1.split.join(" "))}</li>" }
          "<ul>\n#{items.join("\n")}\n</ul>"
        else
          "<p>#{inline(block.split.join(" "))}</p>"
        end
      end.join("\n")
    end

    # The document split at its ## headings, as [title, Markdown] pairs.
    def sections(text)
      text.to_s.split(/^(?=## )/).filter_map do |chunk|
        title = chunk[/\A## (.+)$/, 1] or next
        [title.strip, chunk.sub(/\A## .+\n?/, "")]
      end
    end

    # A paragraph's words without the markup, for descriptions.
    def plain(text)
      text.to_s.gsub(LINK, '\1').delete("*`").split.join(" ")
    end

    # Blank lines separate blocks, and a heading is always a block of its own.
    def blocks(text)
      text.to_s.gsub(/^(\#{2,4} .+)$/) { "\n#{$1}\n" }.split(/\n\s*\n/).map(&:strip).reject(&:empty?)
    end

    # Code is set aside while bold and links are found, so it can sit inside
    # either without its contents being read as markup.
    def inline(text)
      code = []
      ERB::Util.h(text.delete("\0"))
        .gsub(/`([^`]+)`/) { code << $1; "\0#{code.size - 1}\0" }
        .gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
        .gsub(LINK, '<a href="\2">\1</a>')
        .gsub(/\0(\d+)\0/) { "<code>#{code[$1.to_i]}</code>" }
    end
  end
end
