import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';
import LEAD_OWNER_ID from '@salesforce/schema/Lead.OwnerId';
import LEAD_REGION from '@salesforce/schema/Lead.Region__c';
import LEAD_INDUSTRY from '@salesforce/schema/Lead.Industry';
import LEAD_SOURCE from '@salesforce/schema/Lead.LeadSource';
import LEAD_STATUS from '@salesforce/schema/Lead.Status';

const LEAD_FIELDS = [LEAD_OWNER_ID, LEAD_REGION, LEAD_INDUSTRY, LEAD_SOURCE, LEAD_STATUS];

export default class LeadRoutingSummary extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: LEAD_FIELDS })
    wiredLead;

    get isLoading() {
        return !this.wiredLead.data && !this.wiredLead.error;
    }

    get hasError() {
        return !!this.wiredLead.error;
    }

    get region() {
        return this.getDisplayableFieldValue(LEAD_REGION);
    }

    get industry() {
        return this.getDisplayableFieldValue(LEAD_INDUSTRY);
    }

    get leadSource() {
        return this.getDisplayableFieldValue(LEAD_SOURCE);
    }

    get status() {
        return this.getDisplayableFieldValue(LEAD_STATUS);
    }

    getDisplayableFieldValue(fieldReference) {
        if (!this.wiredLead.data) {
            return '—';
        }
        return getFieldDisplayValue(this.wiredLead.data, fieldReference)
            || getFieldValue(this.wiredLead.data, fieldReference)
            || '—';
    }
}