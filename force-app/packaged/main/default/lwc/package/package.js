import { LightningElement, wire, track, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const PACKAGE_FIELDS = 'aprv__Manifest_Package__c.aprv__Package_Version__r.sfLma__Package__r.Name';

export default class Package extends LightningElement {
    @api manifestPackageId;
    @api isDuplicate;
    @track packageDetails;


    //TODO Add a little bin icon to packages so they can be removed off the screen
    @wire(getRecord, { recordId: '$manifestPackageId', fields: PACKAGE_FIELDS})
    wirePackageVersionId({error, data}){
        if(data){
            this.packageDetails = {package: data.fields.aprv__Package_Version__r.value.fields.sfLma__Package__r.displayValue, version: data.fields.aprv__Package_Version__r.displayValue};
        }
        else if(error){
            console.log(error);
        }
    }

    get packageStyling(){
        return this.isDuplicate ? 'package-duplicate': 'package';
    }
}