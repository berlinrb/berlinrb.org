## Chapters

- [0:00](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=0s) Welcome, and curiosity as a way to learn
- [1:09](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=69s) Going deep instead of high
- [1:57](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=117s) feelsneat, and the hype around Jev
- [3:50](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=230s) Who bought a computer for local AI?
- [4:55](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=295s) A runtime for decision models
- [6:05](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=365s) Demo: is this support message urgent?
- [7:12](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=432s) Scores for any set of labels
- [8:28](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=508s) How much memory, and why not an LLM?
- [9:58](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=598s) sayneat, a better say command
- [11:44](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=704s) Demo: Kokoro and Supertonic
- [14:34](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=874s) Cloning a voice from ten seconds
- [15:56](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=956s) Transcription, and coding during a meeting
- [17:25](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1045s) Why run these models locally
- [18:09](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1089s) looksneat, OCR beyond Apple Vision
- [20:40](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1240s) V-JEPA 2 and TRIBE v2 from Meta
- [23:03](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1383s) Demo: predicting actions from a webcam
- [24:01](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1441s) Demo: reading a night train ticket
- [26:27](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1587s) Where to find the tools
- [27:31](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1651s) Why canned fish
- [29:05](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1745s) Questions from the audience

## Summary

Lukas Rieder shows three small open-source runtimes he wrote to run open-weight models on his own Mac. feelsneat runs decision models that answer a question about a text with a probability, which he uses for routing and classification. sayneat extends the macOS `say` command with modern text-to-speech models, voice cloning from a ten-second clip, and transcription. looksneat does OCR that keeps a page's layout, tables and bounding boxes, and also runs two research models from Meta. His point: frontier models can't really run locally, but smaller models can do a lot, and following your curiosity is a good way to learn in the age of AI-assisted programming.

### Curiosity as a way in [0:35](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=35s)

People starting out in AI-assisted programming, especially younger ones, ask Lukas what they should learn. His answer is one approach among others: follow your curiosity, see where it leads, and maybe something comes of it. This talk is the result of that approach. Instead of going high, to large language models and everything fancy around them, he goes deep into smaller models, with three discoveries, all of them open source.

### feelsneat: decisions with a probability [1:57](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=117s)

For a while, Lukas's LinkedIn feed was all about Jev, TypeSafe's hosted model. System 1 thinking and decision models were all the rage, and he finds them interesting because they solve an old problem in a new, dynamic and generic way. They handle classification, labelling and judgment tasks, and they do it very fast. He signed up for the API, waited on the waiting list, and then realised he could download open models and run them on his own computer.

A show of hands found four people in the room, Lukas included, who had bought an expensive computer to run local AI. Most of them regretted it a little, and nobody said they benefit from it. Everyone, he says, got a bit disappointed by how little frontier model intelligence runs locally, but a lot of other things do. [3:50](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=230s)

feelsneat is a runtime he wrote that manages these System 1 models on Apple's MLX. It supports BERT-based models and typed decision models in several sizes. The simplest task, `noul`, takes a question and a context and returns the probability, between zero and one, that the answer is yes. Because the models are trained on large amounts of text, they understand what is being asked, and you can fine-tune them for a domain. [4:55](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=295s)

His demo plays a customer support app that needs to route messages. Asked "is this urgent?" about "payouts are failing for three days", the model returns a probability, and "help me now" with exclamation marks raises it. That's enough to build a routing algorithm. The usual alternative is a static classifier you retrain when your data changes. These models also score a dynamic set of labels, so you can classify or label things without retraining. Lukas runs feelsneat as a small local HTTP server for routing and classification, such as picking the best tool for a job, including in his own agent harness. [6:05](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=365s)

Two questions came from the room. The smaller models are small enough for a Raspberry Pi: the weights in the demo were under a gigabyte, and the BERT family is small in general. His machine is an M2 with 24 GB of RAM. And these models don't need an LLM, they are models of their own. You can ask an LLM the same question, but its answers are less deterministic, its output is text you have to force into JSON, and LLMs aren't good at giving probabilities. A decision model returns a probability based on the question, the context and its training. For this family of tasks, Lukas sees it as a replacement for an LLM. [8:28](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=508s)

### sayneat: a better say command [9:58](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=598s)

Lukas has used Macs for two decades and works in the terminal a lot. For a long-running task, he appends `; say done`, and the Mac tells him when it's finished, in a mechanical voice. With so much better synthetic voices around now, he wanted one on his Mac. sayneat is an open-source binary that keeps the `say` command's format and adds the latest models.

The room preferred sayneat's Kokoro voice to Apple's, though Lukas admitted it still doesn't sound great. Kokoro is small enough to run on a tiny CPU. His favourite for daily work is Supertonic, which is not much slower and sounds more human. Credit goes to the AI labs that make these models. He only wrote a runtime that downloads the weights and optimises them, sitting on the shoulders of giants. [11:44](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=704s)

#### Voice cloning [14:34](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=874s)

sayneat also supports Qwen3 and the ElevenLabs and OpenAI APIs. Qwen3 and other model families can clone a voice from a ten-second snippet, so sayneat clones voices too. Lukas played a clone of his own voice, which he uses for simple screen reading so he doesn't have to talk himself. He also asked the room not to use it to scam their neighbour's grandmother.

#### Transcription [15:56](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=956s)

sayneat works the other way too, as a speech-to-text tool, from the command line or as an HTTP server. It supports Whisper and Qwen3, which both give multi-speaker recognition and time codes. Lukas does the videos for the Berlin.rb community and others, and turns their audio tracks into transcripts for titles, descriptions and YouTube chapters. In client meetings, he feeds the live transcript into a local agent, which starts implementing what the client describes while the meeting is still going. The idea is that the software is basically done when the meeting is.

Why a separate runtime, when ElevenLabs and OpenAI exist? He likes to run these things locally. These models don't take much RAM, and transcription and voice cloning are sensitive, so he wants them on his own machine. [17:25](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1045s)

### looksneat: OCR that keeps the layout [18:09](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1089s)

After decisions and audio, the third tool is about vision. A recent project needed better OCR. Apple Vision is a nice SDK that works well for selecting a line of text, but it isn't the Swiss Army knife of OCR, and there are much better models. So he wrote another CLI and HTTP server for MLX, with Apple Vision, PP-OCRv6 and PaddleOCR as the main engines.

The PaddleOCR models detect the page layout, give text that follows the page, and are more accurate than Apple Vision. They also return bounding boxes, which matter to Lukas for provenance: when a human in the loop checks what was extracted, they can see which box of which document each piece of text came from, and grade it. [19:43](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1183s)

His example was a ticket from a night train home from Bratislava, a complex document full of tables. PaddleOCR extracted it with bounding boxes and tables, and his runtime turned a table into HTML. The HTML needs post-processing, but the layout is right: what belongs together in a column or a row stays together, which is a big advantage when you process complex documents. He keeps adding models as his work needs them, most recently Xiaomi's OCR-0. [24:01](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1441s)

#### Two research models from Meta [20:40](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1240s)

Lukas also added two models from Meta's AI research labs to his runtime, mostly to see what would happen. V-JEPA 2 is a vision model that predicts actions: less what is on the screen and more what is happening, like what a robot would see as someone carries something from left to right. TRIBE v2 maps the activations of the human brain to the model's input. As he understands it, the idea is to test content on a machine before it is shown to people. He called it questionable research and asked the room not to use it to make viral videos. Both have open weights, so he can run them in his vision pipeline.

In the demo, V-JEPA 2 watched him through the webcam, collected frames, and predicted what he was doing. It said "moving an object up" with 62% confidence, which was right, running on an M2 MacBook Air. [23:03](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1383s)

### Takeaways [26:27](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1587s)

- Follow your curiosity, and see where a small dive leads.
- Frontier models don't really run locally, but smaller models for decisions, speech and OCR do.
- For classification, a decision model gives you a probability, where an LLM gives you text.
- Keep sensitive work, such as transcripts and cloned voices, on your own machine.
- The three runtimes are on GitLab under Parlant, Lukas's company, and he writes about his discoveries on his blog. He invites anyone with an idea or a problem in this space to get in touch.

### Why canned fish [27:31](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1651s)

Asked to explain the canned fish, Lukas told the story of Matthew Carlson, a YouTuber in New York who makes videos about canned fish and music, and opens them with "What are we even doing here?" Lukas asks himself the same about the obscure dives he showed tonight. They work in this room, among us, and the canned fish reminds him to "stay on the weird side of things and just explore".

### From the Q&A [29:05](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1745s)

- **What about Apple's Siri voices?** An audience member who uses `say` a lot pointed out that Apple's default voice sounds like it's from 2001, because it is. In the settings you can download the Siri voices, about 400 MB, which were designed for phones with limited memory and power, are multilingual and sound good, and `say` can use them. Lukas didn't know, and might connect his runtime to them. [29:05](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1745s)
- **Have you tried Microsoft's neural voices?** Another audience member had Claude build a Swift app that uses the neural voices behind Microsoft Edge's read-aloud feature, through a CLI someone else made. They need no API key and are very fast. Lukas will check them out. [30:38](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1838s)
- **Did you know macOS ships with a built-in LLM?** A third audience member pointed out the small language model that comes with the Mac, and recommended MLX as an insanely powerful way to run models. [31:49](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1909s)

## Background

Short explanations of ideas the talk builds on, written by Berlin.rb.

- **System 1 and System 2.** Daniel Kahneman's names for two modes of thinking: fast, automatic judgment, and slow, deliberate reasoning. AI companies borrow the terms for small models that make quick decisions, as opposed to large models that reason step by step. [3:03](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=183s)
- **MLX.** Apple's open-source machine learning framework for Apple Silicon. CPU and GPU share the same memory on these chips, so a model's weights don't have to be copied between them. [4:57](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=297s)
- **BERT.** A family of encoder models, first published by Google in 2018. An encoder reads a whole text at once and turns it into numbers rather than generating new text, which makes it small and fast for classification. [5:18](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=318s)
- **Zero-shot classification.** Sorting text into labels a model was never trained on, by phrasing each label as part of the question. The labels can then change without retraining. [7:12](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=432s)
- **Voice cloning.** Modern text-to-speech models can take a short recording of a voice as a reference and speak new text in that voice. The same ability makes voice scams easier. [15:04](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=904s)
- **Layout analysis.** Classic OCR reads lines of text. Layout models first detect regions such as headings, paragraphs and tables, and the order to read them in, so the extracted text keeps the structure of the page. [19:54](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1194s)
- **JEPA.** Joint Embedding Predictive Architecture, an approach proposed by Yann LeCun at Meta. A model learns from video by predicting abstract representations of the parts it can't see, rather than every pixel. [21:17](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1277s)
- **Brain encoding models.** Models that predict how the brain responds to a stimulus, trained on fMRI recordings of people watching, listening or reading. TRIBE v2 predicts these responses to video, audio and text. [21:56](https://www.youtube.com/watch?v=uBVl-ArIMTc&t=1316s)

## Mentioned in the talk

- [feelsneat](https://gitlab.com/parlant-co/feelsneat): Lukas's runtime for System 1 decision models on Apple Silicon.
- [sayneat](https://gitlab.com/parlant-co/sayneat): Lukas's local text-to-speech, voice cloning and transcription tool.
- [looksneat](https://gitlab.com/parlant-co/looksneat): Lukas's local OCR and vision runtime.
- [Parlant](https://parlant.co): Lukas's company.
- [lukasrieder.com](https://lukasrieder.com): Lukas's blog.
- [Jev](https://docs.typesafe.ai): TypeSafe's hosted decision model, which got Lukas started.
- [MLX](https://github.com/ml-explore/mlx): Apple's machine learning framework for Apple Silicon.
- [Kokoro](https://github.com/hexgrad/kokoro): a small open-weight text-to-speech model.
- [Supertonic](https://github.com/supertone-inc/supertonic): a fast on-device text-to-speech model, Lukas's daily favourite.
- [Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS): Qwen's text-to-speech models, which can clone a voice.
- [Whisper](https://github.com/openai/whisper): OpenAI's open speech recognition model.
- [Qwen3-ASR](https://github.com/QwenLM/Qwen3-ASR): Qwen's speech recognition models.
- [ElevenLabs](https://elevenlabs.io): a hosted speech and voice cloning service.
- [Apple Vision](https://developer.apple.com/documentation/vision): Apple's framework for text recognition and other image analysis.
- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR): Baidu's open-source OCR toolkit, home of PP-OCRv6.
- [Xiaomi-OCR-0](https://huggingface.co/xiaomi-research/Xiaomi-OCR-0): Xiaomi's OCR model, recently added to looksneat.
- [V-JEPA 2](https://ai.meta.com/vjepa/): Meta's video model that understands and predicts actions.
- [TRIBE v2](https://github.com/facebookresearch/tribev2): Meta's model for predicting brain responses.
- [Canned Fish Files](https://www.youtube.com/@CannedFishFiles): Matthew Carlson's YouTube channel about canned fish.
- [Apple Foundation Models](https://developer.apple.com/documentation/foundationmodels): the framework for the on-device language model that ships with the Mac, raised in the Q&A.
