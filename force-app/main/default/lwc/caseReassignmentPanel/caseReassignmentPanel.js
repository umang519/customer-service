import { LightningElement, api, wire } from 'lwc';
import getCurrentOwner from '@salesforce/apex/CaseAssignmentController.getCurrentOwner';
import searchOwners from '@salesforce/apex/CaseAssignmentController.searchOwners';
import reassignCase from '@salesforce/apex/CaseAssignmentController.reassignCase';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class CaseReassignmentPanel extends LightningElement {
    @api recordId;

    currentOwner;
    ownerOptions;
    searchTerm = '';
    selectedOwnerId;
    loading = false;
    searchTimeout;
    wiredCurrentOwnerResult;

    get currentOwnerLabel() {
        return this.currentOwner ? `${this.currentOwner.label} (${this.currentOwner.type})` : 'Loading...';
    }

    get hasOwnerOptions() {
        return this.ownerOptions && this.ownerOptions.length > 0;
    }

    get isReassignDisabled() {
        return !this.selectedOwnerId || this.loading;
    }

    @wire(getCurrentOwner, { caseId: '$recordId' })
    wiredCurrentOwner(result) {
        this.wiredCurrentOwnerResult = result;
        if (result.data) {
            this.currentOwner = result.data;
        }
        if (result.error) {
            this.showError(result.error);
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        clearTimeout(this.searchTimeout);

        if (!this.searchTerm || this.searchTerm.length < 1) {
            this.ownerOptions = undefined;
            return;
        }

        this.searchTimeout = setTimeout(() => {
            this.loading = true;
            searchOwners({ searchTerm: this.searchTerm })
                .then((result) => {
                    this.ownerOptions = result.map((opt) => ({
                        label: `${opt.label} (${opt.type})`,
                        value: opt.value
                    }));
                    this.loading = false;
                })
                .catch((error) => {
                    this.loading = false;
                    this.showError(error);
                });
        }, 300);
    }

    handleOwnerSelect(event) {
        this.selectedOwnerId = event.detail.value;
    }

    handleReassign() {
        if (!this.selectedOwnerId) {
            return;
        }

        this.loading = true;
        reassignCase({ caseId: this.recordId, newOwnerId: this.selectedOwnerId })
            .then(() => {
                this.loading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Case reassigned successfully.',
                        variant: 'success'
                    })
                );
                getRecordNotifyChange([{ recordId: this.recordId }]);
                refreshApex(this.wiredCurrentOwnerResult);
                this.selectedOwnerId = undefined;
                this.ownerOptions = undefined;
                this.searchTerm = '';
            })
            .catch((error) => {
                this.loading = false;
                this.showError(error);
            });
    }

    showError(error) {
        const message = (error && error.body && error.body.message) || error.message || 'An unexpected error occurred';
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }
}