integer CHAN_URL_TRACKER = -5454354;
integer CHAN_SERVER_POST = -6546536;
integer CHAN_SERVER_QUEUE = -6343254;

integer CHAN_PRINT_QUEUE = -6344854;

integer NONCE = 453453;

list listener_queue = [/* avatar, poll_id, time, queue */];
integer timeout = 15;

integer DEBUG = TRUE;

enqueue_data(key avatar, string json)
{
    if (avatar == NULL_KEY)
    {
        integer index = llGetListLength(listener_queue) / 4;
        
        while (index-- > 0)
        {
            enqueue_data_for_avatar(llList2Key(listener_queue, index * 4), json);
        }
    }
    else
    {
        enqueue_data_for_avatar(avatar, json);
    }
}

enqueue_data_for_avatar(key avatar, string json)
{
    integer index = llListFindList(listener_queue, [avatar]);
    
    if (index == -1)
    {
        listener_queue += [avatar, NULL_KEY, llGetUnixTime(), llList2Json(JSON_ARRAY, [json])];
    }
    else
    {
        string queue = llList2String(listener_queue, index + 3);
        queue = llJsonSetValue(queue, [-1], json);

        listener_queue = llListReplaceList(listener_queue, [queue], index + 3, index + 3);
        
        send_queue(avatar);
    }
}

clean_queue()
{
    integer index = llGetListLength(listener_queue) / 4;
    
    integer remove_after = llGetUnixTime() - timeout;
    
    while (index-- > 0)
    {
        integer time = llList2Integer(listener_queue, (index * 4) + 2);
        
        if (time < remove_after)
        {
            listener_queue = llListReplaceList(listener_queue, [], (index * 4) + 3, (index * 4) + 3);
            if (DEBUG) llOwnerSay("Cleaned entry!");
        }
    }
}

broadcast(key from, string message)
{
    integer index = llGetListLength(listener_queue) / 4;
    
    while (index-- > 0)
    {
        key avatar = llList2Key(listener_queue, (index * 4));
        
        if (avatar != from)
        {
            enqueue_data_for_avatar(avatar, message);
        }
    }
}

jsonp_ack(string http_id, string message_id)
{
    jsonp_response(http_id, "ack", llList2Json(JSON_OBJECT, [
        "message_id", message_id,
        "status", "ok"
    ]));
}

jsonp_error(string http_id, string message_id, string message)
{
    jsonp_response(http_id, "ack", llList2Json(JSON_OBJECT, [
        "message_id", message_id,
        "status", message
    ]));
}

list queue = [/* target, time, json */];
key current_poll;

string url;
key url_request;

string PUBLIC_URL_BASE = "https://devy-null.github.io/LSLJSE/";
string PAGE = "devy-null:app-hello-world";

string get_token(key avatar)
{
    return llMD5String((string)avatar + "_" + (string)llGetKey(), NONCE);
}

string get_public_url(key avatar)
{
    string json = "{}";
    json = llJsonSetValue(json, ["app"],  llGetKey());
    json = llJsonSetValue(json, ["avatar"], avatar);
    json = llJsonSetValue(json, ["token"], get_token(avatar));
    json = llJsonSetValue(json, ["page"], PAGE);
    json = llJsonSetValue(json, ["start_url"], url);
    return PUBLIC_URL_BASE + "#" + llStringToBase64(json);
}

requestURL()
{
    if (url) llReleaseURL(url);
    url = "";
    url_request = llRequestSecureURL();
}

on_new_url(string url)
{
    integer i = llGetListLength(listener_queue) / 4;
    
    for (i; i > 0; i--)
    {
        listener_queue = llListReplaceList(listener_queue, [NULL_KEY], (i - 1) * 4 + 1, (i - 1) * 4 + 1);
    }
    
    llMessageLinked(LINK_THIS, CHAN_URL_TRACKER, llList2Json(JSON_OBJECT, [
        "type", "set",
        "key", llGetKey(),
        "value", url
    ]), llGenerateKey());
}

jsonp_response(key request_id, string name, string json)
{
    llHTTPResponse(request_id, 200, name + "(" + json + ")");
}

send_queue(key avatar)
{
    integer index = llListFindList(listener_queue, [avatar]);
    if (index == -1) return;
    
    key poll_id = llList2Key(listener_queue, index + 1);
    if (poll_id == NULL_KEY) return;
    
    string queue = llList2String(listener_queue, index + 3);
    if (queue == "[]") return;
    
    jsonp_response(poll_id, "poll_response", queue);
    listener_queue = llListReplaceList(listener_queue, [], index, index + 3);
}

on_poll(key avatar, key poll_id)
{
    integer index = llListFindList(listener_queue, [avatar]);
    
    if (index == -1)
    {
        listener_queue += [avatar, poll_id, llGetUnixTime(), "[]"];
    }
    else
    {
        listener_queue = llListReplaceList(listener_queue, [poll_id, llGetUnixTime()], index + 1, index + 2);
        send_queue(avatar);
    }
}

default
{
    state_entry()
    {
        requestURL();
        llOwnerSay(get_public_url(llGetOwner()));
        llOwnerSay(get_public_url(llGenerateKey()));
    }
    
    attach(key avatar) { if (avatar) requestURL(); }
    on_rez(integer param) { requestURL(); }
    changed(integer change) { if(change & (CHANGED_REGION | CHANGED_REGION_START | CHANGED_TELEPORT)) requestURL(); }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == CHAN_SERVER_QUEUE)
        {
            enqueue_data_for_avatar(id, str);
        }
        else if (num == CHAN_PRINT_QUEUE)
        {
            llOwnerSay(llList2Json(JSON_ARRAY, listener_queue));
        }
    }
    
    http_request(key id, string method, string body)
    {        
        if (method == URL_REQUEST_GRANTED)
        {
            on_new_url(body);
            return;
        }
        
        string path = llUnescapeURL(llGetHTTPHeader(id, "x-path-info"));
        string query = llGetHTTPHeader(id, "x-query-string");
        string data = llList2Json(JSON_OBJECT, llParseString2List(query, ["&", "="], []));
        
        string app = llJsonGetValue(data, ["app"]);
        string avatar = llJsonGetValue(data, ["avatar"]);
        string token = llJsonGetValue(data, ["token"]);
        
        llOwnerSay(llList2Json(JSON_OBJECT, [
            "type", "http_request",
            "id", id,
            "method", method,
            "body", body,
            "path", path,
            "query", query,
            "data", data
        ]));
        
        if (token != get_token(avatar))
        {
            jsonp_error(id, message_id, "Invalid token!");
            return;
        }
        
        string message_id = llJsonGetValue(data, ["message_id"]);
        string message = llBase64ToString(llJsonGetValue(data, ["message"]));
        
        if (method == "GET")
        {
            if (path == "/ping")
            {
                jsonp_ack(id, message_id);
            }
            else if (path == "/poll")
            {
                on_poll(avatar, id);
            }
            else if (path == "/post")
            {
                jsonp_ack(id, message_id);
                
                string msg = "{}";
                
                msg = llJsonSetValue(msg, ["avatar"], avatar);
                msg = llJsonSetValue(msg, ["avatar_name"], llGetDisplayName(avatar));
                msg = llJsonSetValue(msg, ["data"], message);
                
                if (llJsonGetValue(message, ["type"]) == "broadcast")
                {
                    broadcast(avatar, msg);
                }
                else
                {
                    msg = llJsonSetValue(msg, ["message_id"], message_id);
                    llMessageLinked(LINK_THIS, CHAN_SERVER_POST, msg, NULL_KEY);
                }
            }
        }
    }
}
