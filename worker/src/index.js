// Receives the forms on berlinrb.org/get-involved/ and files each one as a
// card in the Triage column of the matching Basecamp card table.

const FORMATS = ["Lightning (5 min)", "Short (20 min)", "Talk (40 min)", "Long (55 min)"]
const LIMITS = { name: 120, email: 200, title: 200, abstract: 4000, company: 160, address: 300, notes: 3000, links: 500, capacity: 10, cover: 120 }

export default {
  async fetch(request, env) {
    const url = new URL(request.url)
    const cors = corsHeaders(request, env)
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors })
    if (request.method !== "POST" || !["/talks", "/companies"].includes(url.pathname)) {
      return json({ error: "Not found" }, 404, cors)
    }

    let fields
    try {
      fields = await readFields(request)
    } catch {
      return reply(request, env, cors, 400, "We couldn't read that form.")
    }
    // Bots fill every field; people never see this one.
    if (fields.website) return reply(request, env, cors, 200)

    const card = url.pathname === "/talks" ? talkCard(fields) : companyCard(fields)
    if (card.error) return reply(request, env, cors, 422, card.error)

    const column = url.pathname === "/talks" ? env.TALKS_TRIAGE : env.COMPANIES_TRIAGE
    const response = await fetch(
      `https://3.basecampapi.com/${env.BASECAMP_ACCOUNT}/buckets/${env.BASECAMP_PROJECT}/card_tables/lists/${column}/cards.json`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${env.BASECAMP_TOKEN}`,
          "Content-Type": "application/json",
          "User-Agent": "berlinrb.org forms (hello@berlinrb.org)"
        },
        body: JSON.stringify({ title: card.title, content: card.content })
      }
    )
    if (!response.ok) {
      console.error("Basecamp", response.status, await response.text())
      return reply(request, env, cors, 502, "Something went wrong on our side. Please write to hello@berlinrb.org instead.")
    }
    return reply(request, env, cors, 200)
  }
}

export async function readFields(request) {
  const type = request.headers.get("Content-Type") || ""
  const raw = type.includes("application/json") ? await request.json() : Object.fromEntries(await multi(await request.formData()))
  const fields = {}
  for (const [key, value] of Object.entries(raw)) {
    fields[key] = Array.isArray(value) ? value.map((v) => clean(v, 40)) : clean(value, LIMITS[key] || 200)
  }
  return fields
}

async function multi(form) {
  const entries = new Map()
  for (const [key, value] of form.entries()) {
    const name = key.replace(/\[\]$/, "")
    if (key.endsWith("[]")) entries.set(name, [...(entries.get(name) || []), value])
    else entries.set(name, value)
  }
  return entries
}

function clean(value, limit) {
  return String(value ?? "").replace(/\r\n?/g, "\n").trim().slice(0, limit)
}

export function talkCard(f) {
  if (!f.name || !validEmail(f.email) || !f.title || !f.abstract) {
    return { error: "Please fill in your name, email, the talk's title and what it's about." }
  }
  const format = FORMATS.includes(f.format) ? f.format : "Talk (40 min)"
  const dates = (Array.isArray(f.dates) ? f.dates : [f.dates]).filter((d) => /^\d{4}-\d{2}-\d{2}$/.test(d))
  return {
    title: `${f.name}: ${f.title}`,
    content: lines([
      ["Format", format],
      ["Dates", dates.length ? dates.map(prettyDate).join(", ") : "any"],
      ["Title", f.title],
      ["Abstract", f.abstract],
      ["Contact", f.email],
      ["Links", f.links],
      ["Notes", [f.first_talk ? "This would be their first talk." : "", f.notes, "Submitted on berlinrb.org."].filter(Boolean).join(" ")]
    ])
  }
}

export function companyCard(f) {
  const role = f.kind === "sponsor" ? "Sponsor" : "Host"
  if (!f.name || !validEmail(f.email) || !f.company) {
    return { error: "Please fill in your name, email and company." }
  }
  return {
    title: f.company,
    content: lines([
      ["Role", `Wants to ${role === "Host" ? "host" : "sponsor"} a meetup`],
      ["Contact", `${f.name}, ${f.email}`],
      ["Seats", f.capacity],
      ["Address", f.address],
      ["Would cover", f.cover],
      ["Notes", [f.notes, "Submitted on berlinrb.org."].filter(Boolean).join(" ")]
    ])
  }
}

// Card bodies use the same "Label: value" lines as every card, so the site
// sync can read them back.
function lines(pairs) {
  return pairs
    .filter(([, value]) => value)
    .map(([label, value]) => `<p><strong>${label}:</strong> ${escape(value).replace(/\n{2,}/g, "</p><p>").replace(/\n/g, "<br>")}</p>`)
    .join("")
}

function prettyDate(iso) {
  return new Date(`${iso}T12:00:00Z`).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" })
}

function validEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email || "")
}

export function escape(text) {
  return String(text).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c])
}

function corsHeaders(request, env) {
  const origin = request.headers.get("Origin") || ""
  const allowed = origin === env.SITE || /^http:\/\/(127\.0\.0\.1|localhost):\d+$/.test(origin)
  return allowed
    ? { "Access-Control-Allow-Origin": origin, "Access-Control-Allow-Methods": "POST, OPTIONS", "Access-Control-Allow-Headers": "Content-Type", Vary: "Origin" }
    : {}
}

// Scripts get JSON; a plain form post (no JavaScript) is sent back to the page.
function reply(request, env, cors, status, error) {
  if ((request.headers.get("Accept") || "").includes("application/json")) {
    return json(error ? { error } : { ok: true }, status, cors)
  }
  const back = new URL("/get-involved/", env.SITE)
  back.searchParams.set(error ? "error" : "sent", error || "1")
  return Response.redirect(back.toString(), 303)
}

function json(body, status, headers) {
  return new Response(JSON.stringify(body), { status, headers: { ...headers, "Content-Type": "application/json" } })
}
