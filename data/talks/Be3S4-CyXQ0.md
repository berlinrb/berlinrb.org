## Chapters

- [0:00](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=0s) Every website starts with a dream
- [2:49](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=169s) Who Paweł is
- [4:06](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=246s) Why a Rails generator matters
- [5:19](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=319s) Naming it HiFuMi
- [6:45](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=405s) What HiFuMi is, and how app generators work
- [9:15](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=555s) Refining the idea in a chat
- [10:30](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=630s) Demo: a landing page for RubyLLM 2.0
- [12:52](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=772s) Every change starts with a plan
- [16:21](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=981s) Adding ideas while it builds
- [18:58](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1138s) What the planner assumes
- [21:24](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1284s) Revisions, each a Git commit
- [22:43](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1363s) Workflows with Roast and Claude Code
- [26:13](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1573s) One Docker container per revision
- [26:49](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1609s) What it costs
- [28:08](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1688s) Previewing the generated app
- [30:26](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1826s) How previews run: Docker and Kamal Proxy
- [34:53](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2093s) Exporting the project
- [36:06](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2166s) Why Rails fits, and more generated apps
- [40:02](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2402s) Questions from the audience
- [58:16](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=3496s) Ruby Community Conference comes to Berlin

## Summary

Paweł Strzałkowski, CTO of [Visuality](https://www.visuality.pl), built [HiFuMi](https://hifumi.dev), an open-source online generator that turns a business idea into a Ruby on Rails app. AI app builders only produce JavaScript, and he argues Rails needs one too, so non-technical people build on Rails and models learn more of it. A RubyLLM chat refines the idea, a planner splits it into revisions, and a Roast workflow has Claude Code implement, verify and commit each one, with tests and docs, in its own Docker container. Kamal Proxy serves a live preview, and the project exports as a plain Git repository. He doesn't plan to make it a product, and sees the cost of hosting Rails, against free JavaScript hosting, as the biggest barrier.

### Why Rails needs an app generator [0:29](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=29s)

Paweł gave this talk as a preview of his talk at Rails World in Austin, three weeks later. Every website starts with a dream, he says, and in 2026 non-technical people take theirs to LLM app generators such as Replit, Lovable or bolt.new, which build JavaScript or TypeScript apps. Why it is only JavaScript came up at every conference and meetup he went to over two years, in 14 countries. He waited for someone to build a Rails version. There were attempts, but nothing anyone could go and try.

Developers can build a Rails app in minutes with Codex or Claude Code. Their parents, children and bosses can't, and they have ideas to test too. The prompt boxes they find generate JavaScript, and some of the next startups will come out of them. Building with Rails spreads awareness of the ecosystem, and the more Rails gets built, the more models learn what Rails is. "If we are not there, people won't be using Ruby on Rails."

#### The name [5:19](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=319s)

Naming took two days of talking to Claude, which insisted on names like Conductor or Wagon. Paweł leaned on Ruby's Japanese roots instead. He can count to 99 in Japanese from training karate, and wanted something as easy as one, two, three. Ichi, ni, san was a mouthful, but the traditional way of counting gives hi, fu, mi, which together is also a Japanese name.

### What HiFuMi is [6:45](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=405s)

HiFuMi runs in production at hifumi.dev, but Paweł calls it a blueprint rather than a product: open-source code for anyone who wants to build a Rails app generator, or to learn how an application can build Rails applications by itself. Anyone can register with their own OpenRouter API key ("I'm not paying for your tokens") or run it locally.

Every online app generator follows the same flow. You describe the idea, the system builds the app, you preview it and ask for changes, and finally you export the project to develop it further. The hard part, which he thinks stopped earlier attempts, is that a Rails app has to run on a server. Early JavaScript generators ran everything in the browser. HiFuMi also writes documentation and tests along the way, so that nobody has to be ashamed of the app they export.

### From idea to plan [9:15](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=555s)

An idea from a client is rarely the one that gets built, so HiFuMi starts with a chat, built with RubyLLM, that asks clarifying questions. Generating a Rails app takes a while, so before starting the chat checks that the user is ready and that all their ideas are in. Each stage, such as chat replies, code generation and docs, can use a different model.

The chat has two tools, create the application and modify it, and only one is available at a time. Inside the tool call, a separate LLM call turns the request into a plan of steps, each with a title and a longer description. In the demo, a request for a page promoting RubyLLM 2.0 became six steps, from a pages controller with a landing page at the root route to a hero section and features. A later change asked to fix the top banner, which "failed successfully" because the tagline still wrapped, and added sign-in and a page to praise RubyLLM.

The user can keep talking while a build runs. New ideas wait until the build is done, then the chat summarises them and asks whether to build. Several requests become one change with one plan. [16:21](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=981s)

#### What the planner assumes [18:58](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1138s)

- **A skeleton app.** HiFuMi doesn't ask the agent to create a Rails app. It copies an app made with `rails new` into the project's workspace.
- **A visual template.** A separate LLM call picks one from a predefined set, and more can be added.
- **Three to six revisions** for the plan that creates a new app, which runs once per project. In hindsight he would allow five to ten.
- **The main feature at the root path.** The planner has to be told this explicitly. Otherwise you can wait half an hour for an app with no link to what was built.
- **The docs.** Every change generates docs on architecture, domain, front end and more, and the modification planner reads them. It also has to be told to reuse the design system. Modifications are capped at six revisions too, but tend towards one.

### Building it revision by revision [21:24](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1284s)

Each step of the plan is a revision, a name Paweł is still unhappy with. When a revision is done, it is committed to the Git repository that `rails new` creates, so the exported app carries its full history.

Each revision runs as a workflow in Roast, Shopify's library for workflows written in a Ruby DSL. Paweł had heard Obie Fernandez talk about it and wanted to use it in a bigger project. (Carmine has since told him RubyLLM could have run the workflows too.) A workflow mixes deterministic steps, such as running RuboCop, with agent steps. For one revision it builds a prompt with the app's current state, its guidelines and the change, lets the agent write the code, verifies it, remediates failures, ensures everything passes, commits, updates the docs and commits them. The agent is Claude Code, using Anthropic models through OpenRouter. Running the plan step by step gives more control and consistency than one long agent run.

Every revision runs in its own Docker container, which knows only that one project and is removed when it finishes. That also isolates tenants from each other. [26:13](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1573s)

#### What it costs [26:49](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1609s)

Cost depends on the models chosen, from Haiku to Sonnet and Opus. Conversations, planning and template selection always go through OpenRouter. Coding and docs, the most expensive parts, can too, but locally HiFuMi can run `claude -p` with `--dangerously-skip-permissions` on your Claude subscription. Coding and docs then cost nothing locally, and run the same CLI as in production.

### Previewing the app [28:08](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1688s)

The preview is the generated app itself. In the demo, Paweł signed in to the RubyLLM page and posted on its praise page. Previews start on demand and take 10 to 30 seconds, because keeping every app ever built running would make no sense.

Starting one "is not hard, it's very straightforward", but it is outside what Rails developers usually do: Docker, a bit of Kamal, and Docker driven from Ruby. HiFuMi builds an image of the project, runs a container, checks its `/up` endpoint as Kamal does, routes it, and tells the front end. Locally, each project gets port 3000 plus its ID, so project 41 runs at localhost:3041. In production, it gets a subdomain under `preview.hifumi.dev`, routed by Kamal Proxy. Paweł says not to copy that part: previews belong on a separate domain for security, as Heroku did. The app uses a lot of Hotwire and Active Support notifications, so when the preview is ready a broadcast replaces the preview frame with an iframe of the app. [30:26](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1826s)

### Export, and why Rails [34:53](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2093s)

The project belongs to the user. They can export it to a private repository, keep changing it in HiFuMi and push again, as long as they don't rewrite the history locally. The export is plain Rails, with decent test coverage and docs on architecture, domain, front end and conventions for future agents. Paweł argues that Rails suits generation: convention over configuration, a test-first mindset, and a database, background jobs and the rest out of the box let you one-shot a fairly big application.

He showed other apps built with HiFuMi: a real estate broker app, a prototype of an internal HR platform for Visuality, and a gym tracker with workouts, measurements and exercise programs. His advice for prompts: "everything you don't say will be used against you". His refined prompt for the broker app says nothing about Rails, controllers or background jobs. It describes the business. [37:12](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2232s)

### From the Q&A [40:02](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2402s)

- **How well does it handle extending an app it built?** As well as it gets, he thinks. Every app has docs on its architecture and domain, plus regression tests, so the agent understands it, and he hasn't found real issues. What he wants next is pasting a screenshot into the chat, which is an open issue in the repository. [40:07](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2407s)
- **HiFuMi runs in Docker and starts Docker containers. How does that fit together?** It is deployed with Kamal, so it runs in a container and spawns new ones. He isn't enough of a Docker expert to speak to performance or pitfalls, and would welcome suggestions. [42:31](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2551s)
- **Could the server drive a browser, take screenshots of the running app and feed them to the agent?** It crossed his mind, but it's a big job, and Tidewave already does this in your own browser and environment. He could use Playwright, since he knows the URL, but would start with pasting images into the chat. [44:02](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2642s)
- **Do the JavaScript generators work the same way, and could you swap JavaScript for Rails in them?** He doesn't know their internals, but thinks the architecture is very different. HiFuMi puts everything in one Docker box, where any integration feels like crossing a boundary, while JavaScript apps are open to the web by design and fetch from databases and APIs. HiFuMi has no technology selector, to stay business-facing. He sees no easy bridge, though in a year or two the technology may not matter anymore. [46:42](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2802s)
- **What guidelines does it give the agent for building the Rails way?** Use the Rails way, though models aren't great at knowing what that is, and use Hotwire for the front end. The prompts were themselves written with Claude, which kept writing rules like "use Hotwire, don't use X", a pitfall he had to force it to avoid. He picked Minitest with fixtures rather than Visuality's own way of using RSpec. How the apps are built is secondary to the project, and his favourite test prompt was the simplest hello world at the root path, to use the fewest tokens. [50:34](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=3034s)
- **Will it deploy apps for non-developers?** He doesn't plan to make HiFuMi a product. Deploying with Kamal is the easy part, and the harder parts are managing DNS for a real domain and renting the VMs. A Rails app needs a VM of perhaps €12 a month, against free JavaScript hosting and a $2 database, and he sees that cost as the biggest barrier. A product would need a lot of funding. [54:03](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=3243s)

### Ruby Community Conference comes to Berlin [58:16](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=3496s)

Visuality runs the Ruby Community Conference, and its next edition comes to Berlin in March 2027, for 200 to 300 people. It starts with a local meetup the day before, here Berlin.rb. The next day brings workshops, then four big talks from the afternoon and an organised after party, and a city tour follows the day after. Tickets are kept as affordable as possible.

## Background

Short explanations of ideas the talk builds on, written by Berlin.rb.

- **Isolating builds in containers.** A container has its own file system, processes and network, and shares only the host's kernel. Running each build in a fresh container that is removed afterwards (`docker run --rm`) means generated code can't see other projects or leave anything behind. [26:13](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1573s)
- **Health checks.** Since Rails 7.1, new apps have an `/up` endpoint that answers once the app has booted. Kamal waits for it before sending traffic to a new container. [30:54](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1854s)
- **Separate domains for user content.** Browsers let pages on subdomains share cookies with their parent domain, so an untrusted app on a subdomain could read or set cookies for the main site. Services that host other people's apps, like Heroku with herokuapp.com, put them on a separate domain, often listed on the Public Suffix List, so each app is isolated. [32:46](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=1966s)
- **Reverse proxy.** A server in front of applications that sends each request, usually by host name, to the right one. Kamal Proxy does this for Kamal deployments, and switches traffic to a new container without downtime. [33:21](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2001s)
- **Turbo Stream broadcasts.** Part of Hotwire. The server renders HTML fragments and pushes them over a WebSocket to replace parts of an open page, so the page updates without polling or reloading. [33:45](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2025s)
- **Convention over configuration.** A Rails principle: sensible defaults for naming, structure and tools, so apps look alike and need little setup. [36:16](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=2176s)
- **Positive instructions.** Prompting guides, including Anthropic's, recommend telling a model what to do rather than what not to do, because naming the unwanted thing can pull it into the output. [51:59](https://www.youtube.com/watch?v=Be3S4-CyXQ0&t=3119s)

## Mentioned in the talk

- [HiFuMi](https://hifumi.dev): the Rails app generator, running in production.
- [hifumi-dev](https://github.com/pstrzalk/hifumi-dev): HiFuMi's source code, MIT licensed.
- [Visuality](https://www.visuality.pl): the Ruby on Rails company where Paweł is CTO.
- [Century Perspective](https://centuryperspective.com): the consultancy for AI transformation of Rails products that Paweł is a founding member of.
- [RubyLLM](https://rubyllm.com): the library behind HiFuMi's chat.
- [Roast](https://github.com/Shopify/roast): Shopify's Ruby library for AI workflows, which runs each revision.
- [Claude Code](https://code.claude.com/docs): Anthropic's coding agent, which writes the code.
- [OpenRouter](https://openrouter.ai): one API for many models, where HiFuMi gets Anthropic's.
- [Kamal](https://kamal-deploy.org): the deployment tool HiFuMi runs on.
- [Kamal Proxy](https://github.com/basecamp/kamal-proxy): the proxy that routes previews to their containers.
- [Tidewave](https://tidewave.ai): an AI coding toolkit for Rails and Phoenix that works in your browser, from the Q&A.
- [Playwright](https://playwright.dev): browser automation Paweł could use for screenshots.
- [bolt.new](https://bolt.new), [Lovable](https://lovable.dev) and [Replit](https://replit.com): the JavaScript app generators HiFuMi is compared with.
- [Rails World](https://rubyonrails.org/world): the conference in Austin this talk previewed.
- [Ruby Community Conference](https://rubycommunityconference.com): Visuality's conference, in Berlin on 12 March 2027.
