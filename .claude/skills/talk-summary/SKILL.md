---
name: talk-summary
description: Write the summary page for a recorded Berlin.rb talk, data/talks/<video id>.md, from a transcript of its recording. Use when someone shares a talk transcript (for example a MacWhisper export) and asks to summarise the talk, write its chapters, or add or update a talk summary for berlinrb.org.
---

# Talk summary

A recorded talk's page on berlinrb.org can show a summary under the video:
chapters, a summary that opens with the whole talk in one paragraph,
background on the ideas it builds on, and the links it mentions. This skill
turns a transcript of the recording into that file. The site renders it with
`lib/berlinrb/markdown.rb`, and `assets/player.js` turns its timestamps into
buttons that play the video at that moment.

The summary appears under the speaker's name, so accuracy matters more than
polish. Nothing goes live until the speaker has approved it.

## What you need

- **The talk's video id.** Find the talk in `data/meetups.yml`; its `video:`
  value is the YouTube id. The file is `data/talks/<video id>.md`.
- **A transcript with timestamps**, ideally with speaker labels: a MacWhisper
  export, or YouTube's captions. Ask for one if you don't have it.

Check that the transcript covers the whole recording: its last timestamp
should be within a few seconds of the video's length. If it doesn't match (an
edited recording, or a transcript of the livestream), the timestamps would
point at the wrong moments, so stop and say so.

Never commit the transcript. It contains the audience's voices too.

## Steps

1. Read the whole transcript before writing anything.
2. Work out who speaks when: the speaker, the host, and audience members in
   the Q&A.
3. Correct names the transcription got wrong, such as companies, people,
   gems and tools, by checking a real source (RubyGems, GitHub, the
   project's site). If you can't confirm a name, leave the thing out rather
   than guess.
4. Write the file in the format below.
5. Check every link loads, and every timestamp points at the moment its
   heading describes.
6. Run the tests (`for test in test/*_test.rb; do ruby "$test"; done`), then
   `bin/dev` and open the talk page. Press play and click a few timestamps.
7. Before anything is merged, send the speaker their draft. The site only
   deploys from `main`, so send a preview: screenshots or a PDF of the page
   from `bin/dev`, or the Markdown file itself. They can edit the text or ask
   us not to publish it. Merge only after they've said yes, and note in the
   pull request where they did; if they say no, delete the file.

## Format

Four sections, in this order, with exactly these headings. The page styles
them by name.

```markdown
## Chapters

- [0:00](https://www.youtube.com/watch?v=<id>&t=0s) Who the speaker is, and the problem
- [4:34](https://www.youtube.com/watch?v=<id>&t=274s) The first big idea
- [54:14](https://www.youtube.com/watch?v=<id>&t=3254s) Questions from the audience

## Summary

One paragraph of 80 to 120 words that tells someone who will never watch the
video what the talk argues, how, and what came of it. Search engines show this
paragraph, so make it stand on its own.

### First section heading [6:33](https://www.youtube.com/watch?v=<id>&t=393s)

Paragraphs.

#### A part within it [17:13](https://www.youtube.com/watch?v=<id>&t=1033s)

### Takeaways [51:34](https://www.youtube.com/watch?v=<id>&t=3094s)

- Short points, in the speaker's terms.

### From the Q&A [54:14](https://www.youtube.com/watch?v=<id>&t=3254s)

- **The question, in short?** The answer. [54:25](https://www.youtube.com/watch?v=<id>&t=3265s)

## Background

Short explanations of ideas the talk builds on, written by Berlin.rb.

- **A concept.** Two or three sentences explaining it. [14:05](https://www.youtube.com/watch?v=<id>&t=845s)

## Mentioned in the talk

- [Name](https://example.org): what it is, in one line.
```

- **Chapters:** 10 to 20 of them, starting at 0:00. End with the Q&A if
  there was one.
- **Timestamps** are links to the talk's own video with `&t=<seconds>s`. Write
  them as `m:ss` (or `h:mm:ss` past an hour).
- **Supported Markdown only:** paragraphs, `##` to `####` headings, `- ` lists
  (one level), `**bold**`, `` `code` `` and `[links](https://...)`. Anything
  else, such as italics, tables, nested lists or HTML, shows as plain text.

## Writing rules

- **Only what the speaker said.** Every claim in Summary must trace back to
  the transcript, and numbers must be as the speaker gave them. Quote only
  words they actually said. When the transcript is unclear, leave the point
  out.
- **Background is ours.** It explains concepts the talk relies on, in our
  words. Keep it to well-established facts, and never present it as the
  speaker's view.
- **Never name audience members**, even when the host does. Write "an
  audience member asked" and "the host".
- **Plain, direct English.** Short sentences, active voice, no em dashes, no
  hype. Describe what the speaker argued; don't grade it.
- **Leave out** profanity, asides about people, and anything the speaker
  flagged as private or not yet public.
