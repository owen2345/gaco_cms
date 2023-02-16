import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { body: String, title: String, target: String };
  declare  messageValue: string;
  declare element: HTMLLinkElement|HTMLButtonElement;

  connect() {
    // TODO:  show a modal with a url inside or receive a content target
  }
}
