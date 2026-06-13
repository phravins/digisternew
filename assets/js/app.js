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
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/digister"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// Real-time clock for #sa-datetime
const MONTHS = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

function updateClock() {
  const el = document.getElementById("sa-datetime")
  if (!el) return
  const now = new Date()
  const day = String(now.getDate()).padStart(2, "0")
  const month = MONTHS[now.getMonth()]
  const year = now.getFullYear()
  let hours = now.getHours()
  const ampm = hours >= 12 ? "PM" : "AM"
  hours = hours % 12 || 12
  const mins = String(now.getMinutes()).padStart(2, "0")
  el.textContent = `${day} ${month} ${year} · ${hours}:${mins} ${ampm}`
}

function startClock() {
  updateClock()
  // Sync to the start of the next minute for accuracy
  const msUntilNextMinute = (60 - new Date().getSeconds()) * 1000 - new Date().getMilliseconds()
  setTimeout(() => {
    updateClock()
    setInterval(updateClock, 60000)
  }, msUntilNextMinute)
}

startClock()
// Re-run after LiveView navigations that re-mount the layout
window.addEventListener("phx:page-loading-stop", startClock)

// Auto-dismiss toast notifications after 4 seconds
function autoDismissFlash() {
  document.querySelectorAll('[role="alert"]:not([data-permanent])').forEach(el => {
    if (el.dataset.autoDismiss) return
    el.dataset.autoDismiss = "true"
    setTimeout(() => {
      el.style.transition = "opacity 0.4s ease, transform 0.4s ease"
      el.style.opacity = "0"
      el.style.transform = "translateX(20px)"
      setTimeout(() => el.remove(), 400)
    }, 4000)
  })
}

autoDismissFlash()
window.addEventListener("phx:page-loading-stop", autoDismissFlash)
// Also catch flash added mid-page without navigation (e.g. form saves)
window.addEventListener("phx:update", autoDismissFlash)

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

