/*
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

import { LightningElement, api, track } from 'lwc';

let instanceCounter = 0;

/**
 * Presentational typeahead. Does not load Salesforce data; the parent debounces
 * `search` and passes matching `{id, label}` rows back through `results`.
 *
 * A native input is used so `aria-activedescendant` can point at option ids in
 * this same shadow tree (WAI-ARIA combobox / listbox).
 */
export default class RecordTypeahead extends LightningElement {
    /**
     * Minimum characters before a `search` event is fired (empty term is also fired so the parent can clear).
     * @type {number}
     */
    @api minLength = 3;

    /**
     * Visible field label (associated with the combobox input).
     * @type {string}
     */
    @api label;

    /**
     * When true, the input and clear control are not interactive.
     * @type {boolean}
     */
    @api disabled = false;

    /**
     * Placeholder shown when the input is empty.
     * @type {string}
     */
    @api placeholder = '';

    /**
     * When true, an empty selection is invalid after blur or reportValidity().
     * @type {boolean}
     */
    @api required = false;

    @track _results = [];
    @track highlightedIndex = -1;
    @track _inputValue = '';
    @track _selectedId = null;
    @track _selectedLabel = '';
    @track _listOpen = false;
    @track _showRequiredError = false;

    _uid;

    constructor() {
        super();
        instanceCounter += 1;
        this._uid = `rtc-${instanceCounter}`;
    }

    renderedCallback() {
        const input = this.template.querySelector('[role="combobox"]');
        if (!input) {
            return;
        }
        const options = this.template.querySelectorAll('[role="option"]');
        const active = options[this.highlightedIndex];
        if (this.isOpen && active && active.id) {
            input.setAttribute('aria-activedescendant', active.id);
        } else {
            input.removeAttribute('aria-activedescendant');
        }
    }

    /**
     * Options to render in the listbox. Parent owns fetching; replace the array to update.
     * @type {Array<{id: string, label: string}>}
     */
    @api
    get results() {
        return this._results;
    }
    set results(value) {
        this._results = Array.isArray(value)
            ? value.filter((item) => item && item.id)
            : [];
        this.syncHighlight();
        this._listOpen = this._results.length > 0 && !this.disabled;
    }

    /**
     * Selected record id, or null when nothing is selected.
     * @type {string|null}
     */
    @api
    get value() {
        return this._selectedId;
    }
    set value(val) {
        this._selectedId = val || null;
        if (!this._selectedId) {
            this._selectedLabel = '';
            this._inputValue = '';
            this._showRequiredError = false;
        } else if (this._selectedLabel) {
            this._inputValue = this._selectedLabel;
        }
        this.syncHighlight();
    }

    /**
     * Label shown in the input for the current selection (parent should pass this with `value`).
     * @type {string}
     */
    @api
    get selectedLabel() {
        return this._selectedLabel;
    }
    set selectedLabel(val) {
        this._selectedLabel = val || '';
        if (this._selectedId && this._selectedLabel) {
            this._inputValue = this._selectedLabel;
        }
    }

    /**
     * Shows the required error state. Used by parent forms before submit.
     * @returns {boolean} true when valid
     */
    @api
    reportValidity() {
        this._showRequiredError = this.required && !this._selectedId;
        return !this._showRequiredError;
    }

    get inputId() {
        return `${this._uid}-input`;
    }

    get listboxId() {
        return `${this._uid}-listbox`;
    }

    get computedLabel() {
        return this.label || 'Search';
    }

    get inputValue() {
        return this._inputValue;
    }

    get normalizedMinLength() {
        const parsed = Number(this.minLength);
        return Number.isFinite(parsed) && parsed > 0 ? parsed : 3;
    }

    get hasResults() {
        return this._results.length > 0;
    }

    get isOpen() {
        return (
            !this.disabled &&
            this._listOpen &&
            this.hasResults &&
            this._inputValue.length >= this.normalizedMinLength
        );
    }

    get ariaExpanded() {
        return this.isOpen ? 'true' : 'false';
    }

    get comboboxClass() {
        const classes = [
            'slds-combobox',
            'slds-dropdown-trigger',
            'slds-dropdown-trigger_click'
        ];
        if (this.isOpen) {
            classes.push('slds-is-open');
        }
        return classes.join(' ');
    }

    get formElementClass() {
        return this._showRequiredError
            ? 'slds-form-element slds-has-error'
            : 'slds-form-element';
    }

    get inputClass() {
        return this._selectedId
            ? 'slds-input slds-combobox__input slds-combobox__input-value'
            : 'slds-input slds-combobox__input';
    }

    get listboxAriaHidden() {
        return this.isOpen ? 'false' : 'true';
    }

    get showClear() {
        return !this.disabled && !!this._selectedId;
    }

    get showRequiredError() {
        return this._showRequiredError;
    }

    get ariaInvalid() {
        return this._showRequiredError ? 'true' : 'false';
    }

    get ariaRequired() {
        return this.required ? 'true' : 'false';
    }

    get showMinLengthHint() {
        return (
            !this.disabled &&
            this._inputValue.length > 0 &&
            this._inputValue.length < this.normalizedMinLength
        );
    }

    get minLengthHint() {
        return `Type at least ${this.normalizedMinLength} characters to search.`;
    }

    get requiredErrorMessage() {
        return `${this.computedLabel} is required.`;
    }

    get optionItems() {
        return this._results.map((item, index) => {
            const isHighlighted = index === this.highlightedIndex;
            const isSelected = item.id === this._selectedId;
            const classes = [
                'slds-media',
                'slds-listbox__option',
                'slds-listbox__option_plain',
                'slds-media_small'
            ];
            if (isHighlighted) {
                classes.push('slds-has-focus');
            }
            if (isSelected) {
                classes.push('slds-is-selected');
            }
            return {
                id: item.id,
                label: item.label == null ? String(item.id) : String(item.label),
                optionId: `${this._uid}-option-${index}`,
                cssClass: classes.join(' '),
                ariaSelected: isSelected ? 'true' : 'false',
                isSelected
            };
        });
    }

    handleInput(event) {
        if (this.disabled) {
            return;
        }
        const term = event.target.value;
        this._inputValue = term;
        this._listOpen = true;
        this._showRequiredError = false;
        if (term.length === 0 || term.length >= this.normalizedMinLength) {
            this.dispatchEvent(
                new CustomEvent('search', {
                    detail: { term }
                })
            );
        }
    }

    handleFocus() {
        if (this.disabled) {
            return;
        }
        if (this.hasResults && this._inputValue.length >= this.normalizedMinLength) {
            this._listOpen = true;
        }
    }

    handleBlur() {
        this._listOpen = false;
        if (this._selectedLabel) {
            this._inputValue = this._selectedLabel;
        }
        if (this.required && !this._selectedId) {
            this._showRequiredError = true;
        }
    }

    handleKeyDown(event) {
        if (this.disabled) {
            return;
        }
        const key = event.key;
        if (key === 'ArrowDown') {
            event.preventDefault();
            this.moveHighlight(1);
        } else if (key === 'ArrowUp') {
            event.preventDefault();
            this.moveHighlight(-1);
        } else if (key === 'Enter') {
            event.preventDefault();
            this.selectHighlighted();
        } else if (key === 'Escape') {
            event.preventDefault();
            this._listOpen = false;
        } else if (key === 'Home' && this.isOpen) {
            event.preventDefault();
            this.highlightedIndex = 0;
        } else if (key === 'End' && this.isOpen) {
            event.preventDefault();
            this.highlightedIndex = this._results.length - 1;
        }
    }

    handleOptionMouseDown(event) {
        event.preventDefault();
    }

    handleOptionClick(event) {
        const id = event.currentTarget.dataset.id;
        const item = this._results.find((row) => row.id === id);
        this.applySelection(item);
    }

    handleClear() {
        if (this.disabled) {
            return;
        }
        this._selectedId = null;
        this._selectedLabel = '';
        this._inputValue = '';
        this._listOpen = false;
        this._showRequiredError = false;
        this.highlightedIndex = -1;
        this.dispatchEvent(
            new CustomEvent('select', {
                detail: { id: null, label: null }
            })
        );
        this.dispatchEvent(
            new CustomEvent('search', {
                detail: { term: '' }
            })
        );
    }

    moveHighlight(delta) {
        if (!this.hasResults) {
            return;
        }
        this._listOpen = true;
        const length = this._results.length;
        if (this.highlightedIndex < 0) {
            this.highlightedIndex = 0;
            return;
        }
        this.highlightedIndex = (this.highlightedIndex + delta + length) % length;
    }

    selectHighlighted() {
        if (
            !this.isOpen ||
            this.highlightedIndex < 0 ||
            this.highlightedIndex >= this._results.length
        ) {
            return;
        }
        this.applySelection(this._results[this.highlightedIndex]);
    }

    applySelection(item) {
        if (!item || !item.id) {
            return;
        }
        this._selectedId = item.id;
        this._selectedLabel = item.label == null ? String(item.id) : String(item.label);
        this._inputValue = this._selectedLabel;
        this._listOpen = false;
        this._showRequiredError = false;
        this.dispatchEvent(
            new CustomEvent('select', {
                detail: { id: item.id, label: this._selectedLabel }
            })
        );
    }

    syncHighlight() {
        if (this._results.length === 0) {
            this.highlightedIndex = -1;
            return;
        }
        const selectedIndex = this._results.findIndex((item) => item.id === this._selectedId);
        this.highlightedIndex = selectedIndex >= 0 ? selectedIndex : 0;
    }
}
