integer CHAN_SERVER_POST = -6546536;
integer CHAN_SERVER_QUEUE = -6343254;

ack(string request)
{
    respond(request, llList2Json(JSON_OBJECT, ["status", "ok"]));
}

respond(string request, string json)
{
    string message_id = llJsonGetValue(request, ["message_id"]);
    key avatar = (key)llJsonGetValue(request, ["avatar"]);
    
    llMessageLinked(LINK_THIS, CHAN_SERVER_QUEUE, llList2Json(JSON_OBJECT, ["message_id", message_id, "data", json]), avatar);
}

emit(string json, key avatar)
{   
    llMessageLinked(LINK_THIS, CHAN_SERVER_QUEUE, llList2Json(JSON_OBJECT, ["data", json]), avatar);
}

string getJsonValueOrDefault(string json, list selector, string defaultvalue)
{
    string value = llJsonGetValue(json, selector);
    if (value == JSON_INVALID) value = defaultvalue;
    return value;
}