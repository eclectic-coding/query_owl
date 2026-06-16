import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["controllerInput", "clearButton"]

  connect() {
    this._updateClear()
  }

  filter({ target }) {
    clearTimeout(this._timer)
    this._updateClear()
    this._timer = setTimeout(() => target.form.requestSubmit(), 300)
  }

  select({ target }) {
    clearTimeout(this._timer)
    target.form.requestSubmit()
  }

  clearController() {
    this.controllerInputTarget.value = ""
    this._updateClear()
    this.controllerInputTarget.form.requestSubmit()
  }

  _updateClear() {
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.hidden = this.controllerInputTarget.value.length === 0
    }
  }
}