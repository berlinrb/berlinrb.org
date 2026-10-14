// Get involved: one panel at a time (picked by #speak, #host or #sponsor),
// dates greyed out when the chosen format no longer fits, and forms sent
// without leaving the page. Without JavaScript all three panels show and the
// forms post normally.
(() => {
  const panels = [...document.querySelectorAll(".involve-panel")]
  if (!panels.length) return
  const tabs = [...document.querySelectorAll(".involve-tabs a")]
  const status = document.querySelector(".form-status")

  const show = () => {
    const id = panels.some((panel) => `#${panel.id}` === location.hash) ? location.hash.slice(1) : panels[0].id
    panels.forEach((panel) => { panel.hidden = panel.id !== id })
    tabs.forEach((tab) => tab.setAttribute("aria-current", tab.hash === `#${id}` ? "page" : "false"))
  }
  document.documentElement.classList.add("involve-js")
  addEventListener("hashchange", show)
  show()

  const params = new URLSearchParams(location.search)
  if (params.has("sent") || params.has("error")) {
    status.hidden = false
    status.textContent = params.has("sent") ? "Thanks, it's with the organizers. We'll reply by email." : params.get("error")
    status.classList.toggle("form-status-error", params.has("error"))
  }

  const format = document.querySelector('[data-form="talk"] select[name="format"]')
  const fitDates = () => {
    const minutes = Number(format.selectedOptions[0].dataset.minutes)
    document.querySelectorAll(".date-option").forEach((option) => {
      const input = option.querySelector("input")
      input.disabled = Number(option.dataset.free) < minutes
      if (input.disabled) input.checked = false
    })
  }
  format?.addEventListener("change", fitDates)
  if (format) fitDates()

  document.querySelectorAll(".involve-form").forEach((form) => {
    form.addEventListener("submit", async (event) => {
      event.preventDefault()
      const button = form.querySelector('button[type="submit"]')
      button.disabled = true
      const data = {}
      new FormData(form).forEach((value, key) => {
        if (key.endsWith("[]")) (data[key.slice(0, -2)] ||= []).push(value)
        else data[key] = value
      })
      try {
        const response = await fetch(form.action, {
          method: "POST",
          headers: { "Content-Type": "application/json", Accept: "application/json" },
          body: JSON.stringify(data)
        })
        const body = await response.json().catch(() => ({}))
        if (!response.ok) throw new Error(body.error || "Something went wrong. Please write to hello@berlinrb.org instead.")
        const done = document.createElement("div")
        done.className = "form-done"
        done.setAttribute("role", "status")
        done.innerHTML = "<h3>Thanks, it's with the organizers.</h3><p>We'll reply by email. Questions in the meantime: <a href=\"mailto:hello@berlinrb.org\">hello@berlinrb.org</a>.</p>"
        form.replaceWith(done)
      } catch (error) {
        let message = form.querySelector(".form-error")
        if (!message) {
          message = document.createElement("p")
          message.className = "form-error"
          message.setAttribute("role", "alert")
          button.before(message)
        }
        message.textContent = error.message === "Failed to fetch" ? "We couldn't reach our server. Please try again, or write to hello@berlinrb.org." : error.message
        button.disabled = false
      }
    })
  })
})()
