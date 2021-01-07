public with sharing class PackageInstallCalloutMock implements HttpCalloutMock 
{
    public HTTPResponse respond(HTTPRequest req)
    {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{ "success": true, "id": "005x00000012Q9P" }');
        response.setStatusCode(200);
        return response;
    }
}
