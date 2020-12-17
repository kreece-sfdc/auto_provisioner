public class ApiResponse
{
    public string Message { get; set; }
    public string Status { get; set; }

    public string Id { get; set; }
    public Map<string, object> ResponseMap { get; set; }
}