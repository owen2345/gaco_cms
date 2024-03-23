import { Controller } from '@hotwired/stimulus';

// Sample:
//   .fw{ data: { controller: 'gaco-cms-toggle-field', 'gaco-cms-toggle-field-open-value': @model.my_key.present? } }
//		 = f.text_field :my_key
export default class extends Controller {
  declare element: HTMLDivElement;
  static values = { open: Boolean };
  declare openValue: boolean;

	initialize() {
		if (this.openValue) return;

		this.element.insertAdjacentHTML('beforebegin', this.editIconTpl());
		this.editBtn().addEventListener('click', this.showElement.bind(this));
		this.element.classList.add('d-none');
	}

	showElement() {
		this.element.classList.remove('d-none');
		this.element.previousElementSibling.remove();
	}

	editIconTpl() {
		if (this.element.parentElement.querySelector('.toggle-field-panel')) return '';

		return `
			<div class="toggle-field-panel">
				<button class="btn btn-sm btn-secondary edit-field" type="button">
					<i class="fa fa-pencil"></i>
				</button>
			</div>
		`;
	}

	editBtn() {
		return this.element.previousElementSibling.querySelector('button');
	}
}
