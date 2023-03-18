import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['cell']

  connect() {
    let that = this;
    document.onkeydown = function (e) {
      // TODO: This can probably be broken up into methods on the CellController and delegated over using [Outlets](https://stimulus.hotwired.dev/reference/outlets)
      if (!['Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7', 'Digit8', 'Digit9', 'Backspace'].includes(e.code)) {
        return;
      }
      let selectedCell = that.cellTargets.find(cell => cell.classList.contains("selected"))
      if (selectedCell === undefined) { return }
      if (selectedCell.classList.contains("prefilledCell")) { return }

      if (e.code === 'Backspace') {
        selectedCell.innerText = ""
        return;
      }

      // This feels hacky and there's probably a more native/correct way to do this
      // but I'm just trying to get it to work right now. I want to trigger the
      // button click event for the digit that was selected.
      document.getElementById(`select_${e.key}`).click()
    };
  }

  selectCell(event) {
    let targetCell = event.target;
    if ([...targetCell.classList].includes("selected")) {
      this.deselectCells();
      targetCell.classList.remove("selected")
      event.stopImmediatePropagation()
    } else {
      this.deselectCells()
      event.target.classList.add("selected")
    }
  }

  deselectCells() {
    for (const cell of this.cellTargets) {
      cell.classList.remove("selected")
      cell.classList.remove("highlighted")
    }
  }

  highlightAlikeCells(event) {
    const selectedNumber = event.target.innerText;
    if (selectedNumber === "") { return }
    let otherCells = this.cellTargets.filter((cell) => { return (cell.innerText === selectedNumber) && (cell !== event.target) })
    otherCells.forEach((cell) => { cell.classList.add("highlighted") })
  }

  makeSelection(event) {
    // Get selected cell
    let selectedCell = this.cellTargets.find(cell => cell.classList.contains("selected"))
    if (selectedCell === undefined) { return }

    // Update it's value with the selection
    while (selectedCell.firstChild) {
      selectedCell.removeChild(selectedCell.lastChild);
    }
    const span = selectedCell.appendChild(document.createElement('span'))
    span.textContent = event.target.innerText;

    this.deselectCells()
    this.highlightAlikeCells(event)
    selectedCell.classList.remove("highlighted")
    selectedCell.classList.add("selected")
  }

  startEditing() {
    let editRow = document.getElementById("editRow");
    let selectionRow = document.getElementById('selectionRow')
    editRow.hidden = false;
    selectionRow.hidden = true;
  }

  stopEditing() {
    let editRow = document.getElementById("editRow");
    let selectionRow = document.getElementById('selectionRow')
    editRow.hidden = true;
    selectionRow.hidden = false;
  }

}
