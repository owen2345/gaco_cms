import { Controller } from '@hotwired/stimulus';
import { ajaxRequest } from "../lib/request";

// Sample: %li= link_to(v, url_for(action: :new_field, id: @group, kind: k), class: 'dropdown-item', data: { controller: 'gaco-cms-remote-content', 'gaco-cms-remote-content-target-value': '#fields_list' })
export default class extends Controller {
  declare element: HTMLLinkElement;
	static values = { target: String };
	declare targetValue: string;


  connect() {
  	const that = this;
  	this.element.addEventListener('click', (ev) => {
  		ev.preventDefault();
  		that.loadContent();
		});
  }

	async loadContent() {
		const res = await ajaxRequest(this.element.href);
		if (!res) return;

		document.body.querySelector<HTMLElement>(this.targetValue).insertAdjacentHTML('beforeend', res);
		window.scrollTo(0, document.body.scrollHeight);
	}
}
