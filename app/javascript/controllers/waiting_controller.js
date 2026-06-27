import { Controller } from "@hotwired/stimulus"

// Tracks when player 1 leaves the "waiting for challenger" screen before an
// opponent ever joins — our clearest signal for the "created then abandoned"
// matches we're trying to understand.
//
// When an opponent DOES join, the container is replaced in place via Turbo
// Stream and disconnect() fires (the page stays alive), so the listener is torn
// down and no abandonment is recorded. We deliberately use `pagehide` rather
// than `visibilitychange`: switching tabs (e.g. to paste the link into a chat
// app) is the opposite of abandoning, and only `pagehide` fires on real unload.
export default class extends Controller {
  static values = { matchKey: String }

  connect() {
    this.reported = false
    this.onPageHide = () => this.reportAbandoned()
    window.addEventListener("pagehide", this.onPageHide)
  }

  disconnect() {
    window.removeEventListener("pagehide", this.onPageHide)
  }

  reportAbandoned() {
    if (this.reported) return
    this.reported = true

    const data = new URLSearchParams({
      name: "waiting_abandoned",
      match_key: this.matchKeyValue,
    })

    // sendBeacon is built for unload-time requests; fall back to keepalive
    // fetch on the rare browser without it.
    if (navigator.sendBeacon) {
      navigator.sendBeacon("/et", data)
    } else {
      fetch("/et", { method: "POST", body: data, keepalive: true }).catch(() => {})
    }
  }
}
