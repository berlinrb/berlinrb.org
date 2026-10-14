# frozen_string_literal: true

require "fileutils"
require "open3"

module Berlinrb
  # Meetup photos live in photos/<meetup number>/. bin/photos turns whatever
  # was dropped there into web-sized JPEGs without metadata, plus thumbnails.
  class Photos
    ROOT       = File.expand_path("../../photos", __dir__)
    SOURCES    = /\.(jpe?g|png|webp|heic|tiff?)\z/i
    FULL       = 1600
    THUMB      = 640

    def initialize(root = ROOT)
      @root = root
    end

    def for(number)
      Dir[File.join(@root, number.to_s, "*.jpg")].sort.map do |path|
        name = File.basename(path)
        thumb = File.join(@root, number.to_s, "thumbs", name)
        width, height = self.class.dimensions(File.exist?(thumb) ? thumb : path)
        { "src" => "/photos/#{number}/#{name}", "thumb" => "/photos/#{number}/thumbs/#{name}", "width" => width, "height" => height }
      end
    end

    # Resizes, strips location and camera metadata, and writes thumbnails.
    # Returns the paths it wrote.
    def process
      Dir[File.join(@root, "*", "*")].sort.filter_map do |source|
        next unless File.file?(source) && source.match?(SOURCES)
        dir = File.dirname(source)
        target = File.join(dir, "#{self.class.name_for(source)}.jpg")
        thumb = File.join(dir, "thumbs", File.basename(target))
        written = []
        if source != target || needs_work?(source)
          convert(source, target, FULL, 82)
          File.delete(source) unless source == target
          written << target
        end
        unless File.exist?(thumb) && File.mtime(thumb) >= File.mtime(target)
          FileUtils.mkdir_p(File.dirname(thumb))
          convert(target, thumb, THUMB, 76)
          written << thumb
        end
        written
      end.flatten
    end

    def self.name_for(path)
      File.basename(path, ".*").downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    end

    # Width and height from a JPEG's start-of-frame marker.
    def self.dimensions(path)
      File.open(path, "rb") do |file|
        return nil unless file.read(2) == "\xFF\xD8".b
        loop do
          marker = file.read(2) or return nil
          length = file.read(2).unpack1("n")
          if marker.getbyte(1).between?(0xC0, 0xCF) && ![0xC4, 0xC8, 0xCC].include?(marker.getbyte(1))
            height, width = file.read(5).unpack("xnn")
            return [width, height]
          end
          file.seek(length - 2, IO::SEEK_CUR)
        end
      end
    end

    private

    def needs_work?(path)
      width, height = self.class.dimensions(path)
      return true unless width && height
      return true if [width, height].max > FULL
      out, = Open3.capture2(*identify, "-format", "%[exif:*]", path, err: File::NULL)
      !out.strip.empty?
    end

    def convert(source, target, size, quality)
      ok = system(*magick, source, "-auto-orient", "-strip", "-resize", "#{size}x#{size}>",
                  "-quality", quality.to_s, "-interlace", "Plane", "-sampling-factor", "4:2:0", "jpg:#{target}")
      raise "Could not convert #{source}" unless ok
    end

    def magick = system("command -v magick >/dev/null") ? %w[magick] : %w[convert]
    def identify = system("command -v magick >/dev/null") ? %w[magick identify] : %w[identify]
  end
end
