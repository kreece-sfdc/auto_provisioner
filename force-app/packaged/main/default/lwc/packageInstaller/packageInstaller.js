import { LightningElement, track } from 'lwc';

export default class PackageInstaller extends LightningElement {
    @track manifestId;
    @track showNewManifestModal = false;
    @track showLoadManifestModal = false;

    /*
        handleCreateNewManifest
        Causes the Modal Popup to appear to enter the name of the new Manifest
    */
    handleNewManifestWindow(){
        this.showNewManifestModal = true;
    }

    /*
        handleNewManifest
        Handles updating the UI to create a new installation Manifest
    */
    handleNewManifest(event){
        this.handleCloseModals();
        this.manifestId = event.detail;
    }

    handleLoadManifestWindow(){
        this.showLoadManifestModal = true;
    }

    handleLoadManifest(event){
        this.manifestId = event.detail.manifestId;
        this.handleCloseModals();
    }

    /*
        handleCloseModals
        Sets all modal pop ups to close
    */
    handleCloseModals(){
        this.showNewManifestModal = false;
        this.showLoadManifestModal = false;
    }

    handleBack(){
        this.manifestId = '';
    }
}