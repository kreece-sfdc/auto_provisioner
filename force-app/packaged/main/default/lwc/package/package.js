import { LightningElement, wire, track, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const PACKAGE_FIELDS = 'aprv__Manifest_Package__c.aprv__Package_Version__r.sfLma__Package__r.Name';

//const FIELDS = ['sfLma__Package_Version__c.Name', 'sfLma__Package_Version__c.aprv__Package_Version_Password__c', 'sfLma__Package_Version__c.sfLma__Version_ID__c'];

export default class Package extends LightningElement {
    @api manifestPackageId;
    @track packageDetails;

    @wire(getRecord, { recordId: '$manifestPackageId', fields: PACKAGE_FIELDS})
    wirePackageVersionId({error, data}){
        if(data){
            this.packageDetails = {package: data.fields.aprv__Package_Version__r.value.fields.sfLma__Package__r.displayValue, version: data.fields.aprv__Package_Version__r.displayValue};
        }
        else if(error){
            console.log(error);
        }
    }

    connectedCallback(){

    }
}