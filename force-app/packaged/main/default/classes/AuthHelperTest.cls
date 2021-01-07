@isTest
public with sharing class AuthHelperTest 
{
    @isTest
    public static void FetchTokensTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());

        boolean resp = AuthHelper.fetchTokens('code', false);

        system.assertEquals(true, resp);
    }

    @isTest
    static void RefreshAccessTokensTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());

        boolean resp = AuthHelper.fetchTokens('code', false);

        test.startTest();

        List<Subscriber_Authentication__c> auths = [SELECT Access__c, Refresh__c, IsSandbox__c, Org_Id__c, User__c, Instance__c FROM Subscriber_Authentication__c];
        Subscriber_Authentication__c newAuth;

        if(!auths.isEmpty())
        {
            newAuth = AuthHelper.refreshAccessToken(auths.get(0), true);

            newAuth = AuthHelper.refreshAccessToken(auths.get(0), false);
        }   

        test.stopTest();

        system.assertNotEquals(null, newAuth);
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
    static void GenerateOrgAuthInitialiserSandboxTest()
    {
        string resp = AuthHelper.GenerateOrgAuthInitialiserSandbox();

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

    @isTest
    static void AuthControllerSandboxTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());
        
        PageReference pageRef = Page.authHandlerSandbox;
        Test.setCurrentPage(pageRef);
        
        AuthPageHandler controller = new AuthPageHandler();
        controller.RedirectSandbox();
        
        pageRef.getParameters().put('code', 'abc');
        controller.RedirectSandbox();
        
        system.assertEquals(true, controller.CloseModal);
    }
}
