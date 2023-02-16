import { Controller } from '@hotwired/stimulus';

// Sample: = form_for @appointment, url: url_for(action: :destroy), method: :delete, html: { data: { controller: 'form-confirm', 'confirm' => 'Are you sure you want to cancel this appointment?' } } do |f|
export default class extends Controller {
  static values = { message: String };
  declare  messageValue: string;
  declare element: HTMLFormElement|HTMLElement;

  connect() {
    const action = this.element.tagName == 'FORM' ? 'submit' : 'click';
    this.element.addEventListener(action, this.confirm.bind(this), false);
  }

  confirm(event) {
    if (!(window.confirm(this.messageValue || this.element.getAttribute('data-confirm')))) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  };
}
