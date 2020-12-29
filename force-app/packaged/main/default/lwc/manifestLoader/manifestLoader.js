import { LightningElement, wire } from 'lwc';
import getAllPackageManifests from '@salesforce/apex/ManifestCanvasUtils.getAllManifests';

export default class ManifestLoader extends LightningElement {
    allManifests;


    @wire (getAllManifests)
    getAllManifests({error, data}){
        if(data){
            this.allManifests = [];

            
            
            /*data.forEach(element => {
                this.allPackageVersions.push({label: element.sfLma__Package__r.Name + ': ' + element.Name, value: element.Id});                    
            });*/
        }
        else if(error){
            console.log(error);
        }
    }
    
    handleLoad(){
        this.dispatchEvent(new CustomEvent('load'));//, {detail: event.detail.id}));
    }

    handleCancel(){
        this.dispatchEvent(new CustomEvent('cancel'));//, {detail: event.detail.id}));
    }
}