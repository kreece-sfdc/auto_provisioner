import { LightningElement, track } from 'lwc';

export default class PickListTester extends LightningElement 
{
    renderedCallback() {
        console.log(window.location.href);
    }
}