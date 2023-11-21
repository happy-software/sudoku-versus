import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js";

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
        that.clearCell(selectedCell)
        return;
      }

      // This feels hacky and there's probably a more native/correct way to do this
      // but I'm just trying to get it to work right now. I want to trigger the
      // button click event for the digit that was selected.
      document.getElementById(`select_${e.key}`).click()
    };
    this.disableCompletedNumberSelection();

    console.log(`Connected to BoardController with input checker as ${window.input_checker_url}`)
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
    if (event.target.classList.contains("disabled")) { return } // Do nothing for keyboard users for completed numbers

    const selectedNumber = event.target.innerText;
    const cellIndex = selectedCell.id;

    const request = this.isSelectionCorrect(selectedNumber, cellIndex)

    request.then((response) => {
      if (response.ok) {
        const bodyPromise = response.json
        bodyPromise.then((body) => {
          const is_correct        = body.is_correct
          const is_game_over      = body.game_over
          const remaining_numbers = Array.from(body.remaining_numbers)

          if (is_correct) {
            selectedCell.classList.remove("incorrectSelection")
            selectedCell.classList.add("correctSelection")
            if (!remaining_numbers.includes(parseInt(selectedNumber))) {
              // Hide the number from selection options since
              // it is no longer a remaining number (i.e. it has been
              // completed).
              this.markSelectionNumberDisabled(selectedNumber)
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

  clearButtonClick(event) {
    let selectedCell = this.cellTargets.find(cell => cell.classList.contains("selected"))
    this.clearCell(selectedCell)
  }

  clearCell(selectedCell) {
    if (selectedCell.classList.contains("prefilledCell"))    { return }
    if (selectedCell.classList.contains("correctSelection")) { return }

    selectedCell.innerText = ""
    selectedCell.classList.remove("incorrectSelection")
  }

  startEditing() {
    // TODO: Need to get this working at some point
    let editRow = document.getElementById("editRow");
    let selectionRow = document.getElementById('selectionRow')
    editRow.hidden = false;
    selectionRow.hidden = true;
  }

  stopEditing() {
    // TODO: Need to get this working at some point
    let editRow = document.getElementById("editRow");
    let selectionRow = document.getElementById('selectionRow')
    editRow.hidden = true;
    selectionRow.hidden = false;
  }

  disableCompletedNumberSelection() {
    // Get all the prefilled cells
    let prefilled = document.getElementsByClassName('prefilledCell')

    // Of the prefilled cells, find the numbers that have all 9 already filled
    let available_numbers = []
    for(let i = 0; i < prefilled.length; i++) {
      let cell = prefilled.item(i)
      available_numbers.push(cell.dataset.boardPrefilledValue)
    }
    const number_counts = available_numbers.reduce((acc, e) => acc.set(e, (acc.get(e) || 0) + 1), new Map());

    let filled_numbers = []
    for(let pair of number_counts) { if(pair[1] === 9) { filled_numbers.push(pair[0])} }

    // Of the already filled numbers, disable the selection button for it
    for(let number of filled_numbers) { this.markSelectionNumberDisabled(number) }
  }

  markSelectionNumberDisabled(selectedNumber) {
    document.getElementById(`select_${selectedNumber}`).classList.remove('btn-primary')
    document.getElementById(`select_${selectedNumber}`).classList.add('btn')
    document.getElementById(`select_${selectedNumber}`).classList.add('btn-outline-secondary')
    document.getElementById(`select_${selectedNumber}`).classList.add('disabled')
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

    let url        = window.input_checker_url // Set in layouts/application.slim
    const request  = new FetchRequest('post', url, requestData)
    const response = await request.perform()

    return response
  }
}
