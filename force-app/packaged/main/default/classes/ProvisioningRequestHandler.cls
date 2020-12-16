public with sharing class ProvisioningRequestHandler
{
    public class ComponentResponse
    {
        @AuraEnabled
        public string Message { get; set; }
        @AuraEnabled
        public string MessageType { get; set; }
        @AuraEnabled
        public boolean ForceRefresh { get; set; }
    }

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

    @AuraEnabled
    public static ComponentResponse checkPackageInstall(string record_id)
    {
        ComponentResponse response = new ComponentResponse();
        Provisioning_Request_Package__c provisioningRequestPackage;
        Subscriber_Authentication__c authRecord;

        boolean refreshedTokens;

        List<Provisioning_Request_Package__c> provisioningRequestPackages = [SELECT Package_Version_Id__c, Package_Version_Password__c, Provisioning_Request__r.Org_Id__c, Job_Id__c FROM Provisioning_Request_Package__c WHERE Id =: record_id];

        if(!provisioningRequestPackages.isEmpty())
        {
            provisioningRequestPackage = provisioningRequestPackages[0];

            List<Subscriber_Authentication__c> authRecords = [SELECT Access__c, Instance__c, Refresh__c, Org_Id__c, User__c FROM Subscriber_Authentication__c WHERE Org_Id__c =: provisioningRequestPackage.Provisioning_Request__r.Org_Id__c];

            if(!authRecords.isEmpty())
            {
                authRecord = authRecords[0];

                try 
                {
                    Map<string, object> responseMap;

                    responseMap = convertToMap(ToolingApiHelper.createPackageInstallStatusRequest(authRecord, provisioningRequestPackage));

                    if(responseMap.containsKey('errorCode') && responseMap.get('errorCode') == 'INVALID_SESSION_ID')
                    {
                        authRecord = AuthHelper.refreshAccessToken(authRecord, true);
                        refreshedTokens = true;

                        responseMap = convertToMap(ToolingApiHelper.createPackageInstallStatusRequest(authRecord, provisioningRequestPackage));
                    }
                    
                    if(responseMap.containsKey('Status'))
                    {
                        string status = responseMap.get('Status').toString();

                        if(status == 'InProgress')
                        {
                            response.Message = 'The package install is in progress';
                            response.MessageType = 'info';
                        }
                        else if(status == 'Error')
                        {
                            response.Message = 'The package install has failed';
                            response.MessageType = 'error';
                            response.ForceRefresh = true;
                        }
                        else if(status == 'Success')
                        {
                            response.Message = 'The package install has succeeded';
                            response.MessageType = 'success';
                            response.ForceRefresh = true;
                        }
                        else 
                        {
                            response.Message = 'The package install status is unknown';
                            response.MessageType = 'warning';
                        }
                    }
                }
                catch (Exception ex)
                {
                    response.Message = ex.getStackTraceString();
                    response.Message += '\r\n' + ex.getMessage();
                    response.MessageType = 'error';
                }
            }
        }

        if(refreshedTokens == true)
        {
            AuthHelper.refreshAccessToken(authRecord, false);
        }

        if(response.MessageType == 'error')
        {
            provisioningRequestPackage.Status__c = 'Failed';
            
        }
        else if(response.MessageType == 'success')
        {
            provisioningRequestPackage.Status__c = 'Succeeded';
        }

        provisioningRequestPackage.Notes__c = response.Message;
        upsert provisioningRequestPackage;

        return response;
    }

    @AuraEnabled
    public static ComponentResponse InstallPackage(string record_id)
    {
        ComponentResponse response = new ComponentResponse();
        Provisioning_Request_Package__c provisioningRequestPackage;
        Subscriber_Authentication__c authRecord;

        boolean refreshedTokens;
        
        List<Provisioning_Request_Package__c> provisioningRequestPackages = [SELECT Package_Version_Id__c, Package_Version_Password__c, Provisioning_Request__r.Org_Id__c FROM Provisioning_Request_Package__c WHERE Id =: record_id];

        if(!provisioningRequestPackages.isEmpty())
        {
            provisioningRequestPackage = provisioningRequestPackages[0];

            List<Subscriber_Authentication__c> authRecords = [SELECT Access__c, Instance__c, Refresh__c, Org_Id__c, User__c FROM Subscriber_Authentication__c WHERE Org_Id__c =: provisioningRequestPackage.Provisioning_Request__r.Org_Id__c];

            if(!authRecords.isEmpty())
            {
                authRecord = authRecords[0];

                try 
                {
                    Map<string, object> responseMap;

                    responseMap = convertToMap(ToolingApiHelper.createPackageInstallRequest(authRecord, provisioningRequestPackage));

                    if(responseMap.containsKey('errorCode') && responseMap.get('errorCode') == 'INVALID_SESSION_ID')
                    {
                        authRecord = AuthHelper.refreshAccessToken(authRecord, true);
                        refreshedTokens = true;

                        responseMap = convertToMap(ToolingApiHelper.createPackageInstallRequest(authRecord, provisioningRequestPackage));
                    }

                    if(responseMap.containsKey('success') && responseMap.get('success') == true &&
                        responseMap.containsKey('id'))
                    {
                        provisioningRequestPackage.Job_Id__c = responseMap.get('id').toString();

                        response.Message = 'Successful request!';
                        response.MessageType = 'success';
                        response.ForceRefresh = true;
                    }

                }
                catch (Exception ex)
                {
                    response.Message = ex.getStackTraceString();
                    response.MessageType = 'error';
                }
            }
            else 
            {
                response.Message = 'There are no authentication credentials available for this org';
                response.MessageType = 'error';
            }
        }
        else 
        {
            response.Message = 'There are no provisioning packages found';
            response.MessageType = 'error';
        }

        // needs to be done here so there are no uncommitted changes before a callout.
        if(refreshedTokens == true)
        {
            AuthHelper.refreshAccessToken(authRecord, false);
        }

        if(response.MessageType == 'error')
        {
            provisioningRequestPackage.Status__c = 'Failed';
            
        }
        else if(response.MessageType == 'success')
        {
            provisioningRequestPackage.Status__c = 'In Progress';
        }

        provisioningRequestPackage.Notes__c = response.Message;
        upsert provisioningRequestPackage;

        return response;
        
    }

    static Map<string, object> convertToMap(string response)
    {
        system.debug(response);

        if(response.startsWith('['))
        {
            List<object> responseListMap = convertToListMap(response);
            return convertToMap(responseListMap[0]);
        }

        return (Map<string, object>)JSON.deserializeUntyped(response);
    }

    static Map<string, object> convertToMap(object response)
    {
        return (Map<string, object>)JSON.deserializeUntyped(JSON.serialize(response));
    }

    static List<object> convertToListMap(string response)
    {
        return (List<object>)JSON.deserializeUntyped(response);
    }

    @AuraEnabled(cacheable=true)
    public static ComponentResponse fetchUserInfo(string access_token)
    {
        ComponentResponse response = new ComponentResponse();

        string userInfoUrl = 'https://login.salesforce.com/services/oauth2/userinfo';
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(userInfoUrl);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + access_token);

        Http http = new Http();
        HttpResponse httpresponse = http.send(request);
        
        Map<string, object> responseMap = convertToMap(httpresponse.getBody());

        if(responseMap.containsKey('user_id'))
        {
            response.Message = 'Authentication Details are currently valid';
            response.MessageType = 'success';
        }
        else
        {
            response.Message = 'Authentication Details are currently invalid';
            response.MessageType = 'error';
        }
        
        return response;
    }
}
