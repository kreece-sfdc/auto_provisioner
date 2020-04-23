public with sharing class AuthHelper 
{
    public static void handleEvent(List<AuthCode__e> items)
    {
        Map<string, string> responseMap = new Map<string, string>();
        List<Subscriber_Authentication__c> subscribers = new List<Subscriber_Authentication__c>();

        for(AuthCode__e item : items)
        {
            string resp = fetchTokens(item.Code__c);
            responseMap.put(item.Code__c, resp);
        }

        for(string code : responseMap.keySet())
        {
            Map<string, string> resp = (Map<string, string>)JSON.deserialize(responseMap.get(code), Map<string, string>.class);

            string refresh = resp.get('refresh_token');
            string access = resp.get('access_token');
            string instance = resp.get('instance_url');

            List<string> idparts = resp.get('id').split('/');
            string orgid = idparts.get(idparts.size()-2);
            string userid = idparts.get(idparts.size()-1);

            Subscriber_Authentication__c subscriber = new Subscriber_Authentication__c
            (
                Name = orgid,
                Refresh__c = refresh,
                Access__c = access,
                Instance__c = instance,
                User__c = userid
            );
            subscribers.add(subscriber);
        }

        if(!subscribers.isEmpty())
        {
            database.upsert(subscribers, Subscriber_Authentication__c.Name);
        }
    }

    public static string fetchTokens(string code)
    {
        string tokenEndpoint = 'https://login.salesforce.com/services/oauth2/token?';
        
        string client_id = '3MVG9xB_D1giir9oHPrfIWI7ADpVTlTAYCqBMnUM6p1C1sh0tvJqboDk.FErGErUR2jxbRlhJIDCvpX0M6iS_';
        string client_secret = '9E75078F6A26D48758C32106A6140F7BF15A9F0F4951F7D8725DB68CF7E22B0B';
            
        List<string> params = new List<string>();
        params.add('grant_type=' + 'authorization_code');
        params.add('client_id=' + client_id);
        params.add('redirect_uri=' + 'https://sandbox-test-developer-edition.cs80.force.com');
        params.add('client_secret=' + client_secret);
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
        
        return responseString;
    }

    @AuraEnabled(cacheable=true)
    public static string fetchUserInfo(string access_token)
    {
        string userInfoUrl = 'https://login.salesforce.com/services/oauth2/userinfo';
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(userInfoUrl);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + access_token);

        Http http = new Http();
        HttpResponse response = http.send(request);
        string responseString = response.getBody();

        return responseString;
    }
}