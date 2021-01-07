import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/*import SignupOrg from '@salesforce/apex/ProvisioningRequestHandler.SignupOrg';
import CheckOrgSignup from '@salesforce/apex/ProvisioningRequestHandler.CheckOrgSignup';
import REQUEST_PACKAGE_ID from '@salesforce/schema/Provisioning_Request_Package__c.Id';*/

export default class PushToSignup extends LightningElement {
    @api recordId;


    @wire(getRecord, { recordId: '$recordId', fields: [ REQUEST_PACKAGE_ID ] }) 
    record;

    handleClick() {
        /*SignupOrg({ record_id: getFieldValue(this.record.data, REQUEST_PACKAGE_ID) })
        .then(result => {

            const evt = new ShowToastEvent({
                title: 'Signup Request Response',
                message: result.Message,
                variant: result.MessageType,
            });
            this.dispatchEvent(evt);

            getRecordNotifyChange([{recordId: this.recordId}]);
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });*/
    }

    handleStatusClick() {
        /*CheckOrgSignup({ record_id: getFieldValue(this.record.data, REQUEST_PACKAGE_ID) })
        .then(result => {

            const evt = new ShowToastEvent({
                title: 'Signup Status Response',
                message: result.Message,
                variant: result.MessageType,
            });
            this.dispatchEvent(evt);

            getRecordNotifyChange([{recordId: this.recordId}]);
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });*/
    }
}