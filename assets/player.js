// Plays a talk's recording on its page. The thumbnail links to YouTube, and
// nothing loads from YouTube until someone presses play: only then does the
// privacy-enhanced embed replace the thumbnail. Timestamp links to the same
// video seek the player instead of leaving the page, and while the summary is
// on screen the player docks in a corner, sized to the room beside the text.
(() => {
  const player = document.querySelector("[data-player]")
  if (!player) return

  const video = player.dataset.player
  const youtube = "https://www.youtube-nocookie.com"
  const slot = player.parentElement
  const start = player.querySelector(".player-start")
  const label = start.querySelector(".video-label")
  const summary = document.querySelector("#summary")
  const measure = summary?.querySelector("h3 ~ p")

  // Only links to this video, with the time in plain seconds ("&t=393s").
  // Anything else stays an ordinary link to YouTube.
  const secondsIn = (href) => {
    if (!href) return null
    const url = new URL(href, location.href)
    const at = url.searchParams.get("t") ?? ""
    const ours = ["www.youtube.com", "youtube.com"].includes(url.hostname) && url.searchParams.get("v") === video
    return ours && /^\d+s?$/.test(at) ? parseInt(at, 10) : null
  }
  const format = (seconds) => {
    const [hours, minutes, rest] = [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, Math.floor(seconds % 60)]
    const pad = (number) => String(number).padStart(2, "0")
    return hours ? `${hours}:${pad(minutes)}:${pad(rest)}` : `${minutes}:${pad(rest)}`
  }

  const chapters = [...document.querySelectorAll(".chapters li")]
    .map((li) => ({ li, at: secondsIn(li.querySelector("a")?.href) }))
    .filter((chapter) => chapter.at !== null)

  let frame = null
  let ready = false
  let queued = null
  let pending = null
  let inView = true
  let dismissed = false

  // The note says what pressing play does. Phones show it under the video
  // instead of over the thumbnail (styles.css picks one).
  const note = `<span class="player-note">Loads the video from YouTube, which may set cookies.</span>`
  label.innerHTML = `Play here${note}`
  const links = document.createElement("p")
  links.className = "player-links"
  links.innerHTML = `${note}<a>Watch on YouTube</a><a href="/privacy/#embeds-title">Privacy</a>`
  links.querySelector("a").href = start.href
  slot.after(links)

  const close = document.createElement("button")
  close.type = "button"
  close.className = "player-close"
  close.setAttribute("aria-label", "Pause and close the floating player")
  close.innerHTML = "&times;"
  player.append(close)

  const send = (message) => frame?.contentWindow?.postMessage(JSON.stringify({ ...message, id: video, channel: "widget" }), youtube)
  const command = (func, args = []) => send({ event: "command", func, args })

  const highlight = (seconds) => {
    const current = chapters.filter((chapter) => chapter.at <= seconds).pop()
    chapters.forEach((chapter) => chapter.li.classList.toggle("is-current", chapter === current))
  }

  function load(at) {
    const params = new URLSearchParams({ autoplay: 1, start: at, enablejsapi: 1, rel: 0, playsinline: 1, origin: location.origin })
    frame = document.createElement("iframe")
    frame.src = `${youtube}/embed/${encodeURIComponent(video)}?${params}`
    frame.title = `${player.dataset.title} (YouTube video)`
    frame.allow = "autoplay; encrypted-media; picture-in-picture; fullscreen"
    frame.allowFullscreen = true
    frame.addEventListener("load", () => listen(40))
    start.replaceWith(frame)
    player.classList.remove("is-pending")
    pending = null
    highlight(at)
  }

  // YouTube's player starts a moment after its frame loads. Until it answers,
  // keep asking it to report its time, as YouTube's own API does; that also
  // marks the current chapter as the video plays.
  function listen(attempts) {
    if (ready || !frame || attempts === 0) return
    send({ event: "listening" })
    setTimeout(() => listen(attempts - 1), 250)
  }

  // A seek or a pause before the player is ready is held until it answers;
  // the latest one wins.
  function play(at) {
    highlight(at)
    if (!ready) {
      queued = at
      return
    }
    command("seekTo", [at, true])
    command("playVideo")
  }

  // Docked, the player stays within the summary: it slides in as the summary
  // starts and scrolls away with its end, so it never covers anything else.
  function place() {
    if (!player.classList.contains("is-floating")) {
      player.style.removeProperty("--float-width")
      player.style.removeProperty("--float-lift")
      return
    }
    const room = window.innerWidth - measure.getBoundingClientRect().right - 56
    const width = room >= 320 ? Math.min(room, 520) : Math.min(360, window.innerWidth - 32)
    const box = summary.getBoundingClientRect()
    const style = getComputedStyle(summary)
    const top = box.top + parseFloat(style.paddingTop)
    const bottom = box.bottom - parseFloat(style.paddingBottom)
    const dockedBottom = window.innerHeight - 16
    const dockedTop = dockedBottom - (width * 9) / 16
    player.style.setProperty("--float-width", `${width}px`)
    player.style.setProperty("--float-lift", `${Math.min(Math.max(0, top - dockedTop), bottom - dockedBottom)}px`)
  }

  function float() {
    const wanted = Boolean(measure) && (frame || pending !== null) && !inView && !dismissed
    player.classList.toggle("is-floating", Boolean(wanted))
    place()
  }

  // A timestamp outside the summary was clicked while the player is out of
  // sight, so bring it back.
  function reveal() {
    const rect = player.getBoundingClientRect()
    const visible = Math.min(rect.bottom, window.innerHeight) - Math.max(rect.top, 0)
    if (visible >= rect.height / 2) return
    const smooth = !window.matchMedia("(prefers-reduced-motion: reduce)").matches
    slot.scrollIntoView({ behavior: smooth ? "smooth" : "instant", block: "center" })
  }

  // Before someone chooses to play here, a timestamp only queues its moment
  // and moves focus to the play button, so keyboard and screen reader users
  // land where the next step is.
  function seek(at) {
    dismissed = false
    if (frame) {
      play(at)
    } else {
      pending = at
      label.firstChild.textContent = `Play here from ${format(at)}`
      player.classList.add("is-pending")
      start.focus({ preventScroll: true })
    }
    float()
    reveal()
  }

  start.addEventListener("click", (event) => {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
    event.preventDefault()
    dismissed = false
    load(pending ?? 0)
    float()
  })

  close.addEventListener("click", () => {
    if (ready) command("pauseVideo")
    else if (frame) queued = "pause"
    dismissed = true
    float()
  })

  document.addEventListener("click", (event) => {
    const link = event.target.closest("a[href]")
    if (!link || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
    const at = secondsIn(link.href)
    if (at === null) return
    event.preventDefault()
    seek(at)
  })

  window.addEventListener("message", (event) => {
    if (event.origin !== youtube || !frame || event.source !== frame.contentWindow) return
    let data
    try { data = JSON.parse(event.data) } catch { return }
    if (!ready) {
      ready = true
      const next = queued
      queued = null
      if (next === "pause") command("pauseVideo")
      else if (next !== null) play(next)
    }
    const seconds = data?.info?.currentTime
    if (typeof seconds === "number") highlight(seconds)
  })

  let scheduled = 0
  const schedule = () => {
    if (scheduled) return
    scheduled = requestAnimationFrame(() => {
      scheduled = 0
      place()
    })
  }
  window.addEventListener("scroll", schedule, { passive: true })
  window.addEventListener("resize", schedule)

  // Docks once less than half the video shows, and undocks once half is back.
  new IntersectionObserver(([entry]) => {
    inView = entry.intersectionRatio >= 0.5
    float()
  }, { threshold: [0, 0.5] }).observe(slot)
})()
