import { Controller } from '@hotwired/stimulus';
import { Modal } from 'bootstrap';

let modalsCounter = 1;
export default class extends Controller {
  static values = { body: String, title: String, target: String, size: String, selfModal: Boolean };
  declare bodyValue: string;
  declare titleValue: string;
  declare targetValue: string;
  declare sizeValue: string;
  declare selfModalValue: boolean;
  declare element: HTMLLinkElement|HTMLButtonElement;
  declare modalId: string;

	initialize() {
		const that = this;
		if (this.selfModalValue) {
			this.buildModal();
			this.element.remove();
		} else {
			this.element.addEventListener('click', (e) => {
				e.preventDefault();
				e.stopPropagation();
				that.buildModal();
			});
		}
  }

  tpl(content) {
		return `
			<div class="modal fade" id="${this.modalId}" aria-hidden="true" aria-labelledby="exampleModalToggleLabel" tabindex="-1">
				<div class="modal-dialog ${this.sizeValue}">
					<div class="modal-content">
						<div class="modal-header">
							<h5 class="modal-title">${this.titleValue || this.element.getAttribute('data-title') || ''}</h5>
							<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
						</div>
						<div class="modal-body">
							${content}
						</div>
					</div>
				</div>
      </div>
		`;
	}

	calcContent() {
		if (this.selfModalValue) return this.element.innerHTML;
		if (this.bodyValue) return this.bodyValue;
		if (this.targetValue) return document.body.querySelector(this.targetValue).innerHTML;
		if (this.element.tagName == 'A')
			return `<turbo-frame id='turbo-frame-${this.modalId}' src='${this.element.href}'></turbo-frame>`;

		return '';
	}

	buildModal() {
		this.modalId = `modal_${modalsCounter}`;
		document.body.insertAdjacentHTML('beforeend', this.tpl(this.calcContent()));
		modalsCounter += 1;
		setTimeout(this.showModal.bind(this), 2);
	}

	showModal() {
		const modalEle = document.getElementById(this.modalId);
		const modal = new Modal(modalEle);
		modal.show();
		modalEle.addEventListener('close-modal', () => { modal.hide() });
		modalEle.addEventListener('hidden.bs.modal', function (event) {
			modalEle.remove();
		});
	}
}
