# SCAPED: Spoken Conversational AI Platform for Experiments on Dialogue
## To cite:
```bibtex
@inproceedings{maraev_scaped_2026,
	author = {Vladislav Maraev and Christine Howes and Catherine Pelachaud},
	title = {{SCAPED}: Spoken Conversational AI Platform for Experiments on Dialogue},
	year = {2026},
	isbn = {9798400723421},
	publisher = {Association for Computing Machinery},
	address = {New York, NY, USA},
	url = {https://doi.org/10.1145/3811427.3811508},
	doi = {10.1145/3811427.3811508},
	booktitle = {Proceedings of the 2026 International Conference on Advanced Visual Interfaces},
	articleno = {94},
	numpages = {3},
	keywords = {dialogue, experimental methods, spoken dialogue systems, conversational AI, crowdsourcing},
	location = {},
	series = {AVI '26}
}
```

## Integration with [SpeechState](https://speechstate.maraev.me/) projects
### Requirements
1. The project should be a JavaScript/TypeScript module. 
2. HTML code should be ejected into `<div id="app"></div>`

### Receive the condition and other attributes from the HTML:
```ts
const GET_ATTRIBUTES = () => ({
  session_id: parseInt(
    document.getElementById("app")!.getAttribute("data-session-id")!,
  ),
  signalling_id: document
    .getElementById("app")!
    .getAttribute("data-signalling-id")!,
  condition: document.getElementById("app")!.getAttribute("data-condition")!,
});
```

### Record conversation
1. Import `speechstate_webrtc_client`
```ts
import { setupRecorders } from "speechstate_webrtc_client";
```
2. Create an actor for setting up the recorders:
```ts
actors: {
      setupRecording: fromPromise(() => {
      return setupRecorders(GET_ATTRIBUTES().signalling_id);
    }),
}
```
3. Invoke the actor and save the Phoenix Socket and RTC Peer Connections in the context.
```ts
      invoke: {
        src: "setupRecording",
        input: null,
        onDone: {
          target: "Prepare",
          actions: assign(({ event }) => ({
            recordingPCs: event.output.pcs,
            recordingSockets: event.output.sockets,
          })),
        },
      },
```
4. To stop the recording, define and run this action:
```ts
    stop_recording: ({ context }) => {
      context.recordingSockets?.forEach((s) => {
        s.disconnect();
      });
      context.recordingPCs?.forEach((pc) =>
        pc.getSenders().forEach((sender) => sender.track?.stop()),
      );
    },
```

### Save transcript
- Promise actor:
```ts
    saveTranscript: fromPromise<
      any,
      {
        session_id: number;
        moves: OpenAI.Chat.Completions.ChatCompletionMessageParam[];
        step: number;
      }
    >(async ({ input }) => {
      const response = await fetch("session/savetranscript", {
        headers: {
          "Content-Type": "application/json",
        },
        method: "POST",
        body: JSON.stringify(input),
      });
      return response.json();
    })
```

- invoke this actor:
```
          invoke: {
            src: "saveTranscript",
            input: ({ context }) => ({
              session_id: GET_ATTRIBUTES().session_id,
              step: 0,
              moves: context.sessionHistory!,
            }),
            onDone: { target: "Next" },
          }
```
### Example:

[Lagoon Voices](https://github.com/vladmaraev/lagoon-voices/)
(credits: Joy Ciliani and Zofia Milczarek)


## To run locally (using Docker)
1. Copy `docker-compose.dev.yml` to `docker-compose.yml`
2. Generate a secret: `python3 -c 'import secrets; print(secrets.token_urlsafe(48)[:64])'`
3. In `docker-compose.yml`, add the following variables:
```yml
      SECRET_KEY_BASE: "<your secret>"
      GROQ_API_KEY: 
      AZURE_KEY:
      AZURE_CLU_KEY: 
      STUDY_ID: "<any string>"
```
4. Run docker compose:
```sh
docker compose up -d
```
5. Create the database:
```sh
docker compose run phx bin/migrate
```
6. Access your app (change `study_id` to a string from above): http://localhost:5011/?prolific_pid=test&session_id=test&study_id={study_id}




