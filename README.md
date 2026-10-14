# Berlin.rb

The site for berlinrb.org: a static site with a page per meetup and per talk.

- `data/meetups.yml` holds the meetups and their talks. Edit it by hand for things no source knows, such as the host or slides.
- `bin/sync` updates it from Luma (dates, venues, descriptions, in person and livestream signups), the Basecamp Talks card table (talk titles, abstracts and formats from Scheduled and Done cards) and the YouTube channel (recordings and their thumbnails). The `Update meetups and talks` workflow runs it daily and opens a pull request. In CI, Basecamp is read with the `BASECAMP_TOKEN` secret, which `bin/refresh-basecamp-token` copies from a maintainer's signed-in `basecamp` CLI (a daily systemd timer on that machine runs it; tokens last two weeks). Locally, `bin/sync` uses the CLI directly.
- Talks only come from Basecamp. A YouTube video attaches to the talk by the same speaker; videos without a talk are ignored. Talks are listed in the order the Luma description names their speakers.
- Meetup lists show each talk by its short title (the part before a colon, or a card's "Short title" line) and speaker.
- Basecamp is the source of truth for talks: each meetup shows exactly the Scheduled and Done cards due on its date, with or without a title yet.
- Photos go in `photos/<meetup number>/` through a pull request; the `Prepare photos` workflow runs `bin/photos` to resize them, strip their metadata and write thumbnails. See `photos/README.md`.
- `bin/build` writes the site into `_site`, and `bin/dev` builds and serves it. The deploy workflow builds on every push and daily after midnight, so a meetup moves to Past meetups the day after.
- Tests: `for test in test/*_test.rb; do ruby "$test"; done`.
