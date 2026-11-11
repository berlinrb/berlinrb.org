## Chapters

- [0:00](https://www.youtube.com/watch?v=4xd7PalhrT8&t=0s) Six events this autumn, and a calmer view of AI
- [5:31](https://www.youtube.com/watch?v=4xd7PalhrT8&t=331s) Legacy Rails and the wall that moved
- [10:33](https://www.youtube.com/watch?v=4xd7PalhrT8&t=633s) Domain-driven design maps the business to the code
- [16:35](https://www.youtube.com/watch?v=4xd7PalhrT8&t=995s) Domains, process managers and read models
- [19:18](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1158s) The building blocks in Ruby
- [22:38](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1358s) A new operation at CHI Cargo, Frankfurt Airport
- [30:17](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1817s) Who still reads the code: the harness
- [32:43](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1963s) Architecture rules with ArchSpec
- [36:45](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2205s) Mutation testing with Mutant
- [38:02](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2282s) Refactoring at AI scale
- [39:41](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2381s) New roles: forward deployed and platform engineers
- [42:29](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2549s) Agents in remote VMs with Amp
- [44:40](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2680s) Learning to manage agents
- [47:42](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2862s) Residual architecture
- [51:46](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3106s) Takeaways and where to start
- [54:35](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3275s) Questions from the audience

## Summary

Andrzej Krzywda has run [Arkency](https://arkency.com), a consultancy for large legacy Rails applications, for almost twenty years. He argues that architecture still matters with AI, because agents don't deal well with unstructured codebases. Arkency models the business as domains that take commands and publish events, process managers that react to those events, and read models built from them, a vocabulary agents follow well. With it, CHI Cargo, a cargo handler at Frankfurt Airport, shipped a new repackaging operation in around two weeks. Because people will review less code, he relies on a harness: ArchSpec to enforce architecture rules and track known violations, and Mutant to prove test coverage, so agents can refactor large codebases safely.

### Six events, and a calmer view [0:21](https://www.youtube.com/watch?v=4xd7PalhrT8&t=21s)

Andrzej is a programmer, an architect and an entrepreneur, and this year he didn't know what to expect on any of those fronts. So over the last two months he went to six conferences and meetups, mostly in the Rails community, to talk to as many people as possible. He still doesn't know much, he says, but he feels calmer. Things are not as bad as the most pessimistic people claim, even if the job market is weak in some segments, and he expects strong growth in the economy and in innovation.

The moods differed. [EuRuKo](https://2026.euruko.org) in Brno felt more pessimistic, while an Omarchy meetup was upbeat about what you can build. Rails World shook his thinking the most. He calls DHH's talk there, about rewriting everything in Rust, a good wake-up call, with a side effect: the Ruby community started working on performance. With Spinel and Roundhouse, he expects Rails apps to run within the next year at a performance comparable to Rust. A .NET meetup in Wrocław turned out to be an AI meetup, which made him ask whether we will still need language meetups in five years. He thinks we probably will, because Ruby people share values and a mindset. A conference for IT entrepreneurs in Poland had the gloomiest mood, though the numbers it showed were not so bad.

### The wall has moved [5:31](https://www.youtube.com/watch?v=4xd7PalhrT8&t=331s)

Arkency has always focused on bigger, older Rails applications. Andrzej's message is that architecture still matters, because agents don't deal well with unstructured codebases. Arkency's own flavour combines domain-driven design, CQRS and events. They are not the only possible techniques, but they work for Arkency.

Rails projects used to hit a wall around their second or third year, when the codebase got so complex that new features slowed down, and that was when a CTO or CEO would call Arkency. AI moves the wall further out, but it also helps teams hit the new wall faster. Past it, even an agent adds a feature and breaks two existing ones. Codebases also grow much faster: a million-line Rails app used to be a client Arkency saw about once a year, and this year it sees codebases growing that big quickly.

AI makes developers faster, but not instant. Andrzej points out that programmers used to be the agents, prompted by managers and the C-level. Now there are faster agents, so developers need new roles. When he asked who still writes code by hand every day, nobody in the room did.

### Mapping the business into code [10:33](https://www.youtube.com/watch?v=4xd7PalhrT8&t=633s)

Andrzej believes domain-driven design prepared Arkency well for AI, because DDD was always about mapping the business to the code. If the code reflects the departments and processes of the business, requirements use the same language as the codebase and are easy to follow. Modern DDD is about domains and events. The classic book from 2004 had nothing about domain events, and now they are a big part of it.

A domain is roughly a department, such as sales, marketing, pricing or taxes, and becomes a Ruby module or namespace, ideally decoupled from the others. That is hard in Rails. Active Record and "don't repeat yourself" lead to a normalised database where every piece of information lives in one place, but in a business a client means something different to marketing, sales and invoicing. Reflecting the business in a Rails codebase is a big change that used to take years.

Each domain has an input and an output: commands go in, such as asking marketing to capture a lead or sales to sell a product to a customer, and events come out, such as "lead captured", "sale happened" and "invoice issued". Business processes connect the domains. The simplest one says that when marketing captures a lead, sales should try to convert it. A more complicated one might first check the CRM to see whether the lead was a client before. DDD used to create a shared vocabulary for programmers, the business and the code. Now agents work on the code too, and in Arkency's projects non-technical people push code, which Andrzej calls risky. The more structured the codebase, and the more rules the agents are taught, the less likely their changes are to break production.

#### Domains, process managers and read models [16:35](https://www.youtube.com/watch?v=4xd7PalhrT8&t=995s)

Put more formally: domains take commands and publish events. Process managers take events from different domains and, once a certain combination has happened, issue a command to a domain. Read models are where CQRS comes in. Splitting a system into reads and writes feels odd at first, but the business already does it: it asks for reports. A read model is built from events, such as a list of invoices, clients or sales, and the user looks at it to make a decision and click something, which is a new command.

Read models are the perfect place for Active Record, Andrzej says. They are about creating rows, deleting rows and changing columns, with no need for callbacks and little need for validations, since validation happens in the domains. The hard part for many is that the data is denormalised, with a table for each kind of report. Read models act as caches that solve invalidation by always invalidating: every new event produces a new version.

#### In Ruby [19:18](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1158s)

Andrzej shows the building blocks in code:

- **A simple process manager.** When a customer registers, it sends them a welcome message through the internal communication system. It takes the event store to react to events and the command bus to send commands.
- **A more complex process manager.** When an order goes unpaid, it expires and releases the payment. It declares the events it needs and the command it issues, using a process manager library from the Rails Event Store ecosystem. [19:47](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1187s)
- **A read model.** An internal inbox reacts to "communication message sent" and "communication message read" events, the latter switching a message from bold to normal, and writes an ordinary Active Record table. [20:28](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1228s)
- **An aggregate.** A line in an offer to a client, where adding or removing an item publishes "price item added" or "price item removed". [21:11](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1271s)

Commands and events combine like an algebra. Andrzej doesn't claim this is the only or best architecture, but agents handle it very well, because its vocabulary is concise English that the programmers, the business and the code share.

### A new operation at CHI Cargo [22:38](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1358s)

Arkency's client [CHI Cargo](https://chi-cargo.com) runs a cargo business at Frankfurt Airport, moving shipments from planes through its warehouse to trucks, and back. About three years ago it started a domain-driven transformation of its Rails application, then around ten years old, using Arkency's [Rails Event Store](https://railseventstore.org). Such transformations never reach a state where every department is cleanly separated, Andrzej says. They stay hybrid: events published from service objects, aggregates only where needed, read models that sometimes query other data.

Then came a new requirement: repackaging shipments, so that pieces of one shipment go onto different pallets, called load units, depending on whether they go to Hungary, France or Poland. Time was short, so programmers acted as product owners. Two of them went to the warehouse, because the warehouse workers are the real domain experts, not the people in the offices. [26:09](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1569s)

After those conversations, AI drew the change as a diagram of the familiar building blocks. The key was an existing event, "piece checked in", the most important event in the business, which means a piece has passed every airport procedure and is ready to go. The new operation ends in that same event, so every process that follows it keeps working. The agents wrote the code, because they have a skill for each building block. The architecture has also become a business framework: the business asks how things are done, and can ask the agent too. The feature shipped in around two weeks, which Andrzej says was "crazily impossible" before AI and before the transformation. [30:05](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1805s)

### The harness [30:17](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1817s)

Most of the room still reads the code before accepting a pull request. From his conversations, Andrzej expects that in some months fewer people will. Reviews are the bottleneck, and that can't last. The answer is this year's buzzword, the harness: tests, checks and guardrails that let an agent review a pull request.

The push for AI often comes from the C-level. When Arkency warns that less review means bugs in production, clients often answer that if the team is five times faster, they can accept some bugs, as long as one can be spotted and reverted within two hours. For developers it is binary, Andrzej says: it works or it doesn't. Many businesses think in thresholds, though not all of them.

#### Architecture rules with ArchSpec [32:43](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1963s)

ArchSpec, by Carmine Paolino, came up in Stephen Margheim's talk at the previous Berlin.rb. It lets you write architecture rules as code: module A never calls module B, a read model never calls a domain, a domain never calls a process manager directly. Shopify's Packwerk is a similar tool.

Both track technical debt. Add a rule and the tool accepts it but reports, say, 57 existing violations, which it stores in a file. CI then rejects any new violation while staying quiet about the known ones. Combined with an agent, this becomes a way to pay the debt down. Fix the first violation together with the agent in small steps, working out where the data should come from instead, then ask it to write a skill for this kind of fix. It will get the second one wrong, but after the third or fourth it does better, and if the skill explains the fix well, it can handle the remaining 53. [34:04](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2044s)

This needs very good test coverage, because without it the agents are blind. Andrzej thinks there was never a better time to aim for 100% coverage, because generating tests is now "instant and free". [36:06](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2166s)

#### Mutation testing with Mutant [36:45](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2205s)

Mutation testing is the only way to check whether coverage really is 100%. It tests the tests: it changes the code, for example a `+ 1` into a `+ 0`, runs the tests, and checks that one fails. It does this for every node in the syntax tree, finding every operator no test covers. Andrzej uses and recommends Mutant, which costs about $30 a month but has the largest number of mutations. ArchSpec and Mutant together are tools for fixing an existing codebase.

### Refactoring at AI scale [38:02](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2282s)

Everyone defines "software factory" differently. For Andrzej it is tooling and a harness that let an agent produce working code from an initial prompt or spec. More important to him is the other side: cleaning up the mess the agents create, which they still do, and the mess humans created before them. Refactoring is now possible at AI scale. Arkency's business was always improving legacy applications one careful step at a time, and that always took time. Now it is much faster, though not instant: cover a unit with tests, introduce ArchSpec, define the rules, and fix the violations.

### New roles [39:41](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2381s)

At Arkency's clients, non-technical or less technical people now push code, and Arkency's job is to let them ship. At the entrepreneurs' conference, people observed that C-level managers had never been as hands-on: they use agents themselves and are impatient, because they see what is possible.

Andrzej sees developers wearing two hats. The forward deployed engineer translates business pain into technology. They talk to people who just do their work, discover pains the business doesn't always see, and create features, like the programmers who went to the warehouse. This person is close to a consultant and can be non-technical. The platform engineer builds and improves the harness, cares about architecture and refactoring, introduces ArchSpec and Mutant, and keeps the platform working even while non-technical people push code. [40:53](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2453s)

### Agents in remote VMs [42:29](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2549s)

Andrzej presents the rest as newer trends he hasn't tested as thoroughly. His favourite agent harness is Amp, where every conversation in a repository runs in its own remote VM. He doesn't worry if an agent installs something bad, because there are no secrets on the VM to leak. Using it for three months has been the biggest shift in his work this year: he can start 20 or even 50 agents, setup costs nothing, and his laptop is no longer the limit. His prediction, which he says three months ago he would have rejected as "the local development guy", is that local development may not survive the next year or two. His laptop is now for presentations, the browser and talking to Amp.

#### Learning to manage agents [44:40](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2680s)

Developers are becoming architects, platform engineers and also managers of agents, though most never were managers. With agents you don't need to be diplomatic, but you do have to learn to tell others what to do. Andrzej borrows a technique for training new managers: shadowing. The new manager follows an experienced one into every meeting and call, then explains afterwards what happened. He shadowed people who work well with agents. At EuRuKo in Brno, Carmine Paolino, the creator of RubyLLM, showed him his setup for twenty minutes, and Andrzej learned more than in the six months before. [45:33](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2733s)

### Residual architecture [47:42](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2862s)

Architects also have to prepare for the unknown. Arkency's book club read Barry O'Reilly's [Residues](https://leanpub.com/residuality), which promotes residual architecture, an idea operating at a different level from DDD. You start with a basic architecture, Active Record or DDD, and come up with many stressors from outside: what could hit the system, what would happen, and which parts become attractors. The goal, hyperliminality, is to cover the possible scenarios, at least as an intellectual exercise in how you would fix each one.

The book's example is a network of electric vehicle charging stations, with stressors such as a car accident; stressors are often physical. For software, Andrzej asks: if it ever stops being safe to keep your website up, do you have one button to shut everything down, agreed with management, or will you run around in a panic in the middle of a Sunday night? A table of stressors against components shows which scenarios are most catastrophic, and which components fail together even when they aren't coupled in code, like a users microservice and a CRM. [50:15](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3015s)

Coming up with stressors is hard at first, but AI is very good at it, and programmers are good at risk analysis. The aim is to cover every type of problem, not every scenario. Even something unprecedented is useful, because it reveals a path through the system that more likely events could also take. Stressors also make good conversation points with the business.

### Takeaways [51:46](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3106s)

- Architecture still matters. Agents don't deal well with unstructured codebases.
- Learn DDD. It used to be hard to learn, and now you can ask an agent.
- More important than DDD itself: decide what your ideal architecture is, find the current violations with ArchSpec, cover the units with tests checked by Mutant, then move towards it. That is now faster, though not instant.
- Codebases will become more malleable. Probably every line of code will change.
- Take responsibility and be the architect now: know the business's pains, the possible architectural improvements, and the stressors.
- Study the [ecommerce](https://github.com/RailsEventStore/ecommerce) repository in the Rails Event Store organisation, or have your agent study it. It shows every building block, and includes the skills used to build it: one per building block, and others for upgrading Rails and Rails Event Store, adding a feature, and adding an app to what is a product line of several apps sharing similar domains. [53:32](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3212s)

### From the Q&A [54:35](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3275s)

- **For a new e-commerce app, why not stick to the Rails way of MVC, when AI can do whatever you want?** Look at the ecommerce repository, which has many answers. Most Rails apps have service objects, and what sits inside them, orchestrating Active Record, is where the domain logic lives. Cover a service object 100% with Mutant, then find which parts are really data retrieval and could become a read model, possibly with an agent's help. Simplify the service layer with rules such as service objects never calling each other. Service objects change state, like GraphQL mutations, while what GraphQL queries is basically a read model. Give each place where the UI displays data its own table, and keep it up to date either through events or by having the service object tell the read model to update itself. The service object then becomes the hybrid layer between the old Active Record way and the new one. [54:44](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3284s)
- **Why denormalise, rather than keep the database normalised behind repositories that serve each context?** That works, and Andrzej would use it in some hybrid approaches. Denormalising brings performance: a table per report removes joins, which are expensive. Big Rails apps often have reports so slow that they run once a day, so Arkency often starts not with domains but by extracting read models to fix performance. Repositories hide the tables conceptually, but the same joins happen underneath. The repository is a DDD concept and a step forward, but modern DDD with events separates things further. [58:15](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3495s)
- **Mutation testing is slow. Is your tool faster, and how do you handle it?** Mutation testing sounds simple but is very hard to implement well and fast. Arkency has used Mutant for eleven years, and Andrzej praises the optimisation work Markus Schirp has put into it; he discloses that he works with Markus on it. From a brief look at Mutineer, he noticed it has fewer possible mutations, so a 100% score means less. The big speed-up is incremental mode, which only mutates the code that changed: if a unit gained two short methods, that is about 1% of it, so a run can take below 1% of the time. The ecommerce repository runs Mutant in incremental mode in CI on every push, and a full run once a day, which is only really needed when adding libraries or upgrading Ruby. Small units help too: a process manager, a read model or a domain can each be mutation tested on its own, so changing one doesn't mean testing the others. Mutant is free for open source and paid for commercial use. [1:00:27](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3627s)
- **With denormalised data, how do you keep amounts consistent, for example in billing and taxes?** The source of truth stays in the domains, and the results of calculations go into events. Read models shouldn't calculate much; they display what a domain or process manager calculated. Events aren't denormalised: there is one event per fact in the business. Calculations like an order's total value happen in exactly one place, as in a process in the ecommerce repository. A technique called a summary event helps: an order summary builder listens to separate events about tax, order value and discounts, combines them, and publishes one event, "order value calculated". [1:05:27](https://www.youtube.com/watch?v=4xd7PalhrT8&t=3927s)
- **What should we keep in mind so an architecture stays expressive and others follow it?** Andrzej's style is not to create an architecture but to reflect the business's own, with the risk that a badly structured business leads to a badly structured codebase. Besides extracting read models for performance, you can start by reflecting the company's top-level processes as steps, which are events. Event storming helps: bring people from different departments, and programmers, to a wall with sticky notes and ask for events in the past tense, such as "new customer arrived". Anarchy at the start is fine; then help them structure it, and it shows where people use different names for the same concept. You can also ask an agent what DDD architecture fits an existing codebase, and it does quite a good job. Getting every programmer to follow the architecture is a human problem, which is why teams write skills and agree on one definition of their architecture. Good modularisation also keeps concurrent agents working in separate areas, so they don't change the same code at the same time. [1:07:55](https://www.youtube.com/watch?v=4xd7PalhrT8&t=4075s)

## Background

Short explanations of ideas the talk builds on, written by Berlin.rb.

- **Domain-driven design.** An approach to software design described by Eric Evans in his 2004 book Domain-Driven Design. The code is modelled on the business domain and uses the language of its experts, and a large system is split into bounded contexts, each with its own model, so a word like "customer" can mean different things in different parts. [10:33](https://www.youtube.com/watch?v=4xd7PalhrT8&t=633s)
- **Domain events.** A record that something meaningful happened in the business, named in the past tense, such as "invoice issued". Other parts of the system subscribe to events instead of calling each other, which keeps them decoupled. [11:08](https://www.youtube.com/watch?v=4xd7PalhrT8&t=668s)
- **CQRS.** Command Query Responsibility Segregation: separate models for changing data (commands) and for reading it (queries). The read side can then be shaped for each screen or report, at the cost of keeping it in sync with the write side. [17:01](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1021s)
- **Denormalisation.** Storing the same data in more than one place, shaped for a particular read, so queries need no joins. A normalised database avoids this duplication, which is simpler to keep consistent but slower for complex reports. [18:46](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1126s)
- **Process manager.** A component that coordinates a process spanning several parts of a system. It listens to messages, keeps track of where the process is, and sends commands to move it on. The pattern is described in the book Enterprise Integration Patterns. [16:35](https://www.youtube.com/watch?v=4xd7PalhrT8&t=995s)
- **Aggregate.** In DDD, a cluster of objects that is changed as a single unit and enforces its own business rules. In event-driven systems an aggregate records each change it makes as an event. [21:11](https://www.youtube.com/watch?v=4xd7PalhrT8&t=1271s)
- **Mutation testing.** A way to measure how good tests are. A tool makes small changes to the code, called mutants, and runs the tests against each one. A mutant that no test catches survives and points to a gap that line coverage alone wouldn't show. [36:48](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2208s)
- **Forward deployed engineer.** An engineer who works directly with a customer, often on site, to understand their problems and build solutions for them. The role was popularised by Palantir. [41:01](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2461s)
- **Residuality theory.** Barry O'Reilly's approach to software architecture. It stresses a simple design with many imagined stressors, looks at what is left of the system after each one, its residues, and changes the design until it copes with stressors nobody planned for. [47:42](https://www.youtube.com/watch?v=4xd7PalhrT8&t=2862s)
- **Event storming.** A workshop format created by Alberto Brandolini. Domain experts and developers write domain events on sticky notes, put them on a long wall, and arrange them into a timeline of how the business works. [1:10:47](https://www.youtube.com/watch?v=4xd7PalhrT8&t=4247s)

## Mentioned in the talk

- [Arkency](https://arkency.com): Andrzej's consultancy for large and legacy Rails applications.
- [Arkency blog](https://blog.arkency.com): where Arkency writes about DDD, events and Rails.
- [CHI Cargo](https://chi-cargo.com): the Frankfurt Airport cargo handler from Andrzej's case study.
- [Rails Event Store](https://railseventstore.org): Arkency's library for publishing and handling events in Rails apps, with process managers and read models.
- [ecommerce](https://github.com/RailsEventStore/ecommerce): the sample application with all the building blocks, the agent skills and the incremental Mutant setup.
- [ArchSpec](https://rubygems.org/gems/archspec): Carmine Paolino's static architecture linter for Ruby and Rails.
- [Packwerk](https://github.com/Shopify/packwerk): Shopify's tool for enforcing boundaries in Rails apps.
- [Mutant](https://github.com/mbj/mutant): Markus Schirp's mutation testing tool for Ruby, free for open source.
- [Mutineer](https://github.com/davidteren/mutineer): David Teren's mutation testing tool for Ruby, raised in the Q&A.
- [Amp](https://ampcode.com): the coding agent Andrzej uses, running each conversation in its own VM.
- [Residues](https://leanpub.com/residuality): Barry O'Reilly's book on residuality theory.
- [Spinel](https://github.com/matz/spinel): Matz's ahead-of-time compiler for Ruby.
- [Roundhouse](https://github.com/rubys/roundhouse): Sam Ruby's project that turns Rails apps into standalone code that can run on faster runtimes.
- [RubyLLM](https://rubyllm.com): Carmine Paolino's Ruby library for working with AI models.
- [The ZARchitecture](https://berlinrb.org/talks/stephen-margheim-the-zarchitecture-how-and-why-we-evolved-a-fintech-for-ai-driven-development/): Stephen Margheim's talk at Berlin.rb #2, where ArchSpec and mutation testing came up.
- [EuRuKo 2026](https://2026.euruko.org): the European Ruby conference, held in Brno this year.
- [Rails World](https://rubyonrails.org/world): the Rails Foundation's conference.
- [Omarchy](https://omarchy.org): DHH's opinionated Linux setup, whose meetup Andrzej attended.
- [AI Tinkerers](https://aitinkerers.org): meetups for people building with AI.
- [Callstack](https://www.callstack.com): a software company in Wrocław that Andrzej says invests heavily in AI.
