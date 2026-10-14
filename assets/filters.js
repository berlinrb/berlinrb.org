// Filter pills: a [data-filters] group of buttons shows only the items in
// [data-filter-items] whose data-kind matches. Without JavaScript the pills
// stay hidden and everything shows.
(() => {
  document.querySelectorAll("[data-filters]").forEach((group) => {
    const items = document.querySelectorAll(`[data-filter-items="${group.dataset.filters}"] [data-kind]`)
    const buttons = group.querySelectorAll("button")
    group.hidden = false
    buttons.forEach((button) => button.addEventListener("click", () => {
      const kind = button.dataset.filter
      buttons.forEach((other) => other.setAttribute("aria-pressed", String(other === button)))
      items.forEach((item) => { item.hidden = kind !== "all" && item.dataset.kind !== kind })
    }))
  })
})()
