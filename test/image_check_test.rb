# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/berlinrb/image_check"

class ImageCheckTest < Minitest::Test
  def test_rejects_large_raster_images_but_ignores_non_images
    Dir.mktmpdir do |dir|
      image = File.join(dir, "large.JPG")
      File.binwrite(image, "x" * (1024 * 1024 + 1))
      assert_match(/exceeds 1024 KiB/, Berlinrb::ImageCheck.errors([image]).first)
      assert_empty Berlinrb::ImageCheck.errors([File.join(dir, "deleted.jpg")])
    end
  end

  def test_photo_requires_thumbnail_and_rejects_invalid_jpeg
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p("photos/1/thumbs")
        FileUtils.cp(File.expand_path("fixtures/photo.jpg", __dir__), "photos/1/a.jpg")
        assert_match(/missing thumbnail/, Berlinrb::ImageCheck.errors(["photos/1/a.jpg"]).first)
        FileUtils.cp("photos/1/a.jpg", "photos/1/thumbs/a.jpg")
        assert_empty Berlinrb::ImageCheck.errors(Dir["photos/**/*.jpg"])
        File.write("photos/1/a.jpg", "invalid")
        assert_match(/invalid JPEG/, Berlinrb::ImageCheck.errors(["photos/1/a.jpg"]).first)
      end
    end
  end
end
