import { Controller } from '@hotwired/stimulus';

let fieldsCounter = 0;
// Sample: = f.text_field :title, value: @page.title_data.to_json, class: 'form-control', required: true, data: { controller: 'gaco-cms-translatable' }
export default class extends Controller {
  declare element: HTMLTextAreaElement|HTMLInputElement;
	static values = {
		closestClone: String
	}
  declare dataValue: object;
	declare dataName: string;
	declare locales: string[];
	declare currentLoc: string;
	declare closestCloneValue: string;

	initialize() {
		fieldsCounter += 1;
		this.locales = window.gaco_cms_config.locales;
		this.currentLoc = window.gaco_cms_config.locale;
  	try {
			this.dataValue = JSON.parse(this.element.value || '{}');
		} catch(e) {
			console.log("====failed translation: ", e, this.element)
			this.dataValue = { [this.currentLoc]: this.element.value };
		}
		console.log("====initialized translation: ", this.dataValue, this.element.value, this.element)
  	this.dataName = this.element.name;
		this.elementToHide().insertAdjacentHTML('afterend', this.tpl());
  	this.hideElement();
  }

	connect() {
		console.log("======= translation connected", this.element);
	}

  hideElement() {
		this.element.name = '';
		this.elementToHide().style.display = 'none';
	}

	elementToHide(): HTMLElement {
		if (!this.closestCloneValue) return this.element;

		return this.element.closest<HTMLElement>(this.closestCloneValue);
	}

  tpl() {
  	return `
		<div class="translation-panel">
			<ul class="nav nav-tabs justify-content-end" role="tablist" style="margin-top: -24px">
				${ this.locales.map((loc) => 
				`<li class="nav-item" role="presentation">
					<button class="nav-link pt-0 pb-0 ${ loc == this.currentLoc ? 'active' : '' }" 
						data-bs-target="#${this.localeKey(loc)}-tab" data-bs-toggle="tab" type="button" role="tab" 
						aria-controls="${loc}" aria-selected="true" tabindex="-1">${loc}</button>
				</li>` ).join('') }
			</ul>
			<div class="tab-content">
				${ this.locales.map((loc) => 
				`<div class="tab-pane fade ${ loc == this.currentLoc ? 'show active' : '' }" role="tabpanel" id="${this.localeKey(loc)}-tab">
					${this.fieldFor(loc)}
				 </div>` ).join('') }
			</div>
		</div>
  	`;
	}

	localeKey(locale) {
	  return `${this.dataName.replace(/[\W_]+/g, '_')}_${locale}_${fieldsCounter}`;
	}

	fieldFor(locale) {
		const value = this.dataValue[locale] || '';
  	const clone = this.element.cloneNode() as HTMLInputElement;
		const updatedAttr = clone.getAttribute('data-controller').replace('gaco-cms-translatable', '');
  	clone.setAttribute('data-controller', updatedAttr);
		clone.setAttribute('value', value);
		clone.removeAttribute('required'); // TODO: make only for the hidden ones
		clone.innerHTML = value;
  	clone.classList.add('translation-field');
		clone.name = `${this.dataName}[${locale}]`;
		clone.id = `${this.localeKey(locale)}`;

		if (this.closestCloneValue) {
			const panel = this.element.closest(this.closestCloneValue).cloneNode(true) as HTMLElement;
			panel.querySelector('input').outerHTML = clone.outerHTML;
			return panel.outerHTML;
		} else {
			return clone.outerHTML;
		}
	}
}
