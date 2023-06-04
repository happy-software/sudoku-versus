import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js";
import party from "party-js";

export default class extends Controller {
  static targets = ['cell']

  connect() {
    let that = this;
    document.onkeydown = function (e) {
      // TODO: This can probably be broken up into methods on the CellController and delegated over using [Outlets](https://stimulus.hotwired.dev/reference/outlets)
      if (!['Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7', 'Digit8', 'Digit9', 'Backspace',
        'Numpad1', 'Numpad2', 'Numpad3', 'Numpad4', 'Numpad5', 'Numpad6', 'Numpad7', 'Numpad8', 'Numpad9'].includes(e.code)) {
        return;
      }
      let selectedCell = that.cellTargets.find(cell => cell.classList.contains("selected"))
      if (selectedCell === undefined) { return }
      if (selectedCell.classList.contains("prefilledCell")) { return }

      if (e.code === 'Backspace') {
        if(selectedCell.classList.contains("correctSelection")) { return }
        selectedCell.innerText = ""
        selectedCell.classList.remove("incorrectSelection")
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
    if (targetCell.nodeName !== "TD" && targetCell.nodeName === "SPAN") {
      // If the inner span is clicked then we want the parent <td> cell instead
      targetCell = targetCell.parentNode;
    }

    if ([...targetCell.classList].includes("selected")) {
      this.deselectCells();
      targetCell.classList.remove("selected")
      event.stopImmediatePropagation()
    } else {
      this.deselectCells()
      targetCell.classList.add("selected")
      this.highlightAlikeCells(event)
    }
  }

  deselectCells() {
    for (const cell of this.cellTargets) {
      cell.classList.remove("selected")
      cell.classList.remove("highlighted")
    }
  }

  highlightAlikeCells(event) {
    let targetCell = event.target;
    if (targetCell.nodeName !== "TD" && targetCell.nodeName === "SPAN") {
      // If the inner span is clicked then we want the parent <td> cell instead
      targetCell = targetCell.parentNode;
    }

    const selectedNumber = targetCell.innerText;
    if (selectedNumber === "") { return }
    let otherCells = this.cellTargets.filter((cell) => { return (cell.innerText === selectedNumber) && (cell !== targetCell) })
    otherCells.forEach((cell) => { cell.classList.add("highlighted") })
  }

  makeSelection(event) {
    // Get selected cell
    let selectedCell = this.cellTargets.find(cell => cell.classList.contains("selected"))
    if (selectedCell === undefined) { return }
    if (selectedCell.classList.contains("prefilledCell")) { return }
    if (selectedCell.classList.contains("correctSelection")) { return }

    const selectedNumber = event.target.innerText;
    const cellIndex = selectedCell.id;

    const request = this.isSelectionCorrect(selectedNumber, cellIndex)

    request.then((response) => {
      if (response.ok) {
        const bodyPromise = response.json
        bodyPromise.then((body) => {
          const is_correct   = body.is_correct
          const is_game_over = body.game_over

          if (is_correct) {
            selectedCell.classList.add("correctSelection")
            if (is_game_over) {
              party.confetti(selectedCell, {count: 200})
            }
          } else {
            selectedCell.classList.add("incorrectSelection")
          }
        })

      }
    })
    // Update it's value with the selection
    while (selectedCell.firstChild) {
      selectedCell.removeChild(selectedCell.lastChild);
    }
    const span = selectedCell.appendChild(document.createElement('span'))
    span.textContent = selectedNumber;

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

  async isSelectionCorrect(selectedNumber, cellIndex) {
    const requestData = {
      body: {
        game_id: document.getElementById("game-id").innerText,
        match_id: document.getElementById("match-id").innerText,
        selected_cell: cellIndex,
        selected_value: selectedNumber
      }
    }
    const request = new FetchRequest('post', 'http://localhost:3000/check_input', requestData)
    const response = await request.perform()
    return response
  }
}
