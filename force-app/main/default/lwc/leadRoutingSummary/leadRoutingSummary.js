import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';
import REGION_FIELD from '@salesforce/schema/Lead.Region__c';
import INDUSTRY_FIELD from '@salesforce/schema/Lead.Industry';
import LEAD_SOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
import OWNER_NAME_FIELD from '@salesforce/schema/Lead.Owner.Name';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';

const LEAD_FIELDS = [
    REGION_FIELD,
    INDUSTRY_FIELD,
    LEAD_SOURCE_FIELD,
    OWNER_NAME_FIELD,
    STATUS_FIELD
];

export default class LeadRoutingSummary extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: LEAD_FIELDS })
    lead;

    get isLoading() {
        return !this.lead.data && !this.lead.error;
    }

    get hasError() {
        return !!this.lead.error;
    }

    get region() {
        return this.getFieldDisplayOrValue(REGION_FIELD);
    }

    get industry() {
        return this.getFieldDisplayOrValue(INDUSTRY_FIELD);
    }

    get leadSource() {
        return this.getFieldDisplayOrValue(LEAD_SOURCE_FIELD);
    }

    get ownerName() {
        return this.getFieldDisplayOrValue(OWNER_NAME_FIELD);
    }

    get status() {
        return this.getFieldDisplayOrValue(STATUS_FIELD);
    }

    getFieldDisplayOrValue(field) {
        if (!this.lead.data) {
            return '—';
        }
        return getFieldDisplayValue(this.lead.data, field) || getFieldValue(this.lead.data, field) || '—';
    }
}
