// Receives the forms on berlinrb.org/get-involved/ and files each one as a
// card in the Triage column of the matching Basecamp card table.

const FORMATS = ["Lightning (5 min)", "Short (20 min)", "Talk (40 min)", "Long (55 min)"]
const LIMITS = { name: 120, email: 200, title: 200, abstract: 4000, company: 160, address: 300, notes: 3000, links: 500, capacity: 10, cover: 120 }

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url)
    if (request.method === "GET" && url.pathname === "/live") return live(env, ctx)
    if (request.method === "GET" && url.pathname === "/health") return health(env, ctx)
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
    let response
    try {
      response = await basecampFetch(env, `https://3.basecampapi.com/${env.BASECAMP_ACCOUNT}/buckets/${env.BASECAMP_PROJECT}/card_tables/lists/${column}/cards.json`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title: card.title, content: card.content })
      })
    } catch (error) {
      response = { ok: false, status: 0, text: async () => error.message }
    }
    if (!response.ok) {
      console.error("Basecamp", response.status, await response.text())
      return reply(request, env, cors, 502, "Something went wrong on our side. Please write to hello@berlinrb.org instead.")
    }
    return reply(request, env, cors, 200)
  }
}

// Live numbers for the upcoming meetups, keyed by date: who's going in
// person and on the livestream (from Luma), and the stage time still free
// (from the Scheduled column in Basecamp). Cached for five minutes.
const LIVE_SECONDS = 300

async function live(env, ctx) {
  const cache = caches.default
  const key = new Request(`${env.SITE}/live-cache`)
  const cached = await cache.match(key)
  if (cached) return cached

  const meetups = {}
  const [luma, stage] = await Promise.allSettled([lumaCounts(), stageMinutes(env)])
  if (luma.status === "fulfilled") Object.assign(meetups, luma.value)
  else console.error("Luma", luma.reason)
  if (stage.status === "fulfilled") {
    for (const [date, used] of Object.entries(stage.value)) {
      meetups[date] = { ...meetups[date], free: Math.max(Number(env.STAGE_MINUTES || 80) - used, 0) }
    }
  } else console.error("Basecamp", stage.reason)

  const response = new Response(JSON.stringify({ updated_at: new Date().toISOString(), meetups }), {
    headers: { "Content-Type": "application/json", "Cache-Control": `public, max-age=${LIVE_SECONDS}`, "Access-Control-Allow-Origin": "*" }
  })
  ctx?.waitUntil?.(cache.put(key, response.clone()))
  return response
}

export async function lumaCounts() {
  const entries = []
  let cursor
  do {
    const query = new URLSearchParams({ calendar_api_id: "cal-21caVAhECUCuGR6", period: "future", pagination_limit: "50" })
    if (cursor) query.set("pagination_cursor", cursor)
    const response = await fetch(`https://api.lu.ma/calendar/get-items?${query}`, { headers: { "User-Agent": "berlinrb.org (hello@berlinrb.org)" } })
    if (!response.ok) throw new Error(`Luma responded with ${response.status}`)
    const data = await response.json()
    entries.push(...data.entries)
    cursor = data.has_more ? data.next_cursor : null
  } while (cursor)

  const dates = {}
  const online = {}
  for (const { event, guest_count: guests } of entries) {
    const number = event.name.match(/#(\d+)/)?.[1]
    if (!number || event.visibility !== "public") continue
    if (event.location_type === "offline") dates[number] = { date: berlinDate(event.start_at), going: guests || 0 }
    else online[number] = guests || 0
  }
  return Object.fromEntries(Object.entries(dates).map(([number, { date, going }]) => [date, { going, online: online[number] ?? null }]))
}

// Whether the forms can file cards: the token reads the Talks card table and
// finds its Triage column. A scheduled GitHub workflow polls this and fails
// when it does, so a refused token is noticed before a speaker hits it.
// Cached for a minute, so polling it can't use up Basecamp's rate limit.
const HEALTH_SECONDS = 60

async function health(env, ctx) {
  const cache = caches.default
  const key = new Request(`${env.SITE}/health-cache`)
  const cached = await cache.match(key)
  if (cached) return cached

  let problem = null
  try {
    const table = await talksTable(env)
    if (!table.lists?.some((list) => String(list.id) === String(env.TALKS_TRIAGE))) problem = "The Talks card table has no Triage column with TALKS_TRIAGE's id"
  } catch (error) {
    problem = error.message
  }
  if (problem) console.error("Health", problem)
  const response = new Response(JSON.stringify({ ok: !problem, basecamp: problem || "ok", checked_at: new Date().toISOString() }), {
    status: problem ? 503 : 200,
    headers: { "Content-Type": "application/json", "Cache-Control": `public, max-age=${HEALTH_SECONDS}` }
  })
  ctx?.waitUntil?.(cache.put(key, response.clone()))
  return response
}

// Basecamp access tokens last two weeks. The Worker mints its own from the
// berlinrb.org Launchpad app's refresh token (BASECAMP_CLIENT_ID,
// BASECAMP_CLIENT_SECRET, BASECAMP_REFRESH_TOKEN, set by
// bin/set-basecamp-token), keeps it for the life of the isolate, and mints
// another when Basecamp refuses it. A plain BASECAMP_TOKEN is used when
// there is no refresh token (tests, local runs).
let minted = null

export function forgetToken() {
  minted = null
}

async function basecampToken(env, { fresh = false } = {}) {
  if (!env.BASECAMP_REFRESH_TOKEN) return env.BASECAMP_TOKEN
  if (!fresh && minted && minted.expires > Date.now()) return minted.token
  const response = await fetch("https://launchpad.37signals.com/authorization/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded", "User-Agent": "berlinrb.org forms (hello@berlinrb.org)" },
    body: new URLSearchParams({ type: "refresh", client_id: env.BASECAMP_CLIENT_ID, client_secret: env.BASECAMP_CLIENT_SECRET, refresh_token: env.BASECAMP_REFRESH_TOKEN })
  })
  if (!response.ok) throw new Error(`Launchpad refused the refresh token with ${response.status}`)
  const { access_token: token, expires_in: seconds } = await response.json()
  minted = { token, expires: Date.now() + Math.min(Number(seconds) || 3600, 86400) * 1000 }
  return token
}

async function basecampFetch(env, url, init = {}) {
  const send = async (token) => fetch(url, { ...init, headers: { ...init.headers, Authorization: `Bearer ${token}`, "User-Agent": "berlinrb.org forms (hello@berlinrb.org)" } })
  const response = await send(await basecampToken(env))
  if (response.status !== 401 || !env.BASECAMP_REFRESH_TOKEN) return response
  return send(await basecampToken(env, { fresh: true }))
}

async function basecampGet(env, url) {
  const response = await basecampFetch(env, url)
  if (!response.ok) throw new Error(`Basecamp responded with ${response.status}${response.headers.get("WWW-Authenticate") ? ` (${response.headers.get("WWW-Authenticate")})` : ""}`)
  return response
}

async function talksTable(env) {
  return (await basecampGet(env, `https://3.basecampapi.com/${env.BASECAMP_ACCOUNT}/buckets/${env.BASECAMP_PROJECT}/card_tables/${env.TALKS_TABLE}.json`)).json()
}

export async function stageMinutes(env) {
  const get = (url) => basecampGet(env, url)
  const table = await talksTable(env)
  const scheduled = table.lists.find((list) => list.title === "Scheduled")
  const used = {}
  let url = scheduled?.cards_url
  while (url) {
    const response = await get(url)
    for (const card of await response.json()) {
      if (!card.due_on) continue
      const minutes = Number(card.content?.match(/Format:<\/strong>[^<(]*\((\d+) min\)/)?.[1] || 40)
      used[card.due_on] = (used[card.due_on] || 0) + minutes
    }
    url = response.headers.get("Link")?.match(/<([^>]+)>;\s*rel="next"/)?.[1]
  }
  return used
}

function berlinDate(iso) {
  return new Date(iso).toLocaleDateString("en-CA", { timeZone: "Europe/Berlin" })
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
