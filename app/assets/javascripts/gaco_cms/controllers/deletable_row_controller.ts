import { Controller } from '@hotwired/stimulus';

// Sample: = f.check_box :_destroy, 'data-controller': 'gaco-cms-deletable_row', 'data-hide-closest': '.list-group-item', 'data-hideonly': value.id.present?
//	data-hideonly => [boolean] if data-hideonly is empty or false, just hide the data-hide-closest panel, else, it is removed
//	data-hide-closest => [css selector] the panel to be hide/removed
//  data-propagate => [css selector] elements to be marked as checked

export default class extends Controller {
  declare element: HTMLInputElement;
  declare panelToHide: HTMLElement;
  declare isSaved: boolean;

	connect() {
		this.element.style.display = 'none';
		this.element.insertAdjacentHTML('afterend', this.deleteBtn());
		const hideTarget = this.element.getAttribute('data-hide-closest');
		this.isSaved = (this.element.getAttribute('data-hideonly') || 'false') != 'false';
		if (hideTarget) this.panelToHide = this.element.closest(hideTarget);
		this.bindEvent();
	}

	deleteBtn() {
		return `<button type="button" class="btn btn-danger btn-sm del-btn">
				<i class="fa fa-trash"></i>
			</button>`;
	}

	bindEvent() {
		const that = this;
		this.element.nextElementSibling.addEventListener('click', () => {
			if (!that.isSaved || confirm('Are you sure?')) {
				that.element.checked = true;
				if (that.panelToHide) that.hidePanel();
			}
		}, false);
	}

	hidePanel() {
		if (this.isSaved) {
			this.panelToHide.style.display = 'none';
			const propagated = this.element.getAttribute('data-propagate');
			if (propagated)
				this.panelToHide.querySelectorAll<HTMLInputElement>(propagated).forEach((ele) => ele.checked = true);
		} else this.panelToHide.remove();
	}
}
