public with sharing class RemoteSiteSettingUtils {
    
    @future(callout=true)
    public static void createRemoteSiteSettings(Map<string,string> siteURLByName){
        String result = '';
        
        List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
        for(string settingName: siteURLByName.keyset()){
            MetadataService.RemoteSiteSetting site = new MetadataService.RemoteSiteSetting();
            site.fullName = 'ID_' + settingName + '_Customer';
            site.description = 'Remote Site Setting created by Auto Provisioner, facilitates pushing packages to customer org.';
            site.disableProtocolSecurity  = false;
            site.isActive  = true;
            site.url=siteURLByName.get(settingName);
            allMetadataList.add(site);
        }        
        if(allMetadataList.size()>0){
            MetadataService.MetadataPort service = createService();
            List<MetadataService.UpsertResult> results = service.upsertMetadata(allMetadataList);
            for(MetadataService.UpsertResult res: results){
                if(res.success){
                    system.debug(res);
                }else{
                    for(aprv.MetadataService.Error error : res.errors){
                        result += error.message;
                    }
                    System.debug(result);
                }
            }

        }
    }  
  
    private static MetadataService.MetadataPort createService(){ 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;     
    }
}
