# Berlin.rb

The site for berlinrb.org: a static site with a page per meetup and per talk.

- `data/meetups.yml` holds the meetups and their talks. Edit it by hand for things no source knows, such as the host or slides.
- `bin/sync` updates it from Luma (dates, venues, signups, livestreams), the Basecamp Talks card table (talk titles, abstracts and formats from Scheduled and Done cards) and the YouTube channel (recordings and their thumbnails). The `Update meetups and talks` workflow runs the Luma and YouTube parts daily and opens a pull request. Basecamp needs a signed-in `basecamp` CLI, so run `bin/sync` locally for it.
- A talk on an upcoming meetup appears once the meetup's Luma page names its speaker.
- Photos go in `photos/<meetup number>/` through a pull request; the `Prepare photos` workflow runs `bin/photos` to resize them, strip their metadata and write thumbnails. See `photos/README.md`.
- `bin/build` writes the site into `_site`, and `bin/dev` builds and serves it. The deploy workflow builds on every push and daily after midnight, so a meetup moves to Past meetups the day after.
- Tests: `for test in test/*_test.rb; do ruby "$test"; done`.
