import { Controller } from '@hotwired/stimulus';
import { ajaxRequest } from "../lib/request";

// Add the ability to load tpl content from server via ajax and add it to listTarget
// Sample:
//  .fields-list{ 'data-controller': 'gaco-cms-repeatable-field' }
//     = link_to 'My Title' tpl_admin_field_path(id: field, group_no: group_no), class: 'btn btn-sm', 'data-gaco-cms-repeatable-field-target' => 'button'
//     %ul.list-group.list-group-flush{ 'data-gaco-cms-repeatable-field-target': 'list' }
export default class extends Controller {
	static targets = ['button', 'list'];
	declare element: HTMLElement;
	declare buttonTarget: HTMLLinkElement;
	declare listTarget: HTMLUListElement;
	declare hasButtonTarget: boolean

	connect() {
		if (!this.hasButtonTarget) return;
		this.buttonTarget.addEventListener('click', this.loadTpl.bind(this));
	}

	async loadTpl(event) {
		event.preventDefault();
		const res = await ajaxRequest(this.buttonTarget.href);
		this.listTarget.insertAdjacentHTML('beforeend', res);
	}
}
