# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/berlinrb/photos"

class PhotosTest < Minitest::Test
  FIXTURE = File.expand_path("fixtures/photo.jpg", __dir__)

  def setup
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@root, "2"))
  end

  def teardown = FileUtils.rm_rf(@root)

  def test_reads_jpeg_dimensions
    assert_equal [30, 20], Berlinrb::Photos.dimensions(FIXTURE)
  end

  def test_names_are_lowercase_slugs
    assert_equal "img-0001", Berlinrb::Photos.name_for("photos/2/IMG 0001.JPG")
  end

  def test_lists_a_meetups_photos_with_thumbnail_sizes
    FileUtils.cp(FIXTURE, File.join(@root, "2", "a.jpg"))

    assert_equal [{ "src" => "/photos/2/a.jpg", "thumb" => "/photos/2/thumbs/a.jpg", "width" => 30, "height" => 20 }],
                 Berlinrb::Photos.new(@root).for(2)
    assert_empty Berlinrb::Photos.new(@root).for(3)
  end

  def test_process_renames_strips_and_writes_thumbnails
    skip "needs ImageMagick" unless system("command -v magick >/dev/null || command -v convert >/dev/null")
    FileUtils.cp(FIXTURE, File.join(@root, "2", "IMG 1.JPG"))
    photos = Berlinrb::Photos.new(@root)

    written = photos.process

    assert_equal %w[2/img-1.jpg 2/thumbs/img-1.jpg], written.map { _1.delete_prefix("#{@root}/") }
    refute File.exist?(File.join(@root, "2", "IMG 1.JPG"))
    assert_empty photos.process, "a second run has nothing to do"
  end
end
