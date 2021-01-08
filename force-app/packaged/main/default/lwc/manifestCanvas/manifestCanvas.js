import { LightningElement, track, wire, api } from 'lwc';
import createManifestPackages from '@salesforce/apex/ManifestCanvasUtils.createManifestPackages';
import deleteManifestPackages from '@salesforce/apex/ManifestCanvasUtils.deleteManifestPackages';
import saveManifestPackages from '@salesforce/apex/ManifestCanvasUtils.saveManifestPackages';


//const FIELDS = ['aprv__Manifest_Package__c.aprv__Package_Version__c', 'aprv__Manifest_Package__c.aprv__Manifest__c' , 'aprv__Manifest_Package__c.Name'];

export default class ManifestCanvas extends LightningElement {
    @api manifestId;
    @track columns = {};
    @track allPackages = [];
    @track duplicatePackages = false;
    @track saveText = 'Save';
    @track saveStyle = 'brand'
    showSelectPackageVersionsModal = false;
    showAuthenticationModal = false;

    unhighlightedColumn = 'background: white';
    highlightedColumn = 'background: linear-gradient(#034485, #e6e6e6);'; //#c3faec

    connectedCallback(){
        console.log(this.manifestId);
        this.resetColumns();
        this.createManifestPackages(null);
    }    

    resetColumns(){
        this.columns = [{id: '1', items: []}];
    }

    handleBack(){
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleAuth(){
        this.showAuthenticationModal = true;
    }

    get hasPackages(){
        return this.allPackages.length > 0;
    }

    /*
        handleAddPackageVersions
        Set the showSelectPackageVersionsModal var to true
        This brings up the packageSelector cmp in a modal
        for selecting the package records
    */
    handleAddPackageVersions(){
        this.showSelectPackageVersionsModal = true;
    }

    /*
        handleCloseModals
        Sets all modal pop ups to close
    */
    handleCloseModals(){
        this.showSelectPackageVersionsModal = false;
        this.showAuthenticationModal = false;
    }

    /*
        handleOndragstart
        Takes the details of the current item and column being dragged and adds it to 
        the dataTransfer 
    */
    handleOndragstart(event) {
        const dataTransfer = JSON.stringify({id: event.target.dataset.id, column: event.target.dataset.column});
        event.dataTransfer.setData("text/plain", dataTransfer);
    }

    /*
        handleOndragover
        Stop default dragover functionality. Without this, the items
        will return to their previous position ondrop
    */
    handleOndragover(event) {
        this.columns[this.getColumnIndexById(event.target.dataset.column)].style = this.highlightedColumn;
        event.preventDefault();
    }

    /*
        handleOndragenter
        Make the dragged over object slightly see-through
        when we drag over it
    */
    handleOndragenter(event) {
        //console.log('handleOndragenter');
    }

    /*
        handleOndragleave
        Return the dragged over object's opacity to normal when
        we exit the dragover
    */
    handleOndragleave(event) {
        this.columns[this.getColumnIndexById(event.target.dataset.column)].style = this.unhighlightedColumn;
    }

    /*
        paintCanvasWithPackages
        Takes a list of Package Version IDs 
        Identifies which packages should be added to the canvas
        Identifies which packages should be removed from the canvas
        Makes changes to columns object to remove manifest packages from canvas
        Calls to Apex to create new manifest packages for each package version
        Resets the allPackages property to reflect latest changes
    */
    paintCanvasWithPackages(event){
        console.log('0');
        var newPackages = event.detail.filter(x => this.allPackages.indexOf(x) === -1 );
        var removedPackages = this.allPackages.filter(x => event.detail.indexOf(x) === -1);

        removedPackages.forEach(pkg => {
            this.columns.forEach(col => {
                var index = this.getItemIndexByValue(pkg, col.items, 'version')
                if(index > -1){
                    col.items.splice(index, 1);
                }
            });
        });
        console.log('0.5');

        if(removedPackages && removedPackages.length > 0){
            this.deleteManifestPackages(removedPackages);
        }
        if(newPackages && newPackages.length > 0){
            this.createManifestPackages(newPackages );
        }
        console.log('0.7');
        this.allPackages = event.detail;
        this.handleCloseModals();
        console.log('1');
    }

    deleteManifestPackages(removedPackages){
        deleteManifestPackages({manifestId: this.manifestId, packageVersionIds: removedPackages})
        .then((result) => {
            console.log(result);
            this.allPackages = this.getFlattenedColumns().map(col => col.version);
            this.markDuplicatePackages();
            this.setItemOrdinals();
        })
        .catch((error) => {
            console.log(error);
        })
    }

    createManifestPackages(newPackages){
        createManifestPackages({ manifestId: this.manifestId, packageVersionIds: newPackages })
        .then((result) => {
            this.addItems(result);
            this.allPackages = this.getFlattenedColumns().map(col => col.version);
            this.markDuplicatePackages();
            this.setItemOrdinals();
        })
        .catch((error) => {
            console.log(error);
        });
    }

    handleSave(){
        var manifestPackagesWithColumn = []
        var allPackages = this.getFlattenedColumns();
        allPackages.forEach(pack => {
            manifestPackagesWithColumn.push({
                Id: pack.id,
                aprv__Column_Number__c: pack.columnIndex,
                aprv__Ordinal__c: pack.ordinal
            })});
        saveManifestPackages({manifestPackages: manifestPackagesWithColumn})
        .then((result) => {
            if(result == true){
                this.setSaved();
            }
        })
        .catch((error) => {
            console.log(error);
        });
    }

    /*
        addColumn
        Adds a new row to the column object
    */
    addColumn(){
        var columnId = this.columns.length + 1;
        this.columns.push({id: columnId, style: this.unhighlightedColumn, items: []});
    }

    /*
        addItem
        Takes a list of a manifest packages and adds them
        to the first column of the column object.
    */
    addItems(manifestPackages){
        manifestPackages.forEach(element => {
            if(element.aprv__Column_Number__c	){
                var thisColIndex = element.aprv__Column_Number__c	;
            }else{
                var thisColIndex = 0;
            }

            while(thisColIndex > this.columns.length -1){
                this.addColumn();
            }

            this.columns[thisColIndex].items.push({id: element.Id, 
                                        version: element.aprv__Package_Version__c, 
                                        packageId: element.aprv__Package_Id__c,
                                        columnIndex: thisColIndex,
                                        ordinal: element.aprv__Ordinal__c,
                                        duplicate: false})
        });
    }

    /*
        getFlattenedColumns
        Gets all of the package information across all columns
        from the items property and returns all items as one 
        big array of items (package information)
    */
    getFlattenedColumns(){
        var flattenedColumns = [];
        var itemsArray = this.columns.map(col => col.items);
        itemsArray.forEach(column => {
            flattenedColumns = flattenedColumns.concat(column);
        });
        return flattenedColumns;
    }

    /*
        resetDuplicatePackages
        Sets the duplicate property of all manifest package items to false
    */
    resetDuplicatePackages(){
        this.getFlattenedColumns().forEach(flatPackage => {
            this.columns[flatPackage.columnIndex].items[this.getItemIndexByValue(flatPackage.id, this.columns[flatPackage.columnIndex].items, 'id')].duplicate = false;
        })
        this.duplicatePackages = false;
    }

    /*
        markDuplicatePackages
        Loops through every manifest package item in the columns array
        Determines whether there are any other manifest package items on the canvas
        which look up to the same package. If there are, marks the duplicate property
        for that item as true
    */
    markDuplicatePackages(){
        this.resetDuplicatePackages();
        var flattenedColumns = this.getFlattenedColumns();
        flattenedColumns.forEach(packageToFind => {
            var dupeFilter = {packageId: packageToFind.packageId, id: packageToFind.id, column: packageToFind.columnIndex};
            flattenedColumns.filter(packageToCompare => {
                if(packageToCompare.id != dupeFilter.id){
                    if(packageToCompare.packageId == dupeFilter.packageId){
                        this.columns[packageToCompare.columnIndex].items[this.getItemIndexByValue(packageToCompare.id, this.columns[packageToCompare.columnIndex].items, 'id')].duplicate = true;
                        this.columns[dupeFilter.column].items[this.getItemIndexByValue(dupeFilter.id, this.columns[dupeFilter.column].items, 'id')].duplicate = true;
                        this.duplicatePackages = true;
                    }
                }
            });
        });
    }

    /*
        getColumnIndexById    
        Takes an Id of an item in the columns and returns it's position
        in the array
    */
    getColumnIndexById(id){
        var idFilter = (element) => element.id == id;
        return this.columns.findIndex(idFilter);
    }

    /*
        getItemIndexByValue
        Takes an Id, an array and a property and 
        finds the index of the item in the given array 
        based on matching the property value for this element
        and the value of id. 
        Returns the index of the matching item in the array
    */
    getItemIndexByValue(id, obj, property){
        var idFilter = (element) => element[property] == id;
        return obj.findIndex(idFilter);
    }

    /*
        handleOndrop
        Handles the moving of a package between columns (or within the same column)
        Takes the values of the dataTransfer provided in the handleOndragstart function
        Removes the item from the dragged column, adds the item to the target column 
        Shifts the other elements in that column accordingly, depending on where the item
        was dropped
    */
    handleOndrop(event) {
        this.columns[this.getColumnIndexById(event.target.dataset.column)].style = this.unhighlightedColumn;


        const dataTransfer = JSON.parse(event.dataTransfer.getData('text/plain'));
        const {id: startId, column: startColumn} = dataTransfer;
        const {id: endId, column: endColumn} = event.target.dataset;

        var startColIndex = this.getColumnIndexById(startColumn);
        var endColIndex = this.getColumnIndexById(endColumn);

        var targetItemIndexInColumn = this.getItemIndexByValue(endId, this.columns[endColIndex].items, 'id');
        var itemIndexInColumn = this.getItemIndexByValue(startId, this.columns[startColIndex].items, 'id');
        var itemObject = this.columns[startColIndex].items[itemIndexInColumn];

        //Functionally, this doesn't matter, but from a UI perspective it looks nicer if dropping an item into empty column 
        //space goes at the end of the column, rather than being shoved into the top
        itemObject.columnIndex = endColIndex;
        if(targetItemIndexInColumn < 0){
            targetItemIndexInColumn = this.columns[endColIndex].items.length;
        }
        //Add the item to the new column
        this.columns[endColIndex].items.splice(targetItemIndexInColumn +1, 0, itemObject);
        //Remove the item from the previous column 
        if(startColIndex == endColIndex && targetItemIndexInColumn < itemIndexInColumn){
            //If we're in the same same column and the target item is beneath the item to be dropped we will have already spliced the 
            //item below it in the list and therefore the indexes will all have shifted down compared to where the dragged item now sits
            this.columns[startColIndex].items.splice(itemIndexInColumn + 1, 1, )
        }else{
            //This would remove the item in the list before it, if applied when moving in the same column
            this.columns[startColIndex].items.splice(itemIndexInColumn, 1);
        }
        this.setItemOrdinals();
        this.setNotSaved();
    }


    /*
        setItemOrdinals
        Loops through all of the manifest packages currently on screen
        and sets their ordinal in accordance with their position.
    */
    setItemOrdinals(){
        console.log('2');
        var flattenedColumns = this.getFlattenedColumns();
        console.log(flattenedColumns);
        console.log('3');
        this.columns.forEach(col => {
            col.items.forEach(item => {
                item.ordinal = this.getItemIndexByValue(item.id, flattenedColumns, 'id');
            })
        });
        console.log('4');
    }
    setNotSaved(){
        this.saveStyle = 'destructive';
        this.saveText = 'Save*';
    }

    setSaved(){
        this.saveStyle = 'brand';
        this.saveText = 'Save';
    }
}