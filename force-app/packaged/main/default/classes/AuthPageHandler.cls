public with sharing class AuthPageHandler 
{
    public boolean CloseModal { get; set; }

    public PageReference Redirect()
    {
        if(ApexPages.currentPage().getParameters().containsKey('code'))
        {
            string authCode = ApexPages.currentPage().getParameters().get('code');
            // callout to get the access/refresh token
            boolean successful = AuthHelper.fetchTokens(authCode, false);
            
            if(successful) 
            {
                CloseModal = true;
            }
        }

        return null;
    }

    public PageReference RedirectSandbox()
    {
        if(ApexPages.currentPage().getParameters().containsKey('code'))
        {
            string authCode = ApexPages.currentPage().getParameters().get('code');
            // callout to get the access/refresh token
            boolean successful = AuthHelper.fetchTokens(authCode, true);
            
            if(successful) 
            {
                CloseModal = true;
            }
        }

        return null;
    }
}
