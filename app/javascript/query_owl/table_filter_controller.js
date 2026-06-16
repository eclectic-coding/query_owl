import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  filter({ target }) {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => target.form.requestSubmit(), 300)
  }

  select({ target }) {
    clearTimeout(this._timer)
    target.form.requestSubmit()
  }
}