import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = [ "source" ]

  connect() {
    let tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="copy-tooltip"]'))
    this.tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl, {trigger: 'click', container: 'body', delay: { "show": 0, "hide": 100 }})
    })
  }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)
    this.sourceTarget.select()
    setTimeout(() => {this.tooltipList.map(e => e.hide()) }, 3000)
  }
}