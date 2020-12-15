public with sharing class ProvisioningRequestHandler
{
    @InvocableMethod(label='Create Provisioning Request')
    public static void CreateProvisioningRequest(List<ProvisioningRequest> requests)
    {
        ProvisioningRequest request = requests[0];
        // need to bulkify

        CreateProvisioningRequest(request.manifestId, request.company, request.country, request.firstname, request.lastname, request.notes, request.edition, request.language, request.email, request.subdomain, request.trialdays, request.username);
    }

    public static void CreateProvisioningRequest(string manifestId, string company, string country, string firstname, string lastname, string notes, string edition, string language, string email, string subdomain, integer trialdays, string username)
    {
        Provisioning_Request__c provisioningRequest = new Provisioning_Request__c
        (
            Company__c = company,
            Country__c = country,
            FirstName__c = firstname,
            LastName__c = lastname,
            Notes__c = notes,
            PreferredEdition__c = edition,
            PreferredLanguage__c = language,
            SignupEmail__c = email,
            Subdomain__c = subdomain,
            TrialDays__c = trialdays,
            Username__c = username
        );

        if(string.isNotEmpty(manifestId))
        {
            List<Manifest__c> manifests = [SELECT Id, Name, Trialforce_Template__r.Trialforce_Template_Id__c, (SELECT Ordinal__c, Package_Version__r.sfLma__Version_ID__c, Package_Version__r.Package_Version_Password__c, Package_Version__r.sfLma__Package__r.Namespace__c FROM Manifest_Packages__r) FROM Manifest__c WHERE Id =: manifestId];

            if(!manifests.isEmpty())
            {
                Manifest__c manifest = manifests.get(0);

                if(manifest.Trialforce_Template__r != null)
                {
                    provisioningRequest.Trialforce_Template_Id__c = manifest.Trialforce_Template__r.Trialforce_Template_Id__c;
                    provisioningRequest.PreferredEdition__c = null;
                }

                database.insert(provisioningRequest, true);

                List<Provisioning_Request_Package__c> provisioningRequestPackages = new List<Provisioning_Request_Package__c>();

                for(Manifest_Package__c manifestPackage : manifest.Manifest_Packages__r)
                {
                    Provisioning_Request_Package__c provisioningRequestPackage = new Provisioning_Request_Package__c
                    (
                        Namespace__c = manifestPackage.Package_Version__r.sfLma__Package__r.Namespace__c,
                        Ordinal__c = manifestPackage.Ordinal__c,
                        Package_Version_Id__c = manifestPackage.Package_Version__r.sfLma__Version_ID__c,
                        Package_Version_Password__c = manifestPackage.Package_Version__r.Package_Version_Password__c,
                        Provisioning_Request__c = provisioningRequest.Id
                    );

                    provisioningRequestPackages.add(provisioningRequestPackage);
                }

                
                database.insert(provisioningRequestPackages, true);
            }
        }
    }

    public static void CreateOrgSignupRequest(Provisioning_Request__c provisioningRequest)
    {
        string client_id = AuthHelper.CLIENTID;
        string client_secret = AuthHelper.CLIENTSECRET;
        string callback_url = AuthHelper.REDIRECTURL;


        Map<string, object> dataMap = new Map<string, object>();
        dataMap.put('Company', provisioningRequest.Company__c);
        dataMap.put('ShouldConnectToEnvHub', true);
        dataMap.put('Country', provisioningRequest.Country__c);
        dataMap.put('SignupEmail', provisioningRequest.SignupEmail__c);
        dataMap.put('FirstName', provisioningRequest.FirstName__c);
        dataMap.put('LastName', provisioningRequest.LastName__c);
        dataMap.put('Subdomain', provisioningRequest.Subdomain__c);
        dataMap.put('IsSignupEmailSuppressed', true);
        dataMap.put('TrialDays', provisioningRequest.TrialDays__c);
        dataMap.put('Username', provisioningRequest.Username__c);
        dataMap.put('PreferredLanguage', provisioningRequest.PreferredLanguage__c);

        if(provisioningRequest.Trialforce_Template_Id__c != null)
        {
            dataMap.put('TemplateId', provisioningRequest.Trialforce_Template_Id__c);
        }
        else 
        {
            dataMap.put('Edition', provisioningRequest.PreferredEdition__c);
        }

        dataMap.put('ConnectedAppCallbackUrl', callback_url);
        dataMap.put('ConnectedAppConsumerKey', client_id);


        try 
        {
            Type objType = Type.forName('SignupRequest');

            sObject signupRequest = (sObject)JSON.deserialize(JSON.serialize(dataMap), objType);

            if(!Test.isRunningTest())
            {
                insert signupRequest;

                provisioningRequest.Status__c = 'In Progress';
            }
        } 
        catch (Exception ex) 
        {
            // this is an org where SignupRequest does not exist
            provisioningRequest.Notes__c = ex.getMessage();
            provisioningRequest.Status__c = 'Failed';
        }
        finally
        {
            update provisioningRequest;
        }
    }

    public static List<CustomPicklist> getPickListValues(string objName, string fieldName)
    {
        List<CustomPicklist> picklistSet = new List<CustomPicklist>();
        CustomPicklist defaultOption = new CustomPicklist('Please select', '');

        Type objType = Type.forName(objName);

        if(objType != null)
        {
            sObject objInstance = (sObject)objType.newInstance();
            
            if(objInstance != null)
            {
                Schema.DescribeFieldResult fieldResult = objInstance.getsObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();
                
                for(Schema.PicklistEntry pickListValue: fieldResult.getPicklistValues())
                {
                    picklistSet.add(new CustomPicklist(pickListValue.value, pickListValue.label));
                }
            }
        }
    
        return picklistSet;
    }
}
