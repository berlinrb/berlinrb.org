// Live numbers from api.berlinrb.org/live: who's going to the upcoming
// meetups, and how much stage time each still has. Pages work without it;
// these only fill in or update what the build already wrote.
(() => {
  const api = document.querySelector('meta[name="berlinrb-api"]')?.content
  const now = Date.now()

  // During a meetup, say so.
  document.querySelectorAll("[data-live-start]").forEach((element) => {
    const start = Date.parse(element.dataset.liveStart)
    const end = Date.parse(element.dataset.liveEnd)
    if (now >= start && now <= end) {
      element.hidden = false
      element.classList.add("is-live")
      if (element.dataset.liveText) element.textContent = element.dataset.liveText
    }
  })

  if (!api) return
  fetch(`${api}/live`)
    .then((response) => response.json())
    .then(({ meetups }) => {
      document.querySelectorAll("[data-live-going]").forEach((element) => {
        const meetup = meetups[element.dataset.liveGoing]
        if (!meetup || !(meetup.going || meetup.online)) return
        const parts = [`${meetup.going} going`]
        if (meetup.online) parts.push(`${meetup.online} on the livestream`)
        element.textContent = parts.join(" · ")
        element.hidden = false
      })
      document.querySelectorAll("[data-live-stats]").forEach((element) => {
        const meetup = meetups[element.dataset.liveStats]
        if (!meetup || !(meetup.going || meetup.online)) return
        element.querySelector('[data-stat="going"]').textContent = meetup.going
        element.querySelector('[data-stat="online"]').textContent = meetup.online ?? 0
        element.hidden = false
      })
      document.dispatchEvent(new CustomEvent("berlinrb:live", { detail: meetups }))
    })
    .catch(() => {})
})()
