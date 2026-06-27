import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"
import { post } from "@rails/request.js"

export default class extends Controller {
  static targets = [ "source" ]
  static values = { matchKey: String }

  connect() {
    let tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="copy-tooltip"]'))
    this.tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl, {trigger: 'click', container: 'body', delay: { "show": 0, "hide": 100 }})
    })

    // Catch manual copies (Ctrl+C, right-click → Copy) on the link itself, not
    // just clicks of our button, so we know if the challenge link was copied
    // in any way at all.
    if (this.hasSourceTarget) {
      this.onNativeCopy = () => this.track("challenge_link_copied")
      this.sourceTarget.addEventListener("copy", this.onNativeCopy)
    }
  }

  disconnect() {
    if (this.hasSourceTarget && this.onNativeCopy) {
      this.sourceTarget.removeEventListener("copy", this.onNativeCopy)
    }
  }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)
    this.sourceTarget.select()
    setTimeout(() => {this.tooltipList.map(e => e.hide()) }, 3000)
    this.track("copy_button_clicked")
    this.track("challenge_link_copied")
  }

  // Records a client-side event server-side via /et so it lands in Ahoy
  // alongside our page-view events. The path is terse so adblockers don't
  // block it. Fire-and-forget: tracking must never block or break the copy UX.
  track(name) {
    post("/et", { body: { name: name, match_key: this.matchKeyValue } }).catch(() => {})
  }
}
