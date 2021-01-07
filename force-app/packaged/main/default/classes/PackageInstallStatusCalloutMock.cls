public with sharing class PackageInstallStatusCalloutMock implements HttpCalloutMock 
{
    public HTTPResponse respond(HTTPRequest req)
    {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{ "Status": "IN_PROGRESS", "id": "005x00000012Q9P" }');
        response.setStatusCode(200);
        return response;
    }
}
