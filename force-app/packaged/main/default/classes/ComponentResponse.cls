public class ComponentResponse
{
    @AuraEnabled
    public string Message { get; set; }
    @AuraEnabled
    public string MessageType { get; set; }
    @AuraEnabled
    public boolean ForceRefresh { get; set; }
}