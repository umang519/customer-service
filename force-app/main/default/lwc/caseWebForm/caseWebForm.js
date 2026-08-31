import { LightningElement } from 'lwc';
import createCase from '@salesforce/apex/CaseWebFormController.createCase';

export default class CaseWebForm extends LightningElement {
    customerName = '';
    customerEmail = '';
    subject = '';
    description = '';
    priority = 'Medium';
    errorMessage = '';
    showSuccess = false;
    isLoading = false;

    get showForm() {
        return !this.showSuccess;
    }

    get priorityOptions() {
        return [
            { label: 'High', value: 'High' },
            { label: 'Medium', value: 'Medium' },
            { label: 'Low', value: 'Low' }
        ];
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        if (field) {
            this[field] = event.target.value;
        }
    }

    handleSubmit(event) {
        event.preventDefault();
        if (!this.isInputValid()) {
            return;
        }
        this.errorMessage = '';
        this.isLoading = true;

        createCase({
            customerName: this.customerName,
            customerEmail: this.customerEmail,
            subject: this.subject,
            description: this.description,
            priority: this.priority
        })
            .then(() => {
                this.showSuccess = true;
            })
            .catch((error) => {
                this.errorMessage = this.reduceErrors(error).join(', ');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    isInputValid() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox');
        let isValid = true;
        inputs.forEach((input) => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    handleCancel() {
        this.resetForm();
    }

    handleReset() {
        this.resetForm();
        this.showSuccess = false;
    }

    resetForm() {
        this.customerName = '';
        this.customerEmail = '';
        this.subject = '';
        this.description = '';
        this.priority = 'Medium';
        this.errorMessage = '';
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return errors
            .filter((error) => !!error)
            .map((error) => {
                if (Array.isArray(error.body)) {
                    return error.body.map((e) => e.message);
                } else if (error.body && error.body.message) {
                    return error.body.message;
                } else if (error.message) {
                    return error.message;
                }
                return 'Unknown error';
            })
            .reduce((prev, curr) => prev.concat(curr), []);
    }
}