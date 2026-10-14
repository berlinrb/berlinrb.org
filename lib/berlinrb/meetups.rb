# frozen_string_literal: true

require "date"
require "yaml"

module Berlinrb
  # The meetups and talks in data/meetups.yml, which bin/sync updates and
  # bin/build renders. Hand edits survive a sync: it only fills in or
  # replaces the fields its sources own.
  class Meetups
    PATH = File.expand_path("../../data/meetups.yml", __dir__)

    attr_reader :list

    def self.load(path = PATH)
      new(File.exist?(path) ? YAML.safe_load_file(path, permitted_classes: [Date]) || [] : [], path)
    end

    def initialize(list, path = PATH)
      @list = list
      @path = path
      @list.each { _1["talks"] ||= [] }
    end

    def find(number)
      @list.find { _1["number"] == number }
    end

    def find_or_create(number)
      find(number) || (@list << { "number" => number, "talks" => [] }).last
    end

    def on(date)
      @list.find { _1["date"].to_s == date.to_s }
    end

    def save
      @list.sort_by! { _1["number"] }
      @list.each { |meetup| meetup.delete_if { |_, value| value.nil? || value == "" } }
      File.write(@path, "# Updated by bin/sync, rendered by bin/build. Hand edits are kept.\n" + YAML.dump(@list).delete_prefix("---\n"))
    end

    def self.slug(*parts)
      parts.join(" ")
        .tr("łŁøØđĐ", "lLoOdD")
        .gsub("ß", "ss")
        .unicode_normalize(:nfkd)
        .gsub(/\p{Mn}/, "")
        .downcase
        .gsub(/[^a-z0-9]+/, "-")
        .gsub(/\A-|-\z/, "")
    end

    # Names as they appear in video titles and cards, compared without accents,
    # case or punctuation ("Rafał" matches "Rafal").
    def self.same_person?(a, b)
      slug(a) == slug(b)
    end
  end
end
