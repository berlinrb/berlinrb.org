# Meetup photos

Each meetup's photos go in a folder named after its number: `photos/3/` for Berlin.rb #3.

To add photos:

1. On your computer, put the photos in a folder named after the meetup number, for example `3`.
2. On GitHub, open this `photos` folder, choose **Add file → Upload files**, drag the whole folder in, pick **Create a new branch and start a pull request**, and open the pull request.
3. A workflow resizes them, removes their metadata (camera, location), adds thumbnails, and commits that to the pull request. Merge it and they appear on the meetup page and on berlinrb.org/photos.

JPEG and PNG work. Pick the good ones; no need to resize anything first. To credit the photographer, set `photographer:` on the meetup in `data/meetups.yml`. To take a photo down, delete it and its thumbnail.
