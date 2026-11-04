import { LightningElement, wire } from 'lwc';

import { subscribe, unsubscribe } from 'lightning/empApi';

import { refreshApex } from '@salesforce/apex';

import getAtRiskCases
    from '@salesforce/apex/SLABoardController.getAtRiskCases';


const COLUMNS = [

    { label: 'Case #', fieldName: 'CaseNumber' },

    { label: 'Subject', fieldName: 'Subject' },

    { label: 'Priority', fieldName: 'Priority' },

    { label: 'Level', fieldName: 'Escalation_Level__c' },

    {
        label: 'SLA Due',
        fieldName: 'SLA_Due__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    }

];


export default class SlaBoard extends LightningElement {

    columns = COLUMNS;

    cases = [];

    wiredResult;

    subscription = {};


    // Apex se data lao

    @wire(getAtRiskCases)

    wiredCases(result) {

        this.wiredResult = result;

        if (result.data) {

            this.cases = result.data;

        }

    }


    // Platform Event ko listen karo

    connectedCallback() {

        subscribe('/event/SLA_Alert__e', -1, () => {

            if (this.wiredResult) {

                refreshApex(this.wiredResult);

            }

        }).then((response) => {

            this.subscription = response;

        });

    }


    // Component remove hone par subscription band karo

    disconnectedCallback() {

        if (this.subscription && this.subscription.id) {

            unsubscribe(this.subscription, () => {});

        }

    }

}