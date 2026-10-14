// Opens gallery photos in a full-screen viewer with previous and next.
// Without JavaScript, each thumbnail links to the full photo.
(() => {
  const galleries = document.querySelectorAll(".gallery")
  if (!galleries.length || !window.HTMLDialogElement) return

  const dialog = document.createElement("dialog")
  dialog.className = "lightbox"
  dialog.setAttribute("aria-label", "Photo viewer")
  dialog.innerHTML = `
    <img alt="">
    <div class="lightbox-bar">
      <span class="lightbox-count" aria-live="polite"></span>
      <span class="lightbox-buttons">
        <button type="button" data-step="-1" aria-label="Previous photo">&larr;</button>
        <button type="button" data-step="1" aria-label="Next photo">&rarr;</button>
        <button type="button" data-close aria-label="Close">&times;</button>
      </span>
    </div>`
  document.body.append(dialog)

  const image = dialog.querySelector("img")
  const count = dialog.querySelector(".lightbox-count")
  let links = []
  let index = 0

  const show = (next) => {
    index = (next + links.length) % links.length
    const link = links[index]
    image.src = link.href
    image.alt = link.querySelector("img").alt
    count.textContent = `${index + 1} of ${links.length}`
  }

  galleries.forEach((gallery) => {
    const items = [...gallery.querySelectorAll("a")]
    items.forEach((link, i) => link.addEventListener("click", (event) => {
      if (event.metaKey || event.ctrlKey || event.shiftKey) return
      event.preventDefault()
      links = items
      show(i)
      dialog.showModal()
    }))
  })

  dialog.addEventListener("click", (event) => {
    const step = event.target.closest("[data-step]")
    if (step) show(index + Number(step.dataset.step))
    else if (event.target.closest("[data-close]") || event.target === dialog) dialog.close()
  })

  dialog.addEventListener("keydown", (event) => {
    if (event.key === "ArrowLeft") show(index - 1)
    if (event.key === "ArrowRight") show(index + 1)
  })
})()
