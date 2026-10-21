import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import searchLeads from '@salesforce/apex/QuickLeadSearchController.searchLeads';

const SEARCH_DELAY = 300;
const COLUMNS = [
    {
        label: 'Name',
        type: 'button',
        fieldName: 'Id',
        typeAttributes: {
            label: { fieldName: 'Name' },
            name: 'view',
            variant: 'base'
        }
    },
    { label: 'Company', fieldName: 'Company' },
    { label: 'Email', fieldName: 'Email' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Region', fieldName: 'Region__c' },
    { label: 'Industry', fieldName: 'Industry' }
];

export default class QuickLeadSearch extends NavigationMixin(LightningElement) {
    searchTerm = '';
    leads = [];
    error;
    isLoading = false;
    hasSearched = false;
    columns = COLUMNS;
    delayTimeout;

    get hasResults() {
        return this.leads && this.leads.length > 0;
    }

    get showEmptyState() {
        return this.hasSearched && !this.hasResults && !this.isLoading;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.performSearch();
        }, SEARCH_DELAY);
    }

    async performSearch() {
        this.error = undefined;

        const term = this.searchTerm ? this.searchTerm.trim() : '';
        if (term.length < 3) {
            this.leads = [];
            this.hasSearched = false;
            return;
        }

        this.isLoading = true;
        try {
            this.leads = await searchLeads({ searchTerm: term });
            this.hasSearched = true;
        } catch (error) {
            this.error = error.body ? error.body.message : error.message;
            this.leads = [];
            this.hasSearched = true;
        } finally {
            this.isLoading = false;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: 'Lead',
                    actionName: 'view'
                }
            });
        }
    }
}