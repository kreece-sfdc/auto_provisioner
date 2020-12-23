import { api, LightningElement, track, wire } from 'lwc';
import getAllPackageVersions from '@salesforce/apex/ManifestCanvasUtils.getAllPackageVersions';

export default class PackageSelector extends LightningElement {
    allPackageVersions;
    @api selectedPackageVersions;
    
    @wire (getAllPackageVersions)
    wiredPackageVersions({error, data}){
        if(data){
            this.allPackageVersions = [];
            data.forEach(element => {
                this.allPackageVersions.push({label: element.Name, value: element.Id});                    
            });
        }
        else if(error){
            console.log(error);
        }
    }

    handleChange(event){
        this.selectedPackageVersions = event.detail.value;
    }

    handleCancel(){
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleDone(){
        this.dispatchEvent(new CustomEvent('success', {detail: this.selectedPackageVersions}));
    }
}