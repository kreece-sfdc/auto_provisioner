import { LightningElement, api } from 'lwc';

export default class RecordCreate extends LightningElement {
    @api objectApiName;
    @api objectName;
    @api cols;
    @api recId;

    handleSuccess(event){
        console.log(event);
        console.log(event.detail.id);
        this.dispatchEvent(new CustomEvent('success', {detail: event.detail.id}));
    }

    handleError(event){
        this.dispatchEvent(new CustomEvent('error', {detail: event.detail.detail}));
    }

    handleCancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}