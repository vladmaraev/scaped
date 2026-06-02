// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
// import "phoenix_html";

// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "topbar";
// import { dmActor, startSpeechState } from "./dialogue";
import { metaToTailwind } from "./metaToTailwind";

import { setupApp, setupStartButton } from "lagoon_voices";

setupApp();
setupStartButton(document.querySelector<HTMLButtonElement>("#start")!);

let Hooks: { [index: string]: any } = {};
Hooks.SpeechState = {
  mounted() {
    // this.el.addEventListener(
    //   "click",
    //   () => {
    //     (window as any).dmActor.send({ type: "CLICK" });
    //   },
    //   false,
    // );
    // let dmActorMeta: string | undefined = "prepare";
    // dmActor.subscribe((state) => {
    //   console.debug(state.value);
    //   if (state.matches("Main")) {
    //     let metaSS: { view?: string } = Object.values(
    //       state.context.ssRef.getSnapshot().getMeta(),
    //     )[0] || { view: undefined };
    //     dmActorMeta = metaSS.view;
    //   } else {
    //     dmActorMeta = (Object.values(state.getMeta())[0] || {}).view;
    //   }
    //   console.debug(dmActorMeta);
    //   this.el.className = metaToTailwind(dmActorMeta);
    // });
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")!
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
// window.addEventListener("beforeunload", () => {
//   window.dispatchEvent(new CustomEvent("phx:page-loading-start"));
// });
// window.addEventListener("load", () => {
//   window.dispatchEvent(new CustomEvent("phx:page-loading-stop"));
// });

window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
// topbar.show(300);
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
liveSocket.enableDebug();
window.liveSocket = liveSocket;
// (window as any).dmActor = dmActor;
// (window as any).startSpeechState = startSpeechState;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      window.liveReloader = reloader;
    },
  );
}
