import { LightningElement } from 'lwc';

export default class AuthModal extends LightningElement {
    handleCancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}