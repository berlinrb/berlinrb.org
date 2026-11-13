// Each heading in a talk's summary links to itself. Clicking the link puts
// the heading's address in the address bar and copies it, and the icon turns
// into a check for a moment. Without a clipboard it stays an ordinary link
// to the heading.
(() => {
  const links = document.querySelectorAll(".section-link")
  if (!links.length || !navigator.clipboard) return

  const status = document.createElement("span")
  status.className = "visually-hidden"
  status.setAttribute("role", "status")
  document.body.append(status)

  for (const link of links) {
    let timer = 0
    link.addEventListener("click", async (event) => {
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
      event.preventDefault()
      const url = new URL(link.href)
      try {
        await navigator.clipboard.writeText(url.href)
      } catch {
        location.hash = url.hash
        return
      }
      history.replaceState(null, "", url.hash)
      clearTimeout(timer)
      link.classList.add("is-copied")
      status.textContent = "Link copied"
      timer = setTimeout(() => {
        link.classList.remove("is-copied")
        status.textContent = ""
      }, 2000)
    })
  }
})()
