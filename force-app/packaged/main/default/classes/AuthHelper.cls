public with sharing class AuthHelper 
{
    public static string CLIENTID  = GetAuthSettings().Client_Id__c;
    public static string CLIENTSECRET = GetAuthSettings().Client_Secret__c;

    public static string REDIRECTURLPRODUCTIONTOPRODUCTION = 'https://login.salesforce.com/apex/aprv__authHandler';
    public static string REDIRECTURLPRODUCTIONTOSANDBOX = 'https://login.salesforce.com/apex/aprv__authHandlerSandbox';

    public static string REDIRECTURLSANDBOXTOPRODUCTION = 'https://test.salesforce.com/apex/aprv__authHandler';
    public static string REDIRECTURLSANDBOXTOSANDBOX = 'https://test.salesforce.com/apex/aprv__authHandlerSandbox';
   
    public static aprv__Connected_App_Setting__mdt GetAuthSettings()
    {
        List<aprv__Connected_App_Setting__mdt> connectedAppSettings = [SELECT Id, MasterLabel, Client_Id__c, Client_Secret__c FROM aprv__Connected_App_Setting__mdt WHERE MasterLabel = 'Default'];

        if(!connectedAppSettings.isEmpty())
        {
            return connectedAppSettings.get(0);
        }

        return new aprv__Connected_App_Setting__mdt();
    }

    public static boolean fetchTokens(string code, boolean isSandbox, string client_id, string client_secret, string redirect_uri)
    {
        string tokenEndpoint;
        string authHeader;

        if(isSandbox == true) 
        {
            tokenEndpoint = 'https://test.salesforce.com/services/oauth2/token?';
        }
        else 
        {
            tokenEndpoint = 'https://login.salesforce.com/services/oauth2/token?';
        }
        
        List<string> params = new List<string>();
        params.add('grant_type=' + 'authorization_code');
        params.add('client_id=' + client_id);
        params.add('redirect_uri=' + redirect_uri);
        params.add('code=' + code);

        if(client_secret != null)
        {
            params.add('client_secret=' + client_secret);
            authHeader = EncodingUtil.base64Encode(Blob.valueOf(client_id + ':' + client_secret));
        }
        
        tokenEndpoint += string.join(params, '&');

        HttpRequest request = new HttpRequest();
        request.setEndpoint(tokenEndpoint);
        if(authHeader != null)
        {
            request.setHeader('Authorization', 'Basic ' + authHeader);
        }
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

        auth.IsSandbox__c = isSandbox;

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

            // this is where we need remote site settings to be created; naming convention is 'XX_Customer'
            Map<String, String> urlsByInstances = new Map<String, String>();
            urlsByInstances.put(auth.Org_Id__c, auth.Instance__c);
            RemoteSiteSettingUtils.createRemoteSiteSettings(urlsByInstances);

            return true;
        }

        return false;
    }

    static boolean isThisOrgaSandbox()
    {
        List<Organization> orgs = [SELECT IsSandbox FROM Organization];

        if(!orgs.isEmpty())
        {
            return orgs.get(0).IsSandbox;
        }

        return null;
    }

    public static string fetchRedirectUri(boolean isCustomerSandbox)
    {
        boolean isThisOrgaSandbox = isThisOrgaSandbox();

        if(isThisOrgaSandbox == true && isCustomerSandbox == true)
        {
            return REDIRECTURLSANDBOXTOSANDBOX; 
        }
        else if(isThisOrgaSandbox == true && isCustomerSandbox == false)
        {
            return REDIRECTURLSANDBOXTOPRODUCTION; 
        }
        else if(isThisOrgaSandbox == false && isCustomerSandbox == true)
        {
            return REDIRECTURLPRODUCTIONTOSANDBOX; 
        }
        else if(isThisOrgaSandbox == false && isCustomerSandbox == false)
        {
            return REDIRECTURLPRODUCTIONTOPRODUCTION; 
        }

        return null;
    }

    public static boolean fetchTokens(string code, boolean isCustomerSandbox)
    {
        string redirect_uri = fetchRedirectUri(isCustomerSandbox);

        if(redirect_uri != null)
        {
            return fetchTokens(code, isCustomerSandbox, CLIENTID, CLIENTSECRET, redirect_uri); 
        }
        
        return null;
    }

    /*public static boolean fetchTokensSandbox(string code)
    {
        return fetchTokens(code, true, CLIENTID, CLIENTSECRET, REDIRECTURLSANDBOX);
    }*/

    static Subscriber_Authentication__c refreshAccessToken(Subscriber_Authentication__c auth, boolean silently, boolean isCustomerSandbox)
    {
        string tokenEndpoint;
        string redirect_uri = fetchRedirectUri(isCustomerSandbox);

        if(isCustomerSandbox == true) 
        {
            tokenEndpoint = 'https://test.salesforce.com/services/oauth2/token?';
        }
        else 
        {
            tokenEndpoint = 'https://login.salesforce.com/services/oauth2/token?';
        }


        List<string> params = new List<string>();
        params.add('grant_type=' + 'refresh_token');
        params.add('client_id=' + CLIENTID);
        params.add('client_secret=' + CLIENTSECRET);
        params.add('redirect_uri=' + redirect_uri);
        params.add('refresh_token=' + auth.Refresh__c);
        
        string authHeader = EncodingUtil.base64Encode(Blob.valueOf(CLIENTID + ':' + CLIENTSECRET));
        
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

    public static Subscriber_Authentication__c refreshAccessToken(Subscriber_Authentication__c auth, boolean silently)
    {
        return refreshAccessToken(auth, silently, auth.IsSandbox__c);
    }

    @AuraEnabled
    public static string GenerateOrgAuthInitialiser()
    {
        return GenerateOrgAuthInitialiser(false);
    }

    @AuraEnabled
    public static string GenerateOrgAuthInitialiserSandbox()
    {
        return GenerateOrgAuthInitialiser(true);
    }

    public static string GenerateOrgAuthInitialiser(boolean isSandbox)
    {
        string redirect_uri = fetchRedirectUri(isSandbox);

        string url = 'https://login.salesforce.com';

        if(isSandbox == true)
        {
            url = 'https://test.salesforce.com';
        }

        List<string> parts = new List<string>{ url + '/services/oauth2/authorize?response_type=code' };
        parts.add('client_id=' + CLIENTID);
        parts.add('client_secret=' + CLIENTSECRET);
        parts.add('redirect_uri=' + redirect_uri);
        parts.add('scope=refresh_token+full');

        parts.add('display=popup');
        parts.add('prompt=select_account');
        
		return string.join(parts, '&');
    }
}