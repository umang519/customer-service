import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import LEAD_NAME from '@salesforce/schema/Lead.Name';
import LEAD_LAST_NAME from '@salesforce/schema/Lead.LastName';
import LEAD_COMPANY from '@salesforce/schema/Lead.Company';
import LEAD_EMAIL from '@salesforce/schema/Lead.Email';
import LEAD_PHONE from '@salesforce/schema/Lead.Phone';
import LEAD_STATUS from '@salesforce/schema/Lead.Status';
import LEAD_RATING from '@salesforce/schema/Lead.Rating';
import LEAD_INDUSTRY from '@salesforce/schema/Lead.Industry';
import LEAD_OWNER_NAME from '@salesforce/schema/Lead.Owner.Name';

const FIELDS = [
    LEAD_NAME,
    LEAD_LAST_NAME,
    LEAD_COMPANY,
    LEAD_EMAIL,
    LEAD_PHONE,
    LEAD_STATUS,
    LEAD_RATING,
    LEAD_INDUSTRY,
    LEAD_OWNER_NAME
];

export default class LeadConversionReadinessPanel extends LightningElement {
    @api recordId;
    leadObject = LEAD_OBJECT;
    lead;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredLead({ error, data }) {
        if (data) {
            this.lead = data;
        } else if (error) {
            this.lead = undefined;
            // eslint-disable-next-line no-console
            console.error('Error loading Lead record', error);
        }
    }

    get lastName() {
        return this.lead?.fields?.LastName?.value;
    }

    get company() {
        return this.lead?.fields?.Company?.value;
    }

    get status() {
        return this.lead?.fields?.Status?.value;
    }

    get isReady() {
        return Boolean(this.lastName && this.company && this.status);
    }
}