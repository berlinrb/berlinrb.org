# Berlin.rb

The site for berlinrb.org: a static site with a page per meetup and per talk.

- `data/meetups.yml` holds the meetups and their talks. Edit it by hand for things no source knows, such as the host or slides.
- `bin/sync` updates it from Luma (dates, venues, descriptions, in person and livestream signups), the Basecamp Talks card table (talk titles, abstracts and formats from Scheduled and Done cards) and the YouTube channel (recordings and their thumbnails). The `Update meetups and talks` workflow runs it daily and opens a pull request. In CI, Basecamp is read with the `BASECAMP_TOKEN` secret, which `bin/refresh-basecamp-token` copies from a maintainer's signed-in `basecamp` CLI (a daily systemd timer on that machine runs it; tokens last two weeks). Locally, `bin/sync` uses the CLI directly.
- Talks only come from Basecamp. A YouTube video attaches to the talk by the same speaker; videos without a talk are ignored. Talks are listed in the order the Luma description names their speakers.
- Meetup lists show each talk by its short title (the part before a colon, or a card's "Short title" line) and speaker.
- Upcoming meetup pages show a description written from the Basecamp talks (`lib/berlinrb/luma_description.rb`). When Luma's description differs, `bin/sync` adds a to-do to the "Luma descriptions" list in Basecamp with the text to paste, and completes it once Luma matches. Luma's free plan has no API, so the paste is by hand.
- Basecamp is the source of truth for talks: each meetup shows exactly the Scheduled and Done cards due on its date, with or without a title yet.
- The forms on `/get-involved/` post to a Cloudflare Worker at `api.berlinrb.org` (`worker/`), which files talk proposals into the Talks card table's Triage and host or sponsor enquiries into the Companies card table's Triage. Deploy it with `npx wrangler deploy` in `worker/`; `bin/refresh-basecamp-token` keeps its `BASECAMP_TOKEN` secret fresh along with the GitHub one. It also serves `/live` (cached five minutes): who's going to each upcoming meetup from Luma and the stage time still free from Basecamp, which `assets/live.js` shows on the home, meetup and Get involved pages. Test it with `node --test` in `worker/`.
- Photos go in `photos/<meetup number>/` through a pull request; the `Prepare photos` workflow runs `bin/photos` to resize them, strip their metadata and write thumbnails. See `photos/README.md`.
- `bin/build` writes the site into `_site`, and `bin/dev` builds and serves it. The deploy workflow builds on every push and daily after midnight, so a meetup moves to Past meetups the day after.
- Tests: `for test in test/*_test.rb; do ruby "$test"; done`.
