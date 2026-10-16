# Meetup photos

Each meetup's photos go in a folder named after its number: `photos/3/` for Berlin.rb #3.

To add photos:

1. On your computer, put the photos in a folder named after the meetup number, for example `3`.
2. On GitHub, open this `photos` folder, choose **Add file → Upload files**, drag the whole folder in, pick **Create a new branch and start a pull request**, and open the pull request.
3. A workflow resizes them, removes their metadata (camera, location), adds thumbnails, and commits that to the pull request. Merge it and they appear on the meetup page and on berlinrb.org/photos.

JPEG and PNG work. Pick the good ones; no need to resize anything first. To credit the photographer, set `photographer:` on the meetup in `data/meetups.yml`. To take a photo down, delete it and its thumbnail.

## Local preparation (recommended)

Copy new, unique photos into `photos/<meetup number>/`, keeping originals outside the repository. Install ImageMagick (`brew install imagemagick` on macOS), then run `bin/photos` before staging. This makes JPEGs with a maximum edge of 1600px, strips metadata, and creates 640px thumbnails. Review the results, then run `bin/check-images`.

CI rejects raster images over 1 MiB, thumbnails over 150 KiB, unprepared meetup images, oversized photo dimensions, and missing thumbnails. The upload workflow is a convenience for same-repository pull requests; local preparation keeps originals out of Git history.

For the same check before committing, install Overcommit with `gem install overcommit`, then run `overcommit --install` and `overcommit --sign` and `overcommit --sign pre-commit` after reviewing `.overcommit.yml`. Overcommit checks the staged snapshot by temporarily hiding unstaged changes. The check reports problems without rewriting files.
