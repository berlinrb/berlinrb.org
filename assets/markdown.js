// Copies a page's Markdown version, for pasting into an AI assistant. The
// button stays hidden without JavaScript or a clipboard; the link beside it
// still opens the Markdown.
(() => {
  if (!navigator.clipboard) return

  for (const button of document.querySelectorAll("[data-copy-markdown]")) {
    const label = button.textContent
    const say = (text) => {
      button.textContent = text
      setTimeout(() => (button.textContent = label), 2000)
    }
    button.hidden = false
    button.addEventListener("click", async () => {
      const text = fetch(button.dataset.copyMarkdown).then((response) => {
        if (!response.ok) throw new Error(response.statusText)
        return response.text()
      })
      try {
        // Safari only copies inside the click, so hand it the pending text.
        if (window.ClipboardItem) {
          const blob = text.then((markdown) => new Blob([markdown], { type: "text/plain" }))
          await navigator.clipboard.write([new ClipboardItem({ "text/plain": blob })])
        } else {
          await navigator.clipboard.writeText(await text)
        }
        say("Copied")
      } catch {
        say("Couldn't copy")
      }
    })
  }
})()
