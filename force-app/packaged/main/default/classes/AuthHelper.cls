public with sharing class AuthHelper 
{
    public static string CLIENTID  = '3MVG9od6vNol.eBiHujuKURMTk0yi1iShepB1TVy_JU9A3ufTpsl63_pDDk2BKzHAF5ETYAUh3LHO3UX3XmCP';
    public static string CLIENTSECRET = 'FEEC700CDE23798D8C1D3B911807772E4BBF3CD7D57F3F83660B30D1BDB82E99';
    public static string REDIRECTURL = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/authHandler';
    public static string REDIRECTURLSANDBOX = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/authHandlerSandbox';
    
    public static boolean fetchTokensAll(string code, boolean isSandbox)
    {
        string tokenEndpoint;

        if(isSandbox == true) 
        {
            tokenEndpoint = 'https://test.salesforce.com/services/oauth2/token?';
        }
        else 
        {
            tokenEndpoint = 'https://login.salesforce.com/services/oauth2/token?';
        }
        
        string client_id = '';
        string client_secret = '';
            
        List<string> params = new List<string>();
        params.add('grant_type=' + 'authorization_code');
        params.add('client_id=' + CLIENTID);
        params.add('client_secret=' + CLIENTSECRET);
        params.add('redirect_uri=' + REDIRECTURL);
        params.add('code=' + code);
        
        string authHeader = EncodingUtil.base64Encode(Blob.valueOf(client_id + ':' + client_secret));
        
        tokenEndpoint += string.join(params, '&');

        HttpRequest request = new HttpRequest();
        request.setEndpoint(tokenEndpoint);
        request.setHeader('Authorization', 'Basic ' + authHeader);
        request.setMethod('POST');

        Http http = new Http();
        HttpResponse response = http.send(request);
        string responseString = response.getBody();

        Map<string, object> dataMap = (Map<string, object>)JSON.deserializeUntyped(responseString);

        Subscriber_Authentication__c auth = new Subscriber_Authentication__c();

        if(dataMap.containsKey('access_token')) 
        {
            auth.Access__c = dataMap.get('access_token').toString();
        }

        if(dataMap.containsKey('refresh_token')) 
        {
            auth.Refresh__c = dataMap.get('refresh_token').toString();
        }

        if(dataMap.containsKey('instance_url')) 
        {
            auth.Instance__c = dataMap.get('instance_url').toString();
        }

        if(dataMap.containsKey('id')) 
        {
            string id = dataMap.get('id').toString();
            List<string> segments = id.split('/');

            string orgId = segments[4];
            string userId = segments[5];

            auth.Org_Id__c = orgId;
            auth.User__c = userId;
        }

        if(auth.Access__c != null &&
            auth.Refresh__c != null &&
            auth.Instance__c != null &&
            auth.Org_Id__c != null &&
            auth.User__c != null)
        {
            database.upsert(auth, Subscriber_Authentication__c.Org_Id__c);

            return true;
        }

        return false;
    }

    public static boolean fetchTokens(string code)
    {
        return fetchTokensAll(code, false);
    }

    public static boolean fetchTokensSandbox(string code)
    {
        return fetchTokensAll(code, true);
    }

    public static Subscriber_Authentication__c refreshAccessToken(Subscriber_Authentication__c auth, boolean silently)
    {
        string tokenEndpoint = 'https://login.salesforce.com/services/oauth2/token?';
        
        string client_id = '';
        string client_secret = '';
            
        List<string> params = new List<string>();
        params.add('grant_type=' + 'refresh_token');
        params.add('client_id=' + CLIENTID);
        params.add('client_secret=' + CLIENTSECRET);
        params.add('redirect_uri=' + REDIRECTURL);
        params.add('refresh_token=' + auth.Refresh__c);
        
        string authHeader = EncodingUtil.base64Encode(Blob.valueOf(client_id + ':' + client_secret));
        
        tokenEndpoint += string.join(params, '&');

        HttpRequest request = new HttpRequest();
        request.setEndpoint(tokenEndpoint);
        request.setHeader('Authorization', 'Basic ' + authHeader);
        request.setMethod('POST');

        Http http = new Http();
        HttpResponse response = http.send(request);
        string responseString = response.getBody();

        Map<string, object> dataMap = (Map<string, object>)JSON.deserializeUntyped(responseString);

        if(dataMap.containsKey('access_token')) 
        {
            auth.Access__c = dataMap.get('access_token').toString();
        }

        if(dataMap.containsKey('refresh_token')) 
        {
            auth.Refresh__c = dataMap.get('refresh_token').toString();
        }

        if(auth.Access__c != null &&
            auth.Refresh__c != null)
        {
            if(!silently)
            {
                database.upsert(auth, Subscriber_Authentication__c.Org_Id__c);
            }

            return auth;
        }

        return null;
    }

    @AuraEnabled
    public static string GenerateOrgAuthInitialiser()
    {
        List<string> parts = new List<string>{ 'https://login.salesforce.com/services/oauth2/authorize?response_type=code' };
        parts.add('client_id=' + CLIENTID);
        parts.add('client_secret=' + CLIENTSECRET);
        parts.add('redirect_uri=' + REDIRECTURL);
        parts.add('scope=refresh_token+full');
        
		return string.join(parts, '&');
    }

    @AuraEnabled
    public static string GenerateOrgAuthInitialiserSandbox()
    {
        List<string> parts = new List<string>{ 'https://test.salesforce.com/services/oauth2/authorize?response_type=code' };
        parts.add('client_id=' + CLIENTID);
        parts.add('client_secret=' + CLIENTSECRET);
        parts.add('redirect_uri=' + REDIRECTURLSANDBOX);
        parts.add('scope=refresh_token+full');
        
		return string.join(parts, '&');
    }
}