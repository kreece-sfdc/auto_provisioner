public with sharing class AuthHelper 
{
    public static string CLIENTID  = GetAuthSettings().Client_Id__c;
    public static string CLIENTSECRET = GetAuthSettings().Client_Secret__c;
    public static string REDIRECTURIBASE = GetAuthSettings().Callback_Uri__c;

    public static string REDIRECTURLPRODUCTION = REDIRECTURIBASE + '/apex/authHandler';
    public static string REDIRECTURLSANDBOX = REDIRECTURIBASE + '/apex/authHandlerSandbox';
    
    @AuraEnabled
    public static Auth_Setting__c SetAuthSettings(string client_id, string client_secret, string redirect_uri)
    {
        Auth_Setting__c authSetting = GetAuthSettings();

        if(authSetting == null)
        {
            authSetting = new Auth_Setting__c
            (
                Client_Id__c = client_id,
                Client_Secret__c = client_secret,
                Callback_Uri__c = redirect_uri,
                SetupOwnerId = UserInfo.getOrganizationId()
            );

            database.insert(authSetting);
        }
        else 
        {
            authSetting.Client_Id__c = client_id;
            authSetting.Client_Secret__c = client_secret;
            authSetting.Callback_Uri__c = redirect_uri;
            database.update(authSetting);
        }

        return authSetting;
    }

    @AuraEnabled
    public static Auth_Setting__c GetAuthSettings()
    {
        return Auth_Setting__c.getOrgDefaults();
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

            return true;
        }

        return false;
    }

    public static boolean fetchTokens(string code, boolean isSandbox)
    {
        if(isSandbox == true)
        {
            return fetchTokens(code, true, CLIENTID, CLIENTSECRET, REDIRECTURLSANDBOX); 
        }

        return fetchTokens(code, false, CLIENTID, CLIENTSECRET, REDIRECTURLPRODUCTION);
    }

    /*public static boolean fetchTokensSandbox(string code)
    {
        return fetchTokens(code, true, CLIENTID, CLIENTSECRET, REDIRECTURLSANDBOX);
    }*/

    static Subscriber_Authentication__c refreshAccessToken(Subscriber_Authentication__c auth, boolean silently, boolean isSandbox)
    {
        string tokenEndpoint;
        string redirect_uri;

        if(isSandbox == true) 
        {
            tokenEndpoint = 'https://test.salesforce.com/services/oauth2/token?';
            redirect_uri = REDIRECTURLSANDBOX;
        }
        else 
        {
            tokenEndpoint = 'https://login.salesforce.com/services/oauth2/token?';
            redirect_uri = REDIRECTURLPRODUCTION;
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
        List<string> parts = new List<string>{ 'https://login.salesforce.com/services/oauth2/authorize?response_type=code' };
        parts.add('client_id=' + CLIENTID);
        parts.add('client_secret=' + CLIENTSECRET);
        parts.add('redirect_uri=' + REDIRECTURLPRODUCTION);
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