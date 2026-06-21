import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js";

export default class extends Controller {
  static targets = ['cell', 'editToggle']

  connect() {
    // When true, number presses write pencil-mark candidates into the
    // selected cell instead of committing a scored answer.
    this.editMode = false;

    let that = this;
    document.onkeydown = function (e) {
      // TODO: This can probably be broken up into methods on the CellController and delegated over using [Outlets](https://stimulus.hotwired.dev/reference/outlets)
      if (!['Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7', 'Digit8', 'Digit9', 'Backspace',
        'Numpad1', 'Numpad2', 'Numpad3', 'Numpad4', 'Numpad5', 'Numpad6', 'Numpad7', 'Numpad8', 'Numpad9'].includes(e.code)) {
        return;
      }
      let selectedCell = that.selectedCell()
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
    this.updateEditToggle();
  }

  selectCell(event) {
    let targetCell = this.cellFromEvent(event)
    if (targetCell === null) { return }

    if (targetCell.classList.contains("selected")) {
      this.deselectCells()
      event.stopImmediatePropagation()
    } else {
      this.deselectCells()
      targetCell.classList.add("selected")
      this.highlightAlikeCells(targetCell)
    }
  }

  deselectCells() {
    for (const cell of this.cellTargets) {
      cell.classList.remove("selected")
      cell.classList.remove("highlighted")
    }
  }

  // Highlights every cell that shares the given cell's number, whether that
  // number is committed as a value or is just penciled in as a candidate.
  highlightAlikeCells(sourceCell) {
    const selectedNumber = this.getCellValue(sourceCell);
    if (selectedNumber === "") { return }
    this.highlightNumber(selectedNumber, sourceCell)
  }

  highlightNumber(number, sourceCell) {
    const wanted = String(number)
    this.cellTargets.forEach((cell) => {
      if (cell === sourceCell) { return }
      if (this.getCellValue(cell) === wanted || this.getCandidates(cell).includes(wanted)) {
        cell.classList.add("highlighted")
      }
    })
  }

  makeSelection(event) {
    // Get selected cell
    let selectedCell = this.selectedCell()
    if (selectedCell === undefined) { return }
    if (selectedCell.classList.contains("prefilledCell")) { return }
    if (selectedCell.classList.contains("correctSelection")) { return }
    if (event.target.classList.contains("disabled")) { return } // Do nothing for keyboard users for completed numbers

    const selectedNumber = event.target.innerText.trim();

    // In edit mode we just toggle a candidate. This never touches the server
    // so it can't count for or against the player's score.
    if (this.editMode) {
      this.toggleCandidate(selectedCell, selectedNumber)
      this.refreshHighlight(selectedCell, selectedNumber)
      return;
    }

    const cellIndex = selectedCell.id;

    const request = this.isSelectionCorrect(selectedNumber, cellIndex)

    request.then((response) => {
      if (response.ok) {
        const bodyPromise = response.json
        bodyPromise.then((body) => {
          const is_correct        = body.is_correct
          const is_game_over      = body.game_over

          if (is_game_over) {
            // Do Nothing
          }
          else if (is_correct) {
            const remaining_numbers = Array.from(body.remaining_numbers)
            selectedCell.classList.remove("incorrectSelection")
            selectedCell.classList.add("correctSelection")
            // A confirmed answer rules this number out of every peer cell, so
            // tidy up any now-impossible pencil marks in the same row, column,
            // and box.
            this.removeCandidateFromPeers(selectedCell, selectedNumber)
            if (selectedCell.classList.contains("selected")) {
              this.refreshHighlight(selectedCell, selectedNumber)
            }
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
    this.setCellValue(selectedCell, selectedNumber)

    this.deselectCells()
    this.highlightNumber(selectedNumber, selectedCell)
    selectedCell.classList.remove("highlighted")
    selectedCell.classList.add("selected")
  }

  clearButtonClick(event) {
    let selectedCell = this.selectedCell()
    this.clearCell(selectedCell)
  }

  clearCell(selectedCell) {
    if (selectedCell === undefined || selectedCell === null) { return }
    if (selectedCell.classList.contains("prefilledCell"))    { return }
    if (selectedCell.classList.contains("correctSelection")) { return }

    if (selectedCell.classList.contains("hasValue")) {
      // The cell holds a (necessarily incorrect) committed value: clear it
      // and let any candidates that were underneath it show through again.
      this.clearCellValue(selectedCell)
    } else {
      // Otherwise just wipe the pencil marks.
      this.clearCandidates(selectedCell)
    }

    this.cellTargets.forEach((cell) => cell.classList.remove("highlighted"))
  }

  toggleEditMode() {
    this.editMode = !this.editMode
    this.updateEditToggle()
  }

  updateEditToggle() {
    if (!this.hasEditToggleTarget) { return }
    const btn   = this.editToggleTarget
    const label = btn.querySelector(".editModeLabel")
    if (this.editMode) {
      btn.classList.remove("btn-outline-secondary")
      btn.classList.add("btn-warning", "active")
      if (label) { label.textContent = "Notes: On" }
    } else {
      btn.classList.remove("btn-warning", "active")
      btn.classList.add("btn-outline-secondary")
      if (label) { label.textContent = "Notes: Off" }
    }
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

  // --- Cell value / candidate helpers ---------------------------------------

  selectedCell() {
    return this.cellTargets.find(cell => cell.classList.contains("selected"))
  }

  cellFromEvent(event) {
    return event.target.closest('[data-board-target="cell"]')
  }

  getCellValue(cell) {
    const span = cell.querySelector(".cellValue")
    return span ? span.textContent.trim() : ""
  }

  setCellValue(cell, number) {
    const span = cell.querySelector(".cellValue")
    if (span) { span.textContent = number }
    cell.classList.add("hasValue")
  }

  clearCellValue(cell) {
    const span = cell.querySelector(".cellValue")
    if (span) { span.textContent = "" }
    cell.classList.remove("hasValue")
    cell.classList.remove("incorrectSelection")
  }

  // Candidates that are visible (i.e. the cell has no committed value).
  getCandidates(cell) {
    if (cell.classList.contains("hasValue")) { return [] }
    return Array.from(cell.querySelectorAll(".candidate"))
      .filter(span => span.textContent.trim() !== "")
      .map(span => span.dataset.candidate)
  }

  toggleCandidate(cell, number) {
    const span = cell.querySelector(`.candidate[data-candidate="${number}"]`)
    if (!span) { return }
    span.textContent = span.textContent.trim() === "" ? number : ""
  }

  clearCandidates(cell) {
    cell.querySelectorAll(".candidate").forEach(span => span.textContent = "")
  }

  removeCandidate(cell, number) {
    const span = cell.querySelector(`.candidate[data-candidate="${number}"]`)
    if (span) { span.textContent = "" }
  }

  // Strips the given candidate from every cell sharing a row, column, or 3x3
  // box with the source cell. Cell ids are the row-major index (0..80).
  removeCandidateFromPeers(cell, number) {
    const id  = parseInt(cell.id, 10)
    const row = Math.floor(id / 9)
    const col = id % 9

    this.cellTargets.forEach((peer) => {
      if (peer === cell) { return }
      const peerId  = parseInt(peer.id, 10)
      const peerRow = Math.floor(peerId / 9)
      const peerCol = peerId % 9

      const sameRow = peerRow === row
      const sameCol = peerCol === col
      const sameBox = Math.floor(peerRow / 3) === Math.floor(row / 3) &&
                      Math.floor(peerCol / 3) === Math.floor(col / 3)

      if (sameRow || sameCol || sameBox) {
        this.removeCandidate(peer, number)
      }
    })
  }

  // After toggling a candidate, refresh the board highlight so matching
  // values and candidates light up for the number just touched.
  refreshHighlight(selectedCell, number) {
    this.cellTargets.forEach((cell) => cell.classList.remove("highlighted"))
    this.highlightNumber(number, selectedCell)
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

    let url        = window.location.origin + "/check_input"
    const request  = new FetchRequest('post', url, requestData)
    const response = await request.perform()

    return response
  }
}
