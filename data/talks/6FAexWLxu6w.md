## Chapters

- [0:00](https://www.youtube.com/watch?v=6FAexWLxu6w&t=0s) Who Carmine is, and why Ruby
- [2:22](https://www.youtube.com/watch?v=6FAexWLxu6w&t=142s) Why he built RubyLLM
- [3:13](https://www.youtube.com/watch?v=6FAexWLxu6w&t=193s) What 1.0 shipped, and what came after
- [5:32](https://www.youtube.com/watch?v=6FAexWLxu6w&t=332s) The Responses API problem
- [7:23](https://www.youtube.com/watch?v=6FAexWLxu6w&t=443s) Providers and protocols
- [9:31](https://www.youtube.com/watch?v=6FAexWLxu6w&t=571s) A forever API
- [11:19](https://www.youtube.com/watch?v=6FAexWLxu6w&t=679s) Citations and provider tools
- [13:38](https://www.youtube.com/watch?v=6FAexWLxu6w&t=818s) Caching across providers
- [15:22](https://www.youtube.com/watch?v=6FAexWLxu6w&t=922s) Thinking, compaction and new modalities
- [18:05](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1085s) Fallbacks, callbacks and workflows
- [20:15](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1215s) Approvals that survive restarts
- [22:07](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1327s) Driving the agentic loop yourself
- [24:00](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1440s) Cancellation
- [25:33](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1533s) Retries and the usage ledger
- [27:45](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1665s) A model registry for everyone
- [29:40](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1780s) Batches
- [31:22](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1882s) Fewer tables in Rails
- [33:32](https://www.youtube.com/watch?v=6FAexWLxu6w&t=2012s) Help for coding agents
- [36:24](https://www.youtube.com/watch?v=6FAexWLxu6w&t=2184s) Provider coverage, provider gems and RC1

## Summary

Carmine Paolino, the author of [RubyLLM](https://rubyllm.com) and one of Berlin.rb's organisers, explains why RubyLLM 2.0 works the way it does. He built RubyLLM for his own AI product, Chat with Work, because no Ruby library had the taste he wanted. 2.0 separates providers from protocols, so OpenAI's Responses API and Vertex AI's many protocols hide behind a model string, and cleans up the names into a "forever API". It exposes the agentic loop, which makes durable approvals, cancellation and batches possible, records every retry in a usage ledger, publishes a free model registry, and covers 395 of the 405 features its 17 providers offer. RC1 came out on the day of the talk.

### Why Ruby, and why RubyLLM [0:30](https://www.youtube.com/watch?v=6FAexWLxu6w&t=30s)

Ruby was Carmine's first programming love. He started programming at about five with batch scripts, but when he saw Ruby in 2009 it had a different culture: aesthetics, taste, and people who cared how code felt to read. He then went into AI and had to do everything in Python. In 2024, independent again, he chose Ruby for his AI SaaS, Chat with Work, because of Rails and its community. A small open-source app, Cluster Headache Tracker, showed him that fifteen years later Rails still felt familiar. Active Record still looked like Active Record. Those ideas lasted, he thinks, because they were well thought out from the beginning, and he wanted that feeling for his AI code too.

None of the LLM libraries he found had that taste, so he built one. The first commit was on 30 January 2025. Version 1.0 came out on 11 March 2025 and reached number one on Hacker News, and a library he had built for himself became one many people use. [2:22](https://www.youtube.com/watch?v=6FAexWLxu6w&t=142s)

### 1.0 and after [3:13](https://www.youtube.com/watch?v=6FAexWLxu6w&t=193s)

1.0 already shipped what Chat with Work, a retrieval-augmented generation app, needed: cost tracking, streaming, conversations, Rails persistence, Ruby tools, embeddings, image generation, PDFs and other inputs, a model registry with capabilities, limits and prices, and four providers (OpenAI, Anthropic, Gemini and DeepSeek). At its centre is `RubyLLM.chat`. You create a chat, ask a question and ask again, with no arrays of messages to manage. "This felt like Ruby to me." Later 1.x releases added concurrent tools on fibers or threads, structured output, extended thinking, moderation, isolated contexts for different API keys, audio transcription, an agent interface, chat UI generators and cost helpers.

### Providers and protocols [5:32](https://www.youtube.com/watch?v=6FAexWLxu6w&t=332s)

One problem kept coming back: OpenAI's Responses API. OpenAI introduced it alongside Chat Completions, the format most other providers had adopted, and some models were only available on one API while some features only worked on the other. Making the HTTP requests was easy. Keeping one consistent API across both was not. A separate "OpenAI Responses" provider works, and Chris Hasinski published one as a gem, but then a model string no longer tells RubyLLM which provider to use, and Carmine wanted a model string to be enough.

Vertex AI solved it. It started with the Gemini protocol and then added others. Unlike Bedrock, which mostly offers a single API, Vertex AI speaks each vendor's own protocol: Anthropic's for Claude, and Chat Completions with Mistral's quirks for Mistral. That is one provider with several protocols, and in 2.0 OpenAI works the same way. It uses the Responses API by default and Chat Completions where a model needs it, and RubyLLM picks for you. Switching from Gemini Flash on Vertex AI to Claude is still just a change of the model string. Getting there meant tearing apart much of the library to separate providers from protocols. [7:23](https://www.youtube.com/watch?v=6FAexWLxu6w&t=443s)

### A forever API [9:31](https://www.youtube.com/watch?v=6FAexWLxu6w&t=571s)

While he was at it, Carmine wanted 2.0 to be "the forever API": one you learn once and keep building with, the way Rails still felt like home fifteen years later. That meant undoing his own shortcuts. In 1.15, `desc` was a cute alias for `description`, next to `param`, `params` and `with_params`. In 2.0, `description` is `description`, `parameter` and `parameters` are spelled out, `with_params` became `with_provider_options`, and token counts get a proper tokens object. The principle is full names without contractions, so you can always work out what something is called.

### Features from real applications

#### Citations and provider tools [11:19](https://www.youtube.com/watch?v=6FAexWLxu6w&t=679s)

Chat with Work's users wanted to know where an answer came from. With `with_citations`, a response carries its sources, which Chat with Work shows next to each quote and as a list at the end. Every provider has its own format for this, and RubyLLM makes it look like Ruby. Providers also run tools on their own infrastructure, so 2.0 supports these server tools, such as web search, code execution and remote MCP servers (you give a name and a URL, and the provider calls it), under names that work with every provider that offers them. Research tasks can run remotely too, with `RubyLLM.research` starting a deep research job.

#### Caching [13:38](https://www.youtube.com/watch?v=6FAexWLxu6w&t=818s)

Anthropic needs a cache control marker inside the messages to set a cache point. In 1.x, Carmine wasn't sure that design would last, since no other provider worked that way, so instead of changing the message structure and adding Rails columns he added an escape hatch: raw content, written in whatever structure a provider wants. Then Bedrock added cache points too, and "this is where the power of having multiple providers comes from". In 2.0 you call `cache_until_here` on the message where the cache should end.

#### Thinking, compaction and more [15:22](https://www.youtube.com/watch?v=6FAexWLxu6w&t=922s)

Thinking controls now work across providers, and a parameter a provider doesn't support, such as effort, raises an error before anything is sent. Conversations can be compacted, and `chat.messages` can be replaced for those who manage messages themselves. New entry points cover OCR (Gemini Flash is good at it, but Mistral has models tuned for OCR that return Markdown), speech, uploads for larger attachments, richer transcription, reranking for RAG, and video generation. Embeddings now work on video and other files, tools can return attachments, and moderation works through Bedrock.

#### Fallbacks, callbacks and workflows [18:05](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1085s)

A model fallback looked like a simple try and catch, until recoverable failures and other cases showed it was more complicated, so it now lives in the framework. The fallback is saved in the chat, so it isn't lost when a chat is recovered. The `on_` callbacks are joined by before, after and around callbacks, which make more sense to Rails developers and compose: add three `after_fallback` callbacks and all three run. `RubyLLM::Agent` gets `rescue_from`. Workflows build on the instrumentation added in 1.16, with steps that make a whole workflow easier to observe.

### Durable agents

#### Approvals [20:15](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1215s)

Approvals were easy before 2.0, with some code in a tool's `execute` method. But a human can take a while. Does the background job sit and wait? What happens when it restarts? Does the UI show a second approval request, and how do you know the first one was ever shown? In 2.0, `requires_approval` on a tool stops the agentic loop, and it won't continue, even on `complete`, until someone calls `approve` or `deny`. The decision is saved, the job can be descheduled, and another process resumes the chat when the user has answered.

#### The agentic loop [22:07](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1327s)

Jobs that are descheduled, crash, or stop for a deploy led Carmine to the loop itself, and in 2.0 you can drive it yourself. You `step` until the chat is complete or needs an approval, and those two lines are the whole agentic loop. A step is either `generate`, which sends the chat to the model, or `run_tools`, which runs pending local tools. `complete` keeps going until nothing is left to do. Between steps you can change things, stop, and resume.

#### Cancellation [24:00](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1440s)

The stop button found in every LLM chat UI is now possible with RubyLLM. In Chat with Work, it calls `cancel` on the chat. The web process writes the request to the database, and the worker, which checks every second, raises a cancellation error when it sees it. RubyLLM then cleans up the chat, so no half-run tool calls or empty assistant messages are left behind.

### Knowing what you spend

#### Retries and the usage ledger [25:33](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1533s)

RubyLLM has always retried failed requests with Faraday Retry, three times per call by default, but the cost of those attempts went unrecorded. One answer could hide three paid attempts, which adds up in production with many clients, rate limits and other errors. 2.0 adds a usage ledger, a table RubyLLM manages, with the usage of every attempt. `chat.cost.total` works as before and now reads the ledger. The ledger stores the cost as well as the tokens. Before, cost was calculated from the latest model registry refresh, so a model that used to be more expensive was costed at today's price.

#### A model registry for everyone [27:45](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1665s)

Refreshing the model registry yourself needs API keys for all 17 providers. Now RubyLLM publishes a fresh registry every six hours at rubyllm.com/models.json, free for any library, framework or app. It is built from the providers' APIs, augmented with models.dev from Anomaly, the makers of OpenCode, plus RubyLLM's own overrides for fixes models.dev hasn't made yet. A searchable model browser is on the new website. And `refresh!` lost its bang: as in Rails, a bang method should only exist next to a version without one.

### Batches [29:40](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1780s)

With the loop exposed, batches were a nice surprise to implement. `ask_later` stages a question without calling the model, `RubyLLM.batch` submits the staged chats, and `batch.refresh` collects the answers. A batch reuses each chat's instructions, conversation and schema, so nothing has to be rebuilt in another data structure, and the Rails integration writes the results back to your tables. A batch is one model turn. If the model asks for Ruby tools, `run_tools` or `complete` runs them outside the batch.

### Fewer tables in Rails [31:22](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1882s)

Carmine thinks an app only needs its own tables for chats and messages, the parts people customise. Tool calls and the model registry don't need tables you manage, and the "model model" probably confused some people. Batches and the ledger would have added even more. In 2.0, RubyLLM manages every table except chats and messages, which means a substantial migration. It runs in several steps you can check one at a time, and a copy mode keeps the old tables and columns so you can go back to 1.16. It has been tested in Chat with Work and with clients Carmine is helping upgrade, and the upgrading guide covers it. "Trust me, it is worth it", because you won't have to manage those tables again.

### Help for coding agents [33:32](https://www.youtube.com/watch?v=6FAexWLxu6w&t=2012s)

Carmine uses coding agents to build RubyLLM, and many people use them to build with it or to send it pull requests and issues. He cares about code quality and architecture, and an agent, like a human, sometimes makes a change that isn't how he wants it. Rules in AGENTS.md or llms.txt help, but he thinks a static analyser is better, so he built ArchSpec, an executable specification for architectures in Ruby. You declare components and which may use which, or start from ready-made architectures such as vanilla Rails or CQRS. It uses Rubydex and Prism to find the relationships between constants, was at 1.1 at the time, and he used it throughout RubyLLM 2.0 and Chat with Work.

For coding agents, RubyLLM now also has a skill for building RubyLLM apps, an AGENTS.md, Copilot instructions (so he doesn't have to answer every issue himself, as many are duplicates), llms.txt and llms-full.txt, and public API docs in RDoc that agents can read with `ri`. He rebuilt the website with Jekyll VitePress, his own Jekyll theme with VitePress's look, "so we can keep building things in Ruby and make them look great".

### Every provider, every feature [36:24](https://www.youtube.com/watch?v=6FAexWLxu6w&t=2184s)

A table of about 40 features against 17 providers showed the gaps in 1.16: features that were missing, or only reachable through raw options. RubyLLM 2.0 supports 395 of the 405 features the providers offer. "It's a proper AI framework." For providers RubyLLM doesn't cover ("I'm still one guy"), a generator creates a provider gem with configuration, tests, CI, ArchSpec rules and a rake task that fills its models.json, which joins RubyLLM's own registry.

Since 1.16, three months earlier, that took 487 commits and 2,005 changed files, with 91 issues closed and 81 pull requests closed, 36 of them merged. Over the project's life, Carmine has closed 391 issues and 392 pull requests, and merged 168 of those pull requests. RubyLLM 2.0 RC1 came out on the day of the talk, and he thanked his gold sponsors, SerpApi and Missive. [38:25](https://www.youtube.com/watch?v=6FAexWLxu6w&t=2305s)

## Background

Short explanations of ideas the talk builds on, written by Berlin.rb.

- **Retrieval-augmented generation (RAG).** An app first searches its own documents for passages relevant to a question, then gives them to the model along with the question, so the answer can draw on and cite those sources. [3:24](https://www.youtube.com/watch?v=6FAexWLxu6w&t=204s)
- **Chat Completions and Responses.** OpenAI's two text APIs. Chat Completions takes the whole list of messages on every call, and many other providers copied its format. The newer Responses API, from 2025, adds built-in tools and can keep conversation state on OpenAI's side. [5:46](https://www.youtube.com/watch?v=6FAexWLxu6w&t=346s)
- **Prompt caching.** Providers can reuse the work done on the start of a prompt that repeats across calls, such as long instructions or documents, which makes those tokens cheaper and faster. Some providers cache automatically, others need explicit cache points. [13:38](https://www.youtube.com/watch?v=6FAexWLxu6w&t=818s)
- **Reranking.** A second step in search: after a fast search finds candidate documents, a reranking model scores each one against the question so the most relevant come first. [17:26](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1046s)
- **Durable execution.** Saving a process's state after each step, so it can stop (for a restart, a deploy or a human decision) and be resumed later, possibly by another process. [20:44](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1244s)
- **Batch APIs.** Providers accept many requests at once and process them asynchronously, typically within 24 hours, at a lower price than live calls. [29:40](https://www.youtube.com/watch?v=6FAexWLxu6w&t=1780s)
- **Prism.** Ruby's parser, the default since Ruby 3.4. Tools use it to read Ruby code as a syntax tree without running it. [35:09](https://www.youtube.com/watch?v=6FAexWLxu6w&t=2109s)

## Mentioned in the talk

- [RubyLLM](https://rubyllm.com): one Ruby API for every AI provider, by Carmine.
- [RubyLLM upgrading guide](https://rubyllm.com/upgrading/): how to migrate an app to 2.0.
- [Chat with Work](https://chatwithwork.com): Carmine's AI product, built with RubyLLM.
- [Cluster Headache Tracker](https://github.com/crmne/cluster-headache-tracker): the small open-source Rails app that brought Carmine back to Ruby.
- [ruby_llm-responses_api](https://github.com/khasinski/ruby_llm-responses_api): Chris Hasinski's OpenAI Responses provider for RubyLLM.
- [Vertex AI](https://cloud.google.com/vertex-ai): Google Cloud's AI platform, which serves several vendors' models.
- [Amazon Bedrock](https://aws.amazon.com/bedrock/): AWS's AI platform, which serves several vendors' models.
- [Faraday Retry](https://github.com/lostisland/faraday-retry): the middleware RubyLLM uses to retry requests.
- [models.json](https://rubyllm.com/models.json): RubyLLM's model registry, refreshed every six hours and free to use.
- [models.dev](https://models.dev): an open database of models, their capabilities and prices, from the makers of OpenCode.
- [ArchSpec](https://archspecrb.dev): Carmine's architecture linter for Ruby and Rails.
- [Rubydex](https://github.com/Shopify/rubydex) and [Prism](https://github.com/ruby/prism): the Ruby indexer and parser ArchSpec builds on.
- [Jekyll VitePress](https://github.com/crmne/jekyll-vitepress-theme): Carmine's Jekyll theme behind the RubyLLM website.
- [SerpApi](https://serpapi.com) and [Missive](https://missiveapp.com): RubyLLM's gold sponsors.
