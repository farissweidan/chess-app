import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.fromSquare = null
    if (this.element.dataset.computerPending === "true") {
      this.computerMoveTimer = setTimeout(() => this.playComputerMove(), 1000)
    }
  }

      async select(event) {
    if (this.element.dataset.computerPending === "true") return
    const square = event.currentTarget

    if (this.fromSquare === null) {
      if (!square.querySelector("span")) return

      this.fromSquare = square
      square.classList.add("selected")
      await this.showLegalMoves(square)
      return
    }

    if (square === this.fromSquare) {
      square.classList.remove("selected")
      this.fromSquare = null
      this.clearMoveHints()
      return
    }

        const targetPiece = square.querySelector("span")
    const selectedPiece = this.fromSquare.querySelector("span")

    if (targetPiece && targetPiece.className === selectedPiece.className) {
      this.fromSquare.classList.remove("selected")
      this.fromSquare = square
      square.classList.add("selected")
            await this.showLegalMoves(square)
      return
    }

    const from = this.fromSquare.dataset.square
    const to = square.dataset.square
    const selectedPieceCode = selectedPiece.dataset.piece
    this.fromSquare.classList.remove("selected")
    this.fromSquare = null

    const promotes = (selectedPieceCode === "P" && to[1] === "8") ||
      (selectedPieceCode === "p" && to[1] === "1")
    if (promotes) {
      this.pendingMove = { from, to }
      this.element.querySelector("[data-promotion-dialog]").showModal()
      return
    }

    await this.submitMove(from, to)
  }

  async choosePromotion(event) {
    const promotion = event.currentTarget.dataset.promotion
    const { from, to } = this.pendingMove
    this.pendingMove = null
    this.element.querySelector("[data-promotion-dialog]").close()
    await this.submitMove(from, to, promotion)
  }

  cancelPromotion() {
    this.pendingMove = null
    this.element.querySelector("[data-promotion-dialog]").close()
  }

  async submitMove(from, to, promotion = "Q") {
    try {
      const response = await fetch(this.element.dataset.moveUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: new URLSearchParams({ from, to, promotion })
      })

      if (!response.ok) {
        this.clearMoveHints()
        return
      }

      window.location.reload()
    } catch (error) {
      console.error("Could not submit chess move", error)
      alert("Could not contact the server. Please try again.")
    }
  }

  disconnect() {
    clearTimeout(this.computerMoveTimer)
  }

  async playComputerMove() {
    try {
      const response = await fetch(this.element.dataset.computerMoveUrl, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      if (!response.ok) {
        throw new Error(`Could not make computer move (${response.status})`)
      }

      const result = await response.json()
      if (result.computer_moved) window.location.reload()
    } catch (error) {
      console.error("Could not request computer move", error)
      const status = this.element.querySelector(".board-hint")
      if (status) status.textContent = "The computer could not move. Please refresh to try again."
    }
  }

  async getHint() {
    const message = this.element.querySelector("[data-hint-message]")
    const button = this.element.querySelector(".hint-button")
    this.element.querySelectorAll(".hint-from, .hint-to").forEach((square) => {
      square.classList.remove("hint-from", "hint-to")
    })

    if (message) message.textContent = ""
    if (button) button.disabled = true

    try {
      const response = await fetch(this.element.dataset.hintUrl, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) throw new Error(`Could not get a hint (${response.status})`)

      const { hint } = await response.json()
      const fromSquare = this.element.querySelector(`[data-square="${hint.from}"]`)
      const toSquare = this.element.querySelector(`[data-square="${hint.to}"]`)
      fromSquare?.classList.add("hint-from")
      toSquare?.classList.add("hint-to")
      if (message) message.textContent = `Try moving from ${hint.from} to ${hint.to}.`
    } catch (error) {
      console.error("Could not get chess hint", error)
      if (message) message.textContent = "Could not get a hint. Please try again."
    } finally {
      if (button) button.disabled = false
    }
  }

    async showLegalMoves(square) {
    this.clearMoveHints()

    const url = this.element.dataset.legalMovesUrl.replace(
      "SQUARE",
      encodeURIComponent(square.dataset.square)
    )
    const response = await fetch(url, {
      headers: { "Accept": "application/json" }
    })

    if (!response.ok) {
      throw new Error(`Could not load moves (${response.status})`)
    }

    const result = await response.json()

    result.moves.forEach((move) => {
      const destination = this.element.querySelector(`[data-square="${move}"]`)
      if (!destination) return

      const hintClass = destination.querySelector("span") ? "legal-capture" : "legal-move"
      destination.classList.add(hintClass)
    })
  }

  clearMoveHints() {
    this.element.querySelectorAll(".legal-move, .legal-capture").forEach((square) => {
      square.classList.remove("legal-move", "legal-capture")
    })
  }
}