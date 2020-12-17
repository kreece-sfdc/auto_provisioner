@isTest
public with sharing class AuthHelperTest 
{
    @isTest
    static void FetchTokensTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());

        boolean resp = AuthHelper.fetchTokens('code', false);

        system.assertEquals(true, resp);
    }

    @isTest
    static void FetchUserInfoTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());

        Subscriber_Authentication__c authRecord = new Subscriber_Authentication__c
        (
            Access__c = 'access', 
            Instance__c = 'instance', 
            Refresh__c = 'refresh', 
            Org_Id__c = 'orgid', 
            User__c = 'userid',
            IsSandbox__c = true
        );
        insert authRecord;
        
        Test.startTest();
        ComponentResponse resp = ProvisioningRequestHandler.fetchUserInfo(authRecord.Id);
        Test.stopTest();

        system.assertNotEquals('success', resp.MessageType);
    }

    @isTest
    static void GenerateOrgAuthInitialiserTest()
    {
        string resp = AuthHelper.GenerateOrgAuthInitialiser();

        system.assertNotEquals(null, resp);
    }


    @isTest
    static void AuthControllerTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());
        
        PageReference pageRef = Page.authHandler;
        Test.setCurrentPage(pageRef);
        
        AuthPageHandler controller = new AuthPageHandler();
        controller.Redirect();
        
        pageRef.getParameters().put('code', 'abc');
        controller.Redirect();
        
        system.assertEquals(true, controller.CloseModal);
    }
}
