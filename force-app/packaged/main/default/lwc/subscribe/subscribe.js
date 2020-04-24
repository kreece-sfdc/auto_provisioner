import { LightningElement, track } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

export default class Subscribe extends LightningElement 
{
    @track channelName = '/event/Provisioner__e';
    @track isSubscribeDisabled = false;
    @track isUnsubscribeDisabled = !this.isSubscribeDisabled;

    subscription = {};

    renderedCallback() {
        this.handleSubscribe();
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = function(res) {
            // Response contains the payload of the new message received
            var packageVersion = res.data.payload.aprv__Package_Version_Id__c;
            var orgId = res.data.payload.aprv__OrgId__c;
            var status = res.data.payload.aprv__Status__c;
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
}