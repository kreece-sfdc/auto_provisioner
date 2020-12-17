public with sharing class MapHelper 
{
    public static Map<string, object> convertToMap(string response)
    {
        if(response.startsWith('['))
        {
            List<object> responseListMap = convertToListMap(response);
            return convertToMap(responseListMap[0]);
        }

        return (Map<string, object>)JSON.deserializeUntyped(response);
    }

    public static Map<string, object> convertToMap(object response)
    {
        return convertToMap(JSON.serialize(response));
    }

    public static List<object> convertToListMap(string response)
    {
        return (List<object>)JSON.deserializeUntyped(response);
    }
}
