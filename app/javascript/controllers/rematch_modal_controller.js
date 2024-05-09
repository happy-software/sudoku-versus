import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {

  connect() {
    console.log("Connected to RematchModalController");
    document.body.classList.add("modal-open");
    this.element.setAttribute("style", "display: block");
    this.element.classList.add("show");
    if (document.getElementById("modal_backdrop") == undefined) {
      document.body.innerHTML += '<div id="modal_backdrop" class="modal-backdrop fade show"></div>';
    }
  }
}
