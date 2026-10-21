import { LightningElement, api, wire } from 'lwc';
import getRecentCaseActivities from '@salesforce/apex/CaseActivityController.getRecentCaseActivities';
import SUBJECT_FIELD from '@salesforce/schema/Task.Subject';
import ACTIVITYDATE_FIELD from '@salesforce/schema/Task.ActivityDate';
import STATUS_FIELD from '@salesforce/schema/Task.Status';
import OWNER_NAME_FIELD from '@salesforce/schema/User.Name';

const DEFAULT_ROW_LIMIT = 10;

export default class CaseActivitySummary extends LightningElement {
    @api recordId;
    @api rowLimit = DEFAULT_ROW_LIMIT;

    activities = [];
    isLoading = true;
    error;

    @wire(getRecentCaseActivities, { caseId: '$recordId', rowLimit: '$rowLimit' })
    wiredActivities({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.activities = data.map((task) => {
                const activityDate = task[ACTIVITYDATE_FIELD.fieldApiName];
                return {
                    recordId: task.Id,
                    subject: task[SUBJECT_FIELD.fieldApiName],
                    activityDate: activityDate,
                    status: task[STATUS_FIELD.fieldApiName],
                    ownerName: task.Owner[OWNER_NAME_FIELD.fieldApiName],
                    formattedDate: activityDate
                        ? new Date(activityDate).toLocaleDateString()
                        : ''
                };
            });
            this.error = undefined;
        } else if (error) {
            this.activities = [];
            this.error = error;
        }
    }

    get hasActivities() {
        return this.activities && this.activities.length > 0;
    }

    get hasError() {
        return !!this.error;
    }

    get errorMessage() {
        return this.error?.body?.message || 'Unable to load recent activities.';
    }
}