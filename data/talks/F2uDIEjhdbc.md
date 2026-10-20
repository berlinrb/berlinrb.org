## Chapters

- [0:00](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=0s) Who Rafał is, and software that can't adapt
- [1:51](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=111s) Why file imports keep breaking
- [4:54](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=294s) From a fixed pipeline to an agent
- [7:09](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=429s) An agent that writes its own code
- [8:51](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=531s) Demo: a cat management system
- [12:33](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=753s) Renamed columns and American dates
- [13:45](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=825s) Merged columns
- [15:57](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=957s) An Excel file
- [16:52](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1012s) A zip of CSV files
- [18:10](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1090s) A PDF of trading cards
- [20:22](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1222s) How the importer is built
- [22:19](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1339s) Breeds from an XML API
- [23:47](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1427s) Breeds from The Cat API's docs
- [25:47](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1547s) Matching cats to breeds
- [26:42](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1602s) Reports nobody built a feature for
- [29:00](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1740s) A pie chart, drawn by hand in SVG
- [31:12](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1872s) Key learnings from production
- [35:20](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=2120s) Questions from the audience

## Summary

Rafał Cymerys, CTO of [Upside](https://upsidelab.io), puts an AI agent inside an application and lets it write and run its own code. In his demo, a cat management system built with [RubyLLM](https://rubyllm.com), one import agent takes a CSV with renamed or merged columns, an Excel file, a zip of CSVs and a PDF of trading cards. It writes Ruby scripts to explore and convert each one, asking the user when unsure. The same pattern pulls breed data from APIs, matches it to the cats, and builds reports and charts on request. His lessons from production: pick widely used stacks, give agents generic tools, always sandbox the code, and test prompts with a pipeline instead of tuning them by hand.

### Software only does what we built it for [0:58](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=58s)

Rafał opens with Clippy, the assistant in Microsoft Word that could not help with anything outside its script, such as making every second paragraph blue. Real software has the same limit. Take Excel's CSV import. An application needs fixed data structures and validations to work and scale, so it can only accept what its developers thought of when they built it. The user, meanwhile, has data in whatever format another system gave them, and doesn't want to learn how the import works.

The usual answers are expensive. Teams spend months on matching screens with drag and drop and heuristics, a whole ETL industry sits between systems to move data from A to B, or users get a template to fill in, which works until someone fills it in their own way. The result is a support queue full of "my import doesn't work" in a consumer app, and Jira tasks for the important customer in an enterprise one.

### An agent that writes its own code [5:19](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=319s)

A traditional import parses the file, validates it, and throws an error if that fails. Some teams put an LLM behind the parser to match columns, but that is still limiting: every new format, such as a TSV or an older Excel file, is still a new story in the backlog.

Rafał's alternative is an agent (a model, memory and tools, looping until the job is done) with one more tool: it can write code, run it, and iterate on it. The code runs in a sandbox, something the agent can break, because neither what the AI generates nor what the user uploads can be trusted, and the upload can influence the AI. The agent and the sandbox exchange data through the file system, which he finds a simple concept that goes surprisingly far.

### The import demo [8:51](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=531s)

The demo app is a cat management system, the kind of cloud tool a vet practice might move to from a 1990s ERP whose exports are often incomplete or in odd formats. Its table holds each cat, its breed, its owner and their address, its favourite food and its last vet visit. One import agent handles every file:

- **A file that matches the template.** The agent looks up the target structure, peeks at the first bytes to check the file really is a CSV and not a zip with a CSV extension, and samples the data for statistics. Then it writes a script that maps the columns and converts the dates. [10:13](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=613s)
- **Renamed columns,** which is what users do to every template. It checked the headers, converted American dates and turned M and F into male and female. [12:33](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=753s)
- **Merged columns:** zip code and city inside the address, and the owner's full name in one column. From the statistics it worked out the address pattern and split both. It also counts the rows first: a billion rows can't go through an LLM, and for a two-line file a script isn't worth writing. [13:45](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=825s)
- **An Excel file.** It knew that an XLSX file is a zip archive with XML inside, unzipped it, and parsed it with an XML library available in the runtime. [15:57](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=957s)
- **A zip of 12 CSV files** of 10 rows each. Some of its scripts failed on files that didn't exist, and it fixed them as it went. [16:52](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1012s)
- **A PDF of Pokémon-style trading cards** made from the clinic's pets, with the last visit given as a relative date. This took longer. It found the pages, extracted the data, then asked which date the relative visits count from, offering the file's creation date. Rafał confirmed. [18:10](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1090s)

The demo ran on Claude Haiku 5.5, "a pretty dumb model" in Rafał's words, but one that handles these scripts well. A year earlier, he says, GPT-4.1 often couldn't write a script that ran the first time, so the agent needed many rounds of fixing its own code. Opus solved the PDF faster, in fewer iterations, so the right model depends on the problem.

### How the importer is built [20:22](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1222s)

The agent is built with RubyLLM. Its prompt says, in short: import this file, here is a way to look into it, write your own scripts and figure it out. All we want is a CSV that fits our schema exactly. It also tells the model that it can't run forever and should converge, rather than crunching through the whole file with LLM calls. The tools are:

- **Describe the target,** which returns the table's structure and constraints.
- **Peek at the file,** which dumps some bytes and helps the model tell a CSV from an Excel file or a zip.
- **Execute code.** In the demo this is "a poor man's sandbox", a subprocess with a limited environment. Rafał says that's not how you should run it, and you would normally hand this to a dedicated tool.
- **Ask the user,** which shows a yellow banner in the app when the agent is unsure.
- **Finish the import,** which hands the result back to the application.

### Beyond imports

The same pattern, an agent that must return tabular data of a known shape and can write code to get there, covers more of what the clinic needs.

#### Breeds from APIs [22:19](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1339s)

To check whether a cat is over- or underweight, the vet needs a catalogue of breeds with their origin and weight range, and the user tells the app where to get it. Given an XML API Rafał made up, the agent wrote code to fetch and parse it. Given only the docs page of [The Cat API](https://thecatapi.com), it downloaded the docs, found the endpoints and called them, then stopped because it needed an API key. Rafał pointed it to a demo key from the docs. It flagged that weights came in both metric and imperial units (he wanted kilograms) and that some breeds had no origin, a real flaw in that API's data, and asked how to handle them. It ended with 100 breeds. [23:47](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1427s)

#### Matching cats to breeds [25:47](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1547s)

Another agent matched the breed names in the cat data to the imported breeds. Most matched directly, but the API has no "Mixed Breed". The agent can't finish until every cat has a breed, so it asked, and Rafał told it to use Ragdoll. It finished with a summary of what it matched to what.

#### Reports and charts on request [26:42](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1602s)

Playing the user who wants a report but can't say exactly what, Rafał asked for the average number of kilograms that cats of each breed are over the breed's standard weight. The agent asked how to define standard weight, then returned the number of overweight cats in each breed and how many kilograms over they are on average. In his experience a reporting feature brings a flood of requests, because every user wants something different, and teams end up exporting everything to Power BI. Here the application writes the report itself.

Asked for a pie chart of the 10 zip codes with the most cats, the agent asked how to break a tie, exported the data, computed statistics, and drew the chart as SVG, calculating the slices itself. In Python it would reach for Matplotlib, but in Ruby it writes the chart by hand, which is good enough. Rafał's general point: reduce a problem to a coding problem, and let the coding model solve it at runtime, without having to think through every request users might make.

### Key learnings from production [31:12](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1872s)

- **The more Stack Overflow examples for the stack, the better.** For a charting feature, the agent struggled with a library specific to one industry, with sparse documentation. It couldn't build the aggregations, and Rafał found nobody online had described the problem either. Matplotlib, by contrast, is described all over the internet, so the model knows it well.
- **Give the agent generic tools, don't overfit.** Models are trained on simple tasks like writing scripts and using a file system. Letting the agent run its own `ls` gave better results than a custom tool for listing files.
- **You absolutely need a sandbox.** Models are getting better at detecting malicious intent, but even GPT-5 will happily follow an instruction smuggled into the input. Building the isolation yourself is not easy, but doable on Kubernetes, and Azure and AWS now offer building blocks for short-lived sessions with an interpreter.
- **Don't fine-tune prompts manually, build a pipeline.** Tweaking the prompt each time someone's CSV fails is a bad idea with a system that is non-deterministic and tied to one model, and models get deprecated. Collect the messy inputs users send, add synthetic data sets, and run them through a pipeline that gives you a metric, across models and data sets, now and as the industry moves.

### From the Q&A [35:20](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=2120s)

- **How do you keep the cost down, for example by caching the generated code?** When inputs repeat, as with a client's API in an ETL process, reuse the script from the first run and only fall back to the heavier pipeline when it hits errors. Beyond that, build a pipeline that tests real samples and optimise against it. The same task can be solved in many ways depending on the tools an agent gets, and adding a simple one, such as returning the first 10 rows of a file, can sharply cut how much code the agent has to write. [35:33](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=2133s)
- **Did you use RubyLLM's provider tools, which run the code on the provider's servers?** No, the demo runs the code in a subprocess. Provider sandboxes, like Anthropic's or Azure's container sessions, are useful for simple cases like this one, but with larger files or more complex scenarios he has hit their limits several times. [38:37](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=2317s)
- **Could the code run in the browser, with WebContainers?** That would be an option too. The more you can do on the client the better, though you then have to run the LLM calls on the client too, or find a clever way to pass them between the front end and the back end. He has used the WebAssembly build of DuckDB to query CSV and Parquet files in the browser and take load off the server, at the cost of users downloading the files first. [40:33](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=2433s)
- **Is the agent generic, or built for this one task?** There are five agents, partly to give the process a framework and partly to make it easier to show in pieces. One agent could import the cats, fetch the breeds and match them, with the tools combined and a broader goal. That would mostly change the user experience. [42:17](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=2537s)

## Background

Short explanations of ideas the talk builds on, written by Berlin.rb.

- **ETL.** Extract, transform, load: taking data out of one system, reshaping it to fit another's schema, and loading it there. Whole products exist to do this between business systems. [3:46](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=226s)
- **Agent loop.** An AI agent calls a language model over and over. The model can ask for a tool to be run, the application runs it and sends back the result, and the loop continues until the model says it is done. Libraries such as RubyLLM handle the loop and the tool definitions. [6:39](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=399s)
- **Sandboxing.** Running untrusted code in an isolated environment, with limited access to files, the network and secrets, and limits on time and memory. A wrong or malicious script can then only damage the sandbox, not the application around it. [7:50](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=470s)
- **XLSX files.** Since Office 2007, Excel saves workbooks in the Office Open XML format: a zip archive of XML files for the sheets, the shared strings and the styles. That's why a script can unzip one and read it with an ordinary XML parser. [16:10](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=970s)
- **Prompt injection.** An attack that hides instructions in content a model reads, such as an uploaded file, a web page or an API response. The model may follow them as if they came from the developer or the user, so code a model writes after reading untrusted input can't be trusted either. [32:39](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=1959s)
- **Evals.** A fixed set of inputs with known good results, run against a prompt, a model or a whole agent to score its output. Running them again after a change shows whether a new prompt or model made things better or worse. [33:58](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=2038s)
- **WebAssembly.** A portable binary format that browsers run at close to native speed. It lets software written for servers, such as the DuckDB database, run inside a web page. [41:31](https://www.youtube.com/watch?v=F2uDIEjhdbc&t=2491s)

## Mentioned in the talk

- [Upside](https://upsidelab.io): Rafał's engineering consultancy for healthcare and life science companies.
- [cymerys.com](https://cymerys.com): Rafał's site.
- [RubyLLM](https://rubyllm.com): the Ruby library the demo's agents are built with.
- [The Cat API](https://thecatapi.com): the cat breed API the demo imports from.
- [Anthropic's code execution tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool): a code sandbox run by the model provider, from Rafał's resources slide.
- [RubyLLM's provider tools](https://rubyllm.com/provider-tools/): tools such as code execution that run on the provider's servers, raised in the Q&A.
- [Azure Container Apps dynamic sessions](https://learn.microsoft.com/en-us/azure/container-apps/sessions): Azure's short-lived sandboxes for running code.
- [Matplotlib](https://matplotlib.org): the Python charting library models know well.
- [WebContainers](https://webcontainers.io): StackBlitz's runtime for running code in the browser, suggested in the Q&A.
- [DuckDB-Wasm](https://duckdb.org/docs/stable/clients/wasm/overview): DuckDB compiled to WebAssembly, so it runs in the browser.
