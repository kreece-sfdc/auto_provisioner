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

        system.debug(provisioningRequest);

        if(string.isNotEmpty(manifestId))
        {
            List<Manifest__c> manifests = [SELECT Id, Name, Trialforce_Template__r.Trialforce_Template_Id__c, (SELECT Ordinal__c, Package_Version__r.sfLma__Version_ID__c, Package_Version__r.Package_Version_Password__c, Package_Version__r.sfLma__Package__r.Namespace__c FROM Manifest_Packages__r) FROM Manifest__c WHERE Id =: manifestId];

            if(!manifests.isEmpty())
            {
                Manifest__c manifest = manifests.get(0);

                if(manifest.Trialforce_Template__r != null && manifest.Trialforce_Template__r.Trialforce_Template_Id__c != null)
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

    public static boolean CreateOrgSignupRequest(Provisioning_Request__c provisioningRequest)
    {
        system.debug(provisioningRequest);
        string client_id = AuthHelper.CLIENTID;
        string client_secret = AuthHelper.CLIENTSECRET;
        string callback_url = AuthHelper.REDIRECTURLPRODUCTION;


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
            if(isPBO())
            {
                Type objType = Type.forName('SignupRequest');

                sObject signupRequest = (sObject)JSON.deserialize(JSON.serialize(dataMap), objType);

                if(!Test.isRunningTest())
                {
                    database.insert(signupRequest);

                    provisioningRequest.Status__c = 'In Progress';
                    provisioningRequest.SignupRequest_Id__c = signupRequest.Id;
                }
            }
            else 
            {
                provisioningRequest.Notes__c = 'This is not a PBO therefore there is no signup request to create.';
            }

            return true;
        } 
        catch (Exception ex) 
        {
            // this is an org where SignupRequest does not exist
            provisioningRequest.Notes__c = ex.getMessage();
            provisioningRequest.Status__c = 'Failed';

            return false;
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
                    picklistSet.add(new CustomPicklist(pickListValue.label, pickListValue.value));
                }
            }
        }
    
        return picklistSet;
    }

    @AuraEnabled
    public static ComponentResponse checkPackageInstall(string record_id)
    {
        ComponentResponse componentResponse = new ComponentResponse();
        Provisioning_Request_Package__c provisioningRequestPackage;
        Subscriber_Authentication__c authRecord;


        List<Provisioning_Request_Package__c> provisioningRequestPackages = [SELECT Package_Version_Id__c, Package_Version_Password__c, Provisioning_Request__r.Org_Id__c, Job_Id__c FROM Provisioning_Request_Package__c WHERE Id =: record_id];

        if(!provisioningRequestPackages.isEmpty())
        {
            provisioningRequestPackage = provisioningRequestPackages[0];

            List<Subscriber_Authentication__c> authRecords = [SELECT Access__c, Instance__c, Refresh__c, Org_Id__c, User__c, IsSandbox__c FROM Subscriber_Authentication__c WHERE Org_Id__c =: provisioningRequestPackage.Provisioning_Request__r.Org_Id__c];

            if(!authRecords.isEmpty())
            {
                authRecord = authRecords[0];

                ApiResponse response = ToolingApiHelper.performPackageInstallStatusRequest(provisioningRequestPackage, authRecord);

                if(response.Status == 'error')
                {
                    componentResponse.MessageType = 'error';
                    componentResponse.Message = 'The package install has failed.';

                    provisioningRequestPackage.Status__c = 'Failed';
                    
                }
                else if(response.Status == 'success')
                {
                    componentResponse.MessageType = 'success';
                    componentResponse.Message = 'The package install has succeeded.';

                    provisioningRequestPackage.Status__c = 'Succeeded';
                }
                else if(response.Status == 'in progress')
                {
                    componentResponse.MessageType = 'info';
                    componentResponse.Message = 'The package install is in progress.';

                    provisioningRequestPackage.Status__c = 'In Progress';
                }
                else if(response.Status == 'unknown')
                {
                    componentResponse.MessageType = 'warning';
                    componentResponse.Message = 'The package install status is unknown.';

                    provisioningRequestPackage.Status__c = 'In Progress';
                }

                provisioningRequestPackage.Notes__c = response.Message;

                upsert provisioningRequestPackage;
            }
            else 
            {
                componentResponse.Message = 'There are no authentication credentials available for this org';
                componentResponse.MessageType = 'error';
            }
        }
        else 
        {
            componentResponse.Message = 'There are no provisioning packages found';
            componentResponse.MessageType = 'error';
        }

        return componentResponse;
    }

    @AuraEnabled
    public static ComponentResponse InstallPackage(string record_id)
    {
        ComponentResponse componentResponse = new ComponentResponse();
        Provisioning_Request_Package__c provisioningRequestPackage;
        Subscriber_Authentication__c authRecord;


        List<Provisioning_Request_Package__c> provisioningRequestPackages = [SELECT Package_Version_Id__c, Package_Version_Password__c, Provisioning_Request__r.Org_Id__c, Job_Id__c FROM Provisioning_Request_Package__c WHERE Id =: record_id];

        if(!provisioningRequestPackages.isEmpty())
        {
            provisioningRequestPackage = provisioningRequestPackages[0];

            List<Subscriber_Authentication__c> authRecords = [SELECT Access__c, Instance__c, Refresh__c, Org_Id__c, User__c, IsSandbox__c FROM Subscriber_Authentication__c WHERE Org_Id__c =: provisioningRequestPackage.Provisioning_Request__r.Org_Id__c];

            if(!authRecords.isEmpty())
            {
                authRecord = authRecords[0];

                ApiResponse response = ToolingApiHelper.performPackageInstallRequest(provisioningRequestPackage, authRecord);

                if(response.Status == 'error')
                {
                    componentResponse.MessageType = 'error';
                    componentResponse.Message = 'The package installation request has failed.';

                    provisioningRequestPackage.Status__c = 'Failed';
                    
                }
                else if(response.Status == 'success')
                {
                    componentResponse.MessageType = 'success';
                    componentResponse.Message = 'The package installation request has succeeded.';
                    provisioningRequestPackage.Job_Id__c = response.Id;

                    provisioningRequestPackage.Status__c = 'In Progress';
                }
                

                provisioningRequestPackage.Notes__c = response.Message;

                upsert provisioningRequestPackage;
            }
            else 
            {
                componentResponse.Message = 'There are no authentication credentials available for this org';
                componentResponse.MessageType = 'error';
            }
        }
        else 
        {
            componentResponse.Message = 'There are no provisioning packages found';
            componentResponse.MessageType = 'error';
        }

        return componentResponse;
    }

    @AuraEnabled
    public static ComponentResponse fetchUserInfo(string record_id)
    {
        ComponentResponse componentResponse = new ComponentResponse();
        Subscriber_Authentication__c authRecord;

        List<Subscriber_Authentication__c> authRecords = [SELECT Access__c, Instance__c, Refresh__c, Org_Id__c, User__c, IsSandbox__c FROM Subscriber_Authentication__c WHERE Id =: record_id];

        if(!authRecords.isEmpty())
        {
            authRecord = authRecords[0];

            ApiResponse response = ToolingApiHelper.performUserInfoRequest(authRecord);
            
            componentResponse.MessageType = response.Status;
            componentResponse.Message = response.Message;

            authRecord.Notes__c = response.Message;

            upsert authRecord;
        }
        else 
        {
            componentResponse.Message = 'There are no authentication credentials available for this org';
            componentResponse.MessageType = 'error';
        }

        return componentResponse;
    }

    public static Provisioning_Request__c GetNextProvisioningRequestToSignup()
    {
        List<Provisioning_Request__c> inProgressProvisioningRequests = [SELECT SignupRequest_Id__c, Status__c FROM Provisioning_Request__c WHERE Status__c = 'In Progress'];

        if(!inProgressProvisioningRequests.isEmpty())
        {
            throw new SignupInProgressException(inProgressProvisioningRequests.get(0));
        }

        List<Provisioning_Request__c> provisioningRequests = [SELECT Id, Name, Company__c, Country__c, FirstName__c, LastName__c, Notes__c, Org_Id__c, PreferredEdition__c, PreferredLanguage__c, SignupEmail__c, Status__c, Subdomain__c, TrialDays__c, Trialforce_Template_Id__c, Username__c, CreatedDate FROM Provisioning_Request__c WHERE Status__c = 'Not Started' AND Org_Id__c = '' ORDER BY CreatedDate ASC];

        if(!provisioningRequests.isEmpty())
        {
            return provisioningRequests.get(0);
        }
        
        return null;
    }

    static void UpdateInProgressSignup(Provisioning_Request__c provisioningRequest)
    {
        if(provisioningRequest != null && provisioningRequest.SignupRequest_Id__c != null)
        {
            string signupRequestId = provisioningRequest.SignupRequest_Id__c;

            string signupRequestQuery = 'SELECT AuthCode, ConnectedAppCallbackUrl, ConnectedAppConsumerKey, CreatedOrgId, ErrorCode, ResolvedTemplateId, Status FROM SignupRequest WHERE Id =: signupRequestId';

            if(isPBO())
            {
                List<sObject> results = Database.query(signupRequestQuery);

                if(!results.isEmpty())
                {
                    sObject result = results.get(0);

                    string status = result.get('Status').toString();
                    string errorCode = result.get('ErrorCode').toString();
                    string createdOrgId = result.get('CreatedOrgId').toString();
                    string authCode = result.get('AuthCode').toString();
                    string connectedAppConsumerKey = result.get('ConnectedAppConsumerKey').toString();
                    string connectedAppCallbackUrl = result.get('ConnectedAppCallbackUrl').toString();
                    
                    if(status == 'Success')
                    {
                        // now created a Subscriber Authentication record for this org.
                        boolean authResult = AuthHelper.fetchTokens(authCode, false, connectedAppConsumerKey, null, connectedAppCallbackUrl);

                        if(authResult == true)
                        {
                            provisioningRequest.Notes__c = 'The SignupRequest was successful, and the Org Credentials were successfully created.';
                        }
                        else 
                        {
                            provisioningRequest.Notes__c = 'The SignupRequest was successful, but the Org Credentials failed to create.';    
                        }

                        provisioningRequest.Status__c = 'Succeeded';
                        provisioningRequest.Org_Id__c = createdOrgId;
                    }
                    else if(status == 'Error')
                    {
                        provisioningRequest.Status__c = 'Failed';
                        provisioningRequest.Notes__c = errorCode;
                    }
                    else if(status == 'In Progress')
                    {
                        provisioningRequest.Status__c = 'In Progress';
                    }
                    else 
                    {
                        // unknown
                    }
                }
            }

            database.upsert(provisioningRequest);
        }
    }

    public static void SignupNextOrg()
    {
        try 
        {
            Provisioning_Request__c provisioningRequest = GetNextProvisioningRequestToSignup();

            if(provisioningRequest != null)
            {
                CreateOrgSignupRequest(provisioningRequest);
            }
        } 
        catch (SignupInProgressException ex) 
        {
            // Success, In Progress, Error
            // There is a signup in progress, and we could trigger off the SignupRequest object, but it doesn't exist anywhere
            // but in the PBO, so we need to query it based on the SignupRequest.Id, this is stored in the exception cause.

            system.debug(ex.getRecord());

            Provisioning_Request__c provisioningRequest = ex.getRecord();

            UpdateInProgressSignup(provisioningRequest);
        }
    }

    @AuraEnabled
    public static ComponentResponse SignupOrg(string record_id)
    {
        ComponentResponse resp = new ComponentResponse();

        List<Provisioning_Request__c> provisioningRequests = [SELECT Id, Name, Company__c, Country__c, FirstName__c, LastName__c, Notes__c, Org_Id__c, PreferredEdition__c, PreferredLanguage__c, SignupEmail__c, Status__c, Subdomain__c, TrialDays__c, Trialforce_Template_Id__c, Username__c, CreatedDate, SignupRequest_Id__c FROM Provisioning_Request__c WHERE Id =: record_id];

        if(!provisioningRequests.isEmpty())
        {
            Provisioning_Request__c provisioningRequest = provisioningRequests.get(0);

            boolean res = CreateOrgSignupRequest(provisioningRequest);

            if(!isPBO())
            {
                resp.MessageType = 'warning';
                resp.Message = 'This is not a PBO therefore there is no signup request to create';
            }
            else if(res == true)
            {
                resp.MessageType = 'success';
                resp.Message = 'The signup request succeeded';
            }
            else if(res == false)
            {
                resp.MessageType = 'error';
                resp.Message = 'The signup request failed';
            }
        
        }

        return resp;
    }

    @AuraEnabled
    public static ComponentResponse CheckOrgSignup(string record_id)
    {
        ComponentResponse resp = new ComponentResponse();

        List<Provisioning_Request__c> provisioningRequests = [SELECT Id, Name, Company__c, Country__c, FirstName__c, LastName__c, Notes__c, Org_Id__c, PreferredEdition__c, PreferredLanguage__c, SignupEmail__c, Status__c, Subdomain__c, TrialDays__c, Trialforce_Template_Id__c, Username__c, CreatedDate, SignupRequest_Id__c FROM Provisioning_Request__c WHERE Id =: record_id];

        if(!provisioningRequests.isEmpty())
        {
            Provisioning_Request__c provisioningRequest = provisioningRequests.get(0);

            if(provisioningRequest.SignupRequest_Id__c != null)
            {
                UpdateInProgressSignup(provisioningRequest);

                if(!isPBO())
                {
                    resp.MessageType = 'warning';
                    resp.Message = 'This is not a PBO therefore there is no signup request to check';
                }
                else if(provisioningRequest.Status__c == 'Succeeded')
                {
                    resp.MessageType = 'success';
                    resp.Message = 'The signup request successfully completed';
                }
                else if(provisioningRequest.Status__c == 'Failed')
                {
                    resp.MessageType = 'error';
                    resp.Message = 'The signup request failed';
                }
            }
        }

        return resp;
    }

    public static boolean isPBO()
    {
        Type objType = Type.forName('SignupRequest');

        return objType != null;
    }
}
