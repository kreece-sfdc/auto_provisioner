@isTest
public with sharing class AuthHelperTest 
{
    @isTest
    static void FetchTokensTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());

        boolean resp = AuthHelper.fetchTokens('code');

        system.assertEquals(true, resp);
    }

    @isTest
    static void FetchUserInfoTest()
    {
        Test.setMock(HttpCalloutMock.class, new AuthCalloutMock());
        string resp = AuthHelper.fetchUserInfo('access_token');

        system.assertNotEquals(null, resp);
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
