import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import OWNER_ID_FIELD from '@salesforce/schema/Lead.OwnerId';
import OWNER_NAME_FIELD from '@salesforce/schema/Lead.Owner.Name';
import REGION_FIELD from '@salesforce/schema/Lead.Region__c';
import INDUSTRY_FIELD from '@salesforce/schema/Lead.Industry';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';

const FIELDS = [
    OWNER_ID_FIELD,
    OWNER_NAME_FIELD,
    REGION_FIELD,
    INDUSTRY_FIELD,
    STATUS_FIELD
];

export default class LeadAssignmentPanel extends LightningElement {
    @api recordId;

    wiredRecord;
    isUpdating = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredGetRecord(result) {
        this.wiredRecord = result;
    }

    get ownerName() {
        return getFieldValue(this.wiredRecord?.data, OWNER_NAME_FIELD);
    }

    get region() {
        return getFieldValue(this.wiredRecord?.data, REGION_FIELD);
    }

    get industry() {
        return getFieldValue(this.wiredRecord?.data, INDUSTRY_FIELD);
    }

    get status() {
        return getFieldValue(this.wiredRecord?.data, STATUS_FIELD);
    }

    get isOwner() {
        const ownerId = getFieldValue(this.wiredRecord?.data, OWNER_ID_FIELD);
        return ownerId === USER_ID;
    }

    get isAssignDisabled() {
        return this.isUpdating || this.isOwner;
    }

    assignToMe() {
        if (!this.recordId) {
            return;
        }

        this.isUpdating = true;

        const recordInput = {
            fields: {
                Id: this.recordId,
                OwnerId: USER_ID
            }
        };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Lead assigned to you.',
                        variant: 'success'
                    })
                );
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error assigning lead',
                        message: this.reduceErrors(error),
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isUpdating = false;
            });
    }

    reduceErrors(error) {
        if (!error) {
            return 'Unknown error';
        }
        if (typeof error === 'string') {
            return error;
        }
        if (error.body) {
            if (Array.isArray(error.body)) {
                return error.body.map((e) => e.message || JSON.stringify(e)).join(', ');
            }
            if (error.body.message) {
                return error.body.message;
            }
            if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors.map((e) => e.message).join(', ');
            }
            if (error.body.fieldErrors) {
                const messages = [];
                Object.keys(error.body.fieldErrors).forEach((field) => {
                    error.body.fieldErrors[field].forEach((err) => {
                        messages.push(err.message);
                    });
                });
                return messages.join(', ');
            }
        }
        return error.message || 'Unknown error';
    }
}