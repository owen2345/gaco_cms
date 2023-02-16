import { Controller } from '@hotwired/stimulus';
import { ajaxRequest } from "../lib/request";

// converts a text-field into a uploadable field
// Sample:
//   .photo_panel{ data: { controller: 'gaco-cms-file-input' } }
//     = f.text_field :photo_url, class: 'form-control', accept: 'image/*', data: { 'gaco-cms-file-input-target': 'input' }
export default class extends Controller {
  declare element: HTMLElement;
	static targets = ['input'];
	declare inputTarget: HTMLInputElement;


  connect() {
  	setTimeout(this.parseElement.bind(this), 200); // delay to wait for translatable structure
  }

  parseElement() {
		this.element.setAttribute('data-file-input-redered', 'true');
		this.element.classList.add('input-group');
		this.element.insertAdjacentHTML('beforeend', this.tpl());
		this.bindPreview();
		this.dispatchChange();
		this.bindUploader();
	}

  tpl() {
  	return `
			<button class="btn btn-outline-light btn-upload" type="button">
				<i class="fa fa-upload"></i>
			</button>
			<span class="preview input-group-text p-0"></span>`;
	}

	bindPreview() {
		const that = this;
		const preview = this.element.querySelector('.preview');
  	this.inputTarget.addEventListener('change', () => {
  		preview.innerHTML = that.previewTpl(that.inputTarget.value);
		});
	}

	previewTpl(url) {
		const previewExt = ['png', 'jpg', 'jpeg', 'gif'];
		if (!url) return '';
		if (!previewExt.includes(url.split('.').pop().toLowerCase())) return '';

  	return `
  		<a href="${url}" target="_blank">
  			<img src="${url}" style="max-width: 50px; max-height: 50px;" />
			</a>
  	`;
	}

	bindUploader() {
		const btn = this.element.querySelector('.btn-upload');
		const that = this;
  	btn.addEventListener('click', () => {
			const input = document.createElement('input');
			input.setAttribute('type', 'file');
			input.setAttribute('accept', that.inputTarget.getAttribute('accept'));
			input.onchange = async function () {
				await that.uploadFile(input);
			};
			input.click();
		});
	}

	async uploadFile(field: HTMLInputElement) {
		const formData = new FormData();
		formData.append('file', field.files[0]);
		const res = await ajaxRequest(window.gaco_cms_config.upload_path, formData, 'POST', 'json');
		if (res) {
			this.inputTarget.value = res.location;
			this.dispatchChange();
		}
	}

	dispatchChange() {
		this.inputTarget.dispatchEvent(new Event('change'));
	}
}
