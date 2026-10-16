# frozen_string_literal: true

require_relative "photos"

module Berlinrb
  module ImageCheck
    IMAGE = /\.(jpe?g|png|webp|gif|heic|tiff?|avif)\z/i

    def self.errors(paths)
      paths.filter_map do |path|
        next unless File.file?(path) && path.match?(IMAGE)
        thumb = path.include?("/thumbs/")
        limit = thumb ? 150 * 1024 : 1024 * 1024
        next "#{path}: exceeds #{limit / 1024} KiB" if File.size(path) > limit
        next unless path.match?(%r{\Aphotos/\d+/})
        next "#{path}: run bin/photos to prepare JPEGs" unless path.end_with?(".jpg")
        begin
          dimensions = Photos.dimensions(path)
        rescue StandardError
          dimensions = nil
        end
        next "#{path}: invalid JPEG" unless dimensions
        max = thumb ? Photos::THUMB : Photos::FULL
        next "#{path}: exceeds #{max}px, run bin/photos" if dimensions.max > max
        unless thumb || File.file?(File.join(File.dirname(path), "thumbs", File.basename(path)))
          next "#{path}: missing thumbnail, run bin/photos"
        end
        nil
      end
    end
  end
end
