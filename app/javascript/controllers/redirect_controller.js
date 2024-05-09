import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    console.log(`RedirectController connected with url: ${this.element.dataset.url}`)
    Turbo.visit(this.element.dataset.url);
    this.element.remove();
  }
}
