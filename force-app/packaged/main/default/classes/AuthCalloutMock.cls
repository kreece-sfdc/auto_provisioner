public with sharing class AuthCalloutMock implements HttpCalloutMock 
{
    public HTTPResponse respond(HTTPRequest req)
    {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{ "refresh_token": "zzzzzz", "id": "https://login.salesforce.com/id/00Dx0000000BV7z/005x00000012Q9P" }');
        response.setStatusCode(200);
        return response;
    }
}
