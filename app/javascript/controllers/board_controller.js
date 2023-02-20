import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['cell']

  connect() {
    document.onkeydown = function (e) {
      console.log(`KeyboardEvent: key='${e.key}' | code='${e.code}'`)
      if (!['Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7', 'Digit8', 'Digit9', 'Backspace'].includes(e.code)) {
        return;
      }

      if (e.code === 'Backspace') {
        let selectedCell = this.cellTargets.find(cell => cell.classList.contains("selected"))
        selectedCell.innerText = "";
      }

      // This feels hacky and there's probably a more native/correct way to do this
      // but I'm just trying to get it to work right now. I want to trigger the
      // button click event for the digit that was selected.
      document.getElementById(`select_${e.key}`).click()
    };
  }

  selectCell(event) {
    event.target.classList.add("selected")
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
    console.log(`Clicked number: ${event.target.innerText}`)
    while (selectedCell.firstChild) {
      selectedCell.removeChild(selectedCell.lastChild);
    }
    const span = selectedCell.appendChild(document.createElement('span'))
    span.textContent = 'hello world';

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
