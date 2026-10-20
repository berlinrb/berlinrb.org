## Chapters

- [0:00](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=0s) Who Stephen is, and why ZAR can't ship bugs
- [4:34](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=274s) Code is cheap, and that is why it matters
- [6:33](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=393s) The codebase is the prompt
- [9:00](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=540s) Abstractions give every session leverage
- [10:41](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=641s) The inhale and exhale rhythm
- [14:05](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=845s) Every change is a transaction
- [16:52](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1012s) Architecture: shape
- [20:52](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1252s) Architecture: vocabulary
- [27:48](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1668s) Architecture: types
- [29:48](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1788s) Architecture: enforcement with ArchSpec
- [35:37](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2137s) Testing the tests with mutation testing
- [41:13](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2473s) Two rewrites in production
- [44:59](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2699s) Software foremen, not software factories
- [46:28](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2788s) One place to query all your data
- [49:26](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2966s) Never outsource the understanding
- [51:34](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3094s) Takeaways
- [54:14](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3254s) Questions from the audience

## Summary

Stephen Margheim reads perhaps 5% of the code he ships to production at [ZAR](https://zar.app), a stablecoin neobank. He argues that the codebase steers AI agents more than any prompt does, so ZAR keeps one shape and one vocabulary everywhere, lands every change atomically like a database transaction, and lets machines enforce the rules: typed interfaces, architecture checks with ArchSpec in CI, and a test suite pruned with mutation testing until a green build means something. Stephen spends his own attention on the architecture and the database schema, and never outsources the understanding. Working this way, he rewrote ZAR's blockchain integration and its ledger without a single bug.

### The codebase is the prompt [6:33](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=393s)

Code is cheap now, and Stephen argues that this makes it matter more. For the first time, a better idea can win on its merits, because the cost of changing existing code no longer outweighs the improvement.

He gives two reasons why the codebase is the prompt. Most of the tokens in an agent session (he bets 70 to 80%) come from reading your code, not from your instructions. And models are trained above all to produce code, so they follow the patterns in your codebase over the wording of your prompt. Ask for elegant Ruby in a codebase full of spaghetti and you get more spaghetti. Quality compounds in both directions.

Abstractions matter for the same reason. A good abstraction is a decision no session has to make again. Without one, every session guesses, and parallel sessions guess differently. Four people handling third-party API errors on the same day leave four patterns behind, and the next session copies whichever one it finds.

### Inhale, exhale [10:41](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=641s)

The working rhythm Stephen describes, developed with his colleague Obie Fernandez, has two halves. On the inhale, let the agent explore the problem freely. On the exhale, fold what you learned back into abstractions and conventions, and apply them across the whole codebase in the same pull request.

He compares each breath to a database transaction. Changes should be atomic, because an abstraction introduced in one file but not the others leaves two ways of doing the same thing. The codebase should stay consistent at every moment: "Consistency is more valuable than correctness." Work stays isolated in its session until it can land in one pull request, and pushing it to the shared Git remote makes it durable. That way the roughly 50 sessions running across his team all start from the same state.

### Four layers of architecture [16:52](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1012s)

#### Shape [17:13](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1033s)

Stephen sees codebases as fractal. Functions combine into services, which take a schema and return success or failure. Services combine into subsystems, and subsystems into the app. Each layer has a defined interface, which makes the whole app easy to describe to every session.

#### Vocabulary [20:52](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1252s)

Rails won on convention over configuration. AI tools are the opposite: every developer's model, mode, skills and memory are slightly different, so shared conventions are worth more than ever. ZAR found three different HTTP status codes for the same provider exception, 16 ways of translating a provider failure, and 69% of services returning unchecked data. Its answer is REST everywhere, even inside the monolith where no HTTP is involved. There are seven fixed verbs, and you only get to invent nouns. A `Boundary` base class allows exactly those seven methods, so a violation stops the app from booting. For rules that need judgment, ZAR built Praxis, a linter that uses a model to check things like whether a service only returns success for the outcome its name promises.

#### Types [27:48](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1668s)

"A type is a convention that a machine can check." ZAR types the parameters of every resource in place of strong params, and types every value object, using [Literal](https://literal.fun), the runtime type library by Joel Drapper that Stephen co-maintains.

#### Enforcement [29:48](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1788s)

[ArchSpec](https://rubygems.org/gems/archspec) by Carmine Paolino checks the architecture in CI. Every subsystem is a closed box. The outside world can only call its resources and gets back values, which are frozen data objects, and only identifiers go in. Stephen prefers ArchSpec to Packwerk because it can express rules in both directions and is fast. ZAR adds its own Prism-based checks on top, and runs some subsystems' test suites without Rails or Postgres in the bundle, so code there cannot reach for the app's `User` model.

### Testing the tests [35:37](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2137s)

Stephen finds that AI mostly writes useless tests, which slow CI down and give false confidence. His fix is mutation testing with [Mutineer](https://github.com/davidteren/mutineer). The tool changes the source in small ways, such as turning `>` into `>=`, and checks that some test fails. He enforces two rules: every test must catch a bug, and it must catch it uniquely. He contributed a kill matrix to Mutineer that finds redundant tests.

With two agent sessions running mostly unattended, he rewrote ZAR's backend and mobile test suites. The backend went from 17,700 test examples to 8,170, with coverage up, CI time down, and real bugs found and fixed along the way.

### Two rewrites in production [41:13](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2473s)

Over the month before the talk, Stephen replaced all of ZAR's blockchain code and rolled it out over a week in about 30 deploys behind feature flags, without a single bug. He also rewrote the ledger: about 25 ways money moves and about 15,000 call sites, running in production at the time of the talk. He spent his own attention on the database schema (every table, column, index and trigger) and has not read the Ruby written on top of it.

### What comes next

#### Software foremen, not factories [44:59](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2699s)

Code generation is not the bottleneck. Invest in agents that watch every log and check every change against your guards.

#### One place for all your data [46:28](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2788s)

The signals for a safe rollout needed business data, telemetry, exceptions and app events from five systems. ZAR is building a data lake behind one MCP server with two tools: describe the schema, and run SQL.

#### Never outsource the understanding [49:26](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2966s)

Stephen doesn't care whether code uses `map` or `collect`, but he knows every module, what it is called and why it exists. Architecture, vocabulary and the data schema stay with the humans.

### Takeaways [51:34](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3094s)

- One shape and one vocabulary, applied everywhere.
- Consistency over correctness. Any decision can be fixed in one session, but a half-applied decision confuses every session after it.
- No TODO files and no half-finished migrations.
- Type the edges and refuse the drift.
- Use every guard available.
- Exhale after every inhale.

### From the Q&A [54:14](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3254s)

- **What does ZAR use instead of SQLite?** Postgres. [54:25](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3265s)
- **What does the exhale look like in practice?** When a session finds a better way to map errors from a provider's API, apply it everywhere those errors are mapped, in the same change. Don't add a sixteenth variant and ask the team to copy the new one. [54:33](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3273s)
- **Doesn't fixing everything at once turn into yak shaving?** "Yes, except no." Hand the cleanup to sub-agents and do it now, because every session that runs on a messy codebase makes it messier. A codebase that starts out messy needs a cleanup phase first. [57:09](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3429s)
- **How does a team avoid stepping on each other?** ZAR splits work along functional boundaries. For changes that cut across them, such as moving to a new pattern for runtime adjustable constants, one person announces it, lands a short-lived pull request and asks for a quick review. "Long-lived pull requests are death." [1:00:32](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3632s)
- **Does mutation testing run in CI?** Yes, on every push. A new test that doesn't catch a bug uniquely fails CI, and the pull request can't be merged. [1:04:01](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=3841s)

## Background

Short explanations of ideas the talk builds on, written by Berlin.rb.

- **ACID transactions.** The four guarantees a database gives a transaction: atomicity (all of it happens or none of it), consistency (it leaves the data valid), isolation (concurrent transactions don't see each other's unfinished work) and durability (once committed, it survives a crash). Stephen applies the same four ideas to code changes. [14:05](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=845s)
- **Modular monolith.** A single deployable application split into modules with enforced boundaries, so modules depend on each other only through declared interfaces. It aims for the separation of microservices without network calls between them. [23:38](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1418s)
- **Seven RESTful actions.** In Rails, a resource has seven standard actions: index, show, new, create, edit, update and destroy. Sticking to a fixed set of verbs means new behaviour becomes a new resource (a noun) instead of a new custom action. [23:48](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1428s)
- **Result objects.** A service returns an explicit success or failure value instead of raising an exception for expected outcomes. This is often called a Result or Either monad. Callers handle both cases on purpose, and exceptions are left for real errors. [26:31](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1591s)
- **Runtime type checking.** Checking types while the program runs, for example when an object is created. Static checkers analyse code without running it, while runtime libraries such as Literal check each value as it is assigned and fail right away. [28:12](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=1692s)
- **Mutation testing.** A way to measure how good tests are. A tool makes small changes to the code, called mutants, and runs the tests against each one. A mutant that no test catches survives and points to a gap. A kill matrix records which tests catch which mutants, which also reveals tests that only catch what others already catch. [36:16](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2176s)
- **MCP.** The [Model Context Protocol](https://modelcontextprotocol.io) is an open standard for connecting AI agents to tools and data. An MCP server offers tools, such as running a SQL query, that any compatible agent can call. [48:02](https://www.youtube.com/watch?v=OmrdvAzCSIc&t=2882s)

## Mentioned in the talk

- [ZAR](https://zar.app): the stablecoin neobank where Stephen leads product engineering.
- [fractaledmind.com](https://fractaledmind.com): Stephen's site and blog.
- [ArchSpec](https://rubygems.org/gems/archspec): Carmine Paolino's static architecture linter for Ruby and Rails.
- [Mutineer](https://github.com/davidteren/mutineer): David Teren's mutation testing tool for Ruby.
- [Literal](https://literal.fun): Joel Drapper's runtime type library for Ruby.
- [Packwerk](https://github.com/Shopify/packwerk): Shopify's tool for enforcing boundaries in Rails apps.
- [ClickStack](https://clickhouse.com/docs/use-cases/observability/clickstack): the ClickHouse observability stack behind ZAR's data lake.
- [DuckDB](https://duckdb.org): the alternative Stephen names for querying across data sources.
