public with sharing class ManifestCanvasUtils {

    @AuraEnabled(cacheable=false)
    public static List<sfLma__Package_Version__c> getAllPackageVersions(){
        try {
            return [SELECT ID, Name, sfLma__Package__r.Name, CreatedDate FROM sfLma__Package_Version__c ORDER By CreatedDate DESC ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<aprv__Manifest__c> getManifests(String searchTerm){
        try {
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm.trim()) +'%';
            String query = 'SELECT ID, Name, aprv__Description__c, aprv__Trialforce_Template__c, aprv__Trialforce_Template__r.Name, CreatedDate FROM aprv__Manifest__c WHERE Name Like \'' + searchTerm + '\' Limit 5';
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static boolean saveManifestPackages(List<aprv__Manifest_Package__c> manifestPackages){
        System.debug(manifestPackages);
        try {
            List<Database.SaveResult> sr = Database.update(manifestPackages);
            boolean success = true;
            for(Database.SaveResult s : sr){
                if(!s.isSuccess()){
                    success = false;
                }
            }
            return success;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /*
        createManifestPackage
        Takes a manifest ID and a list of package version IDs.
        Checks whether this package version has previously been added to this manifest
        If not, creates a new manifest version and adds to list
        upserts new and existing records and returns them
        Called by the canvas component when a manifest package is added to the selected package list
    */
    @AuraEnabled
    public static List<aprv__Manifest_Package__c> createManifestPackages(Id manifestId, List<Id> packageVersionIds){
        List<aprv__Manifest_Package__c> manifestPackages = new List<aprv__Manifest_Package__c>();
        try {
            List<aprv__Manifest_Package__c> existingManifestPackages = [SELECT id, aprv__Column_Number__c, aprv__Manifest__c, aprv__Package_Version__c, aprv__Package_Id__c, aprv__Ordinal__c FROM aprv__Manifest_Package__c WHERE aprv__Manifest__c =: manifestId];
            //If there are no new manifest packages to create, then just return all the existing ones
            if(packageVersionIds == null || packageVersionIds.size() == 0){
                System.debug(existingManifestPackages);
                return existingManifestPackages;
            }else{
                Map<id, aprv__Manifest_Package__c> existingPackagesByVersionId = new Map<id, aprv__Manifest_Package__c>();
                for(aprv__Manifest_Package__c mp : existingManifestPackages){
                    existingPackagesByVersionId.put(mp.aprv__Package_Version__c, mp);
                }

                List<sfLma__Package_Version__c> packageVersions = [SELECT sfLma__Package__c FROM sfLma__Package_Version__c WHERE Id IN: packageVersionIds];
                Map<Id, Id> packageMap = new Map<Id, Id>();
                for(sfLma__Package_Version__c version: packageVersions)
                {
                    packageMap.put(version.Id, version.sfLma__Package__c);
                }


                //Only create a new manifest package if we haven't already associated this package version with the manifest, otherwise use the existing manifest package
                //2 manifest packages within the same manifest cannot share the same ordinal, so we need to increase this with each package version we add.
                Integer numNewManifestPackages = 0;
                if(packageVersionIds != null){
                    for(Id pvi : packageVersionIds){

                        if(existingPackagesByVersionId.get(pvi) != null){
                            manifestPackages.add(existingPackagesByVersionId.get(pvi));
                        }else{
                            aprv__Manifest_Package__c mp = new aprv__Manifest_Package__c(aprv__Manifest__c = manifestId, aprv__Package_Version__c=pvi, aprv__Package__c = packageMap.get(pvi), aprv__Column_Number__c =0, aprv__Ordinal__c=numNewManifestPackages);
                            manifestPackages.add(mp);
                            numNewManifestPackages++;
                        }
                    }
                }

                //Once we've added new manifest packages, we need to increase the ordinal of those already in the manifest
                for(Manifest_Package__c mp: existingManifestPackages){
                    mp.aprv__Ordinal__c += numNewManifestPackages;
                }

                database.upsert(manifestPackages);
                //Query them out again to get the formula field value
                manifestPackages = [SELECT id, aprv__Column_Number__c, aprv__Manifest__c, aprv__Package_Version__c, aprv__Package_Id__c, aprv__Ordinal__c FROM aprv__Manifest_Package__c WHERE Id IN: manifestPackages];
                return manifestPackages;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
        deleteManifestPackages
        Takes a manifest ID and a list of package version IDs
        Queries for all manifest packages in that manifest for those package versions and deletes them.
        Called by the canvas component when a manifest package is removed from the selected package list
    */
    @AuraEnabled
    public static boolean deleteManifestPackages(Id manifestId, List<Id> packageVersionIds){
        try {
            List<aprv__Manifest_Package__c> manifestPackagesForDeletion = [SELECT id, aprv__Manifest__c, aprv__Package_Version__c FROM aprv__Manifest_Package__c WHERE aprv__Manifest__c =: manifestId AND aprv__Package_Version__c IN: packageVersionIds];
            List<Database.DeleteResult> sr = database.delete(manifestPackagesForDeletion);
            boolean success = true;
            for(Database.DeleteResult s : sr){
                if(!s.isSuccess()){
                    success = false;
                }
            }
            return success;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
