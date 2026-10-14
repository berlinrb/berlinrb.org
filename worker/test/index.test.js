import { test } from "node:test"
import assert from "node:assert/strict"
import worker, { talkCard, companyCard, lumaCounts, stageMinutes } from "../src/index.js"

const env = { TALKS_TABLE: "9", STAGE_MINUTES: "80", SITE: "https://berlinrb.org", BASECAMP_ACCOUNT: "1", BASECAMP_PROJECT: "2", TALKS_TRIAGE: "3", COMPANIES_TRIAGE: "4", BASECAMP_TOKEN: "t" }

test("a talk becomes a card in the sync's format, escaped", () => {
  const card = talkCard({ name: "Ada", email: "ada@example.com", title: "Ruby <3", abstract: "One\n\nTwo", format: "Short (20 min)", dates: ["2026-11-10", "nope"], first_talk: "1" })
  assert.equal(card.title, "Ada: Ruby <3")
  assert.match(card.content, /<strong>Format:<\/strong> Short \(20 min\)/)
  assert.match(card.content, /<strong>Dates:<\/strong> 10 Nov 2026<\/p>/)
  assert.match(card.content, /<strong>Title:<\/strong> Ruby &lt;3/)
  assert.match(card.content, /One<\/p><p>Two/)
  assert.match(card.content, /first talk/)
})

test("missing fields are refused", () => {
  assert.ok(talkCard({ name: "Ada", email: "nope", title: "x", abstract: "y" }).error)
  assert.ok(companyCard({ name: "Ada", email: "ada@example.com" }).error)
})

test("a sponsor enquiry names the role", () => {
  const card = companyCard({ kind: "sponsor", name: "Ada", email: "ada@example.com", company: "Acme", cover: "Food and drinks" })
  assert.equal(card.title, "Acme")
  assert.match(card.content, /Wants to sponsor a meetup/)
  assert.match(card.content, /Would cover:<\/strong> Food and drinks/)
})

test("posts to the right Triage column and answers scripts with JSON", async () => {
  const calls = []
  globalThis.fetch = async (url, init) => { calls.push([url, JSON.parse(init.body)]); return new Response("{}", { status: 201 }) }
  const request = new Request("https://api.berlinrb.org/companies", {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json", Origin: "https://berlinrb.org" },
    body: JSON.stringify({ kind: "host", name: "Ada", email: "ada@example.com", company: "Acme", capacity: "80" })
  })
  const response = await worker.fetch(request, env)
  assert.equal(response.status, 200)
  assert.equal(response.headers.get("Access-Control-Allow-Origin"), "https://berlinrb.org")
  assert.equal(calls[0][0], "https://3.basecampapi.com/1/buckets/2/card_tables/lists/4/cards.json")
  assert.equal(calls[0][1].title, "Acme")
})

test("a plain form post is redirected back, and the honeypot is ignored silently", async () => {
  let called = false
  globalThis.fetch = async () => { called = true; return new Response("{}") }
  const form = new FormData()
  form.set("website", "spam")
  const response = await worker.fetch(new Request("https://api.berlinrb.org/talks", { method: "POST", body: form }), env)
  assert.equal(response.status, 303)
  assert.equal(response.headers.get("Location"), "https://berlinrb.org/get-involved/?sent=1")
  assert.equal(called, false)
})

test("Luma counts are keyed by the in-person date, with the livestream's count", async () => {
  globalThis.fetch = async () => new Response(JSON.stringify({ has_more: false, entries: [
    { event: { name: "Berlin.rb #3 (in person)", visibility: "public", location_type: "offline", start_at: "2026-11-10T17:30:00Z" }, guest_count: 42 },
    { event: { name: "Berlin.rb #3 (livestream)", visibility: "public", location_type: "online", start_at: "2026-11-10T17:30:00Z" }, guest_count: 7 }
  ] }))
  assert.deepEqual(await lumaCounts(), { "2026-11-10": { going: 42, online: 7 } })
})

test("stage time used adds up the Scheduled cards' formats", async () => {
  globalThis.fetch = async (url) => new Response(JSON.stringify(String(url).endsWith("/9.json")
    ? { lists: [{ title: "Done", cards_url: "done" }, { title: "Scheduled", cards_url: "scheduled" }] }
    : [{ due_on: "2026-12-08", content: "<p><strong>Format:</strong> Short (20 min)</p>" }, { due_on: "2026-12-08", content: "" }, { due_on: null }]))
  assert.deepEqual(await stageMinutes(env), { "2026-12-08": 60 })
})
