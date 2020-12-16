public with sharing class ToolingApiHelper 
{
    public static string createPackageInstallRequest(Subscriber_Authentication__c authRecord, Provisioning_Request_Package__c requestPackage)
    {
        string url = authRecord.Instance__c + '/services/data/v49.0/tooling/sobjects/PackageInstallRequest';

        Map<string, object> dataMap = new Map<string, object>();
        dataMap.put('SubscriberPackageVersionKey', requestPackage.Package_Version_Id__c);
        dataMap.put('SecurityType', 'Custom');
        dataMap.put('NameConflictResolution', 'Block');

        if(!string.isBlank(requestPackage.Package_Version_Password__c))
        {
            dataMap.put('Password', requestPackage.Package_Version_Password__c);
        }

        string body = JSON.serialize(dataMap);

        HttpRequest request = createApiRequest(url, 'POST', body, authRecord.Access__c);

        string response = sendApiRequest(request);

        return response;
    }

    public static string createPackageInstallStatusRequest(Subscriber_Authentication__c authRecord, Provisioning_Request_Package__c requestPackage)
    {
        string url = authRecord.Instance__c + '/services/data/v49.0/tooling/sobjects/PackageInstallRequest/' + requestPackage.Job_Id__c;

        HttpRequest request = createApiRequest(url, 'GET', null, authRecord.Access__c);

        string response = sendApiRequest(request);

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
}

/*{
"SubscriberPackageVersionKey": "04t4J000000FPjXQAW",
"SecurityType": "Custom",
"NameConflictResolution": "Block"
}*/