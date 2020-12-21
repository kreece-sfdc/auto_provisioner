public with sharing class ToolingApiHelper 
{
    public static string createPackageInstallRequest(Provisioning_Request_Package__c provisioningRequestPackage, Subscriber_Authentication__c authRecord)
    {
        string url = authRecord.Instance__c + '/services/data/v49.0/tooling/sobjects/PackageInstallRequest';

        Map<string, object> dataMap = new Map<string, object>();
        dataMap.put('SubscriberPackageVersionKey', provisioningRequestPackage.Package_Version_Id__c);
        dataMap.put('SecurityType', 'None');
        dataMap.put('NameConflictResolution', 'Block');

        if(!string.isBlank(provisioningRequestPackage.Package_Version_Password__c))
        {
            dataMap.put('Password', provisioningRequestPackage.Package_Version_Password__c);
        }

        string body = JSON.serialize(dataMap);

        HttpRequest request = createApiRequest(url, 'POST', body, authRecord.Access__c);

        string response = sendApiRequest(request);

        system.debug(response);

        return response;
    }

    public static string createPackageInstallStatusRequest(Provisioning_Request_Package__c provisioningRequestPackage, Subscriber_Authentication__c authRecord)
    {
        string url = authRecord.Instance__c + '/services/data/v49.0/tooling/sobjects/PackageInstallRequest/' + provisioningRequestPackage.Job_Id__c;

        HttpRequest request = createApiRequest(url, 'GET', null, authRecord.Access__c);

        string response = sendApiRequest(request);

        system.debug(response);

        return response;
    }

    public static string createUserInfoRequest(Subscriber_Authentication__c authRecord)
    {
        string url = 'https://login.salesforce.com/services/oauth2/userinfo';

        HttpRequest request = createApiRequest(url, 'GET', null, authRecord.Access__c);

        string response = sendApiRequest(request);

        system.debug(response);

        return response;
    }

    public static HttpRequest createApiRequest(string url, string method, string body, string access_token)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + access_token);

        if(body != null)
        {
            request.setBody(body);
        }

        return request;
    }

    public static string sendApiRequest(HttpRequest request)
    {
        try 
        {
            Http http = new Http();
            HttpResponse response = http.send(request);
            string responseString = response.getBody();

            return responseString;

        } 
        catch (Exception ex)
        {
            return ex.getMessage();
        }
    }

    public static ApiResponse performUserInfoRequest(Subscriber_Authentication__c authRecord)
    {
        ApiResponse apiResponse = new ApiResponse();

        Map<string, object> responseMap = new Map<string, object>();
        boolean accessTokenRefreshed;
        string response = createUserInfoRequest(authRecord);

        if(response == 'Bad_OAuth_Token')
        {
            authRecord = AuthHelper.refreshAccessToken(authRecord, true);

            response = createUserInfoRequest(authRecord);

            if(response != 'Bad_OAuth_Token')
            {
                accessTokenRefreshed = true;
            }
        }

        if(response != 'Bad_OAuth_Token')
        {
            responseMap = MapHelper.convertToMap(response);  
        }

        if(accessTokenRefreshed == true)
        {
            AuthHelper.refreshAccessToken(authRecord, false);
        }

        return parseUserInfoResponse(authRecord, responseMap);
    }

    public static ApiResponse parseUserInfoResponse(Subscriber_Authentication__c authRecord, Map<string, object> responseMap)
    {
        ApiResponse response = new ApiResponse();

        if(responseMap.containsKey('user_id'))
        {
            response.Message = 'The userinfo request has succeeded';
            response.Status = 'success';
        }
        else
        {
            response.Message = 'The userinfo request has failed';
            response.Status = 'error';
        }
        
        return response;
    }

    public static ApiResponse performPackageInstallRequest(Provisioning_Request_Package__c provisioningRequestPackage, Subscriber_Authentication__c authRecord)
    { 
        Map<string, object> responseMap = MapHelper.convertToMap(ToolingApiHelper.createPackageInstallRequest(provisioningRequestPackage, authRecord));
        boolean accessTokenRefreshed;

        if(responseMap.containsKey('errorCode') && responseMap.get('errorCode') == 'INVALID_SESSION_ID')
        {
            authRecord = AuthHelper.refreshAccessToken(authRecord, true);
            accessTokenRefreshed = true;

            responseMap = MapHelper.convertToMap(ToolingApiHelper.createPackageInstallRequest(provisioningRequestPackage, authRecord));
        }

        if(accessTokenRefreshed == true)
        {
            AuthHelper.refreshAccessToken(authRecord, false);
        }

        return parsePackageInstallResponse(provisioningRequestPackage, authRecord, responseMap);
    }

    public static ApiResponse parsePackageInstallResponse(Provisioning_Request_Package__c provisioningRequestPackage, Subscriber_Authentication__c authRecord, Map<string, object> responseMap)
    {
        ApiResponse response = new ApiResponse();

        if(responseMap.containsKey('success') && responseMap.get('success') == true &&
            responseMap.containsKey('id'))
        {
            response.Message = 'The package install request was successful';
            response.Id = responseMap.get('id').toString();
            response.Status = 'success';
        }
        else if(responseMap.containsKey('errorCode') && responseMap.containsKey('message'))
        {
            response.Status = 'error';
            response.Message = responseMap.get('message').toString();
        }
        
        return response;
    }



    public static ApiResponse performPackageInstallStatusRequest(Provisioning_Request_Package__c provisioningRequestPackage, Subscriber_Authentication__c authRecord)
    { 
        Map<string, object> responseMap = MapHelper.convertToMap(ToolingApiHelper.createPackageInstallStatusRequest(provisioningRequestPackage, authRecord));
        boolean accessTokenRefreshed;

        if(responseMap.containsKey('errorCode') && responseMap.get('errorCode') == 'INVALID_SESSION_ID')
        {
            authRecord = AuthHelper.refreshAccessToken(authRecord, true);
            accessTokenRefreshed = true;

            responseMap = MapHelper.convertToMap(ToolingApiHelper.createPackageInstallStatusRequest(provisioningRequestPackage, authRecord));
        }

        if(accessTokenRefreshed == true)
        {
            AuthHelper.refreshAccessToken(authRecord, false);
        }

        return parsePackageInstallStatusResponse(provisioningRequestPackage, authRecord, responseMap);
    }

    public static ApiResponse parsePackageInstallStatusResponse(Provisioning_Request_Package__c provisioningRequestPackage, Subscriber_Authentication__c authRecord, Map<string, object> responseMap)
    {
        ApiResponse response = new ApiResponse();

        if(responseMap.containsKey('Status'))
        {
            string status = responseMap.get('Status').toString();

            if(status == 'IN_PROGRESS')
            {
                response.Message = 'The package install is in progress';
                response.Status = 'in progress';
            }
            else if(status == 'ERROR')
            {
                response.Message = 'The package install has failed';
                response.Status = 'error';
            }
            else if(status == 'SUCCESS')
            {
                response.Message = 'The package install has succeeded';
                response.Status = 'success';
            }
            else 
            {
                response.Message = 'The package install status is unknown';
                response.Status = 'unknown';
            }
        }

        if(responseMap.containsKey('Errors'))
        {
            Map<string, object> errorsMap = MapHelper.convertToMap(responseMap.get('Errors'));

            if(errorsMap != null && errorsMap.containsKey('errors'))
            {
                errorsMap = MapHelper.convertToMap(errorsMap.get('errors'));

                if(errorsMap.containsKey('message'))
                {
                    response.Message = errorsMap.get('message').toString();
                }
            }
        }
        
        return response;
    }
}