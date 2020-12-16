import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import installPackage from '@salesforce/apex/ProvisioningRequestHandler.InstallPackage';
import checkPackageInstall from '@salesforce/apex/ProvisioningRequestHandler.checkPackageInstall';
import REQUEST_PACKAGE_ID from '@salesforce/schema/Provisioning_Request_Package__c.Id';

export default class InstallPackage extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [ REQUEST_PACKAGE_ID ] }) 
    record;

    handleClick() {
        installPackage({ record_id: getFieldValue(this.record.data, REQUEST_PACKAGE_ID) })
        .then(result => {

            const evt = new ShowToastEvent({
                title: 'Provisioning Request Response',
                message: result.Message,
                variant: result.MessageType,
            });
            this.dispatchEvent(evt);

            getRecordNotifyChange([{recordId: this.recordId}]);
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });
    }

    handleCheck() {
        checkPackageInstall({ record_id: getFieldValue(this.record.data, REQUEST_PACKAGE_ID) })
        .then(result => {

            const evt = new ShowToastEvent({
                title: 'Provisioning Request Response',
                message: result.Message,
                variant: result.MessageType,
            });
            this.dispatchEvent(evt);

            getRecordNotifyChange([{recordId: this.recordId}]);
        })
        .catch(error => {
            console.log('error: ');
            console.log(error);
        });
    }
}