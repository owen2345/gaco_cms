import { Controller } from '@hotwired/stimulus';
import Sortable from 'sortablejs';

// Sample:
//    #fields_list.accordion{ data: { controller: 'gaco-cms-sortable', 'gaco-cms-sortable-handle-value': '.accordion-item .sort-btn', 'gaco-cms-sortable-input-selector-value': '.position-field' } }
export default class extends Controller {
  declare element: HTMLElement;
  static values = { handle: String, inputSelector: String };
  declare handleValue: string;
  declare inputSelectorValue: string;

	initialize() {
    new Sortable(this.element, {
      handle: this.handleValue,
      animation: 150,
			onEnd: this.updateFieldValues.bind(this)
    });
  }

  updateFieldValues() {
    if (!this.inputSelectorValue) return;
    this.element.querySelectorAll(":scope > *").forEach((group, index) => {
      group.querySelectorAll<HTMLInputElement>(this.inputSelectorValue).forEach((input) => {
        input.value = `${index + 1}`;
      });
    });
  }
}
