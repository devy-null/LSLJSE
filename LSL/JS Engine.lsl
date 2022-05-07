integer CHAN_URL_TRACKER = -5454354;
integer CHAN_SERVER_POST = -6546536;
integer CHAN_SERVER_QUEUE = -6343254;

integer CHAN_PRINT_QUEUE = -6344854;
integer CHAN_GET_URL = -6343567;

integer NONCE = 453453;

list listener_queue = [/* avatar, session_id, poll_id, time, queue */];
integer QUEUE_AVATAR = 0;
integer QUEUE_SESSION = 1;
integer QUEUE_POLL = 2;
integer QUEUE_TIME = 3;
integer QUEUE_QUEUE = 4;
integer QUEUE_END = 4;
integer QUEUE_LENGTH = 5;

integer timeout = 15;

integer DEBUG = TRUE;

string PUBLIC_URL_BASE = "https://devy-null.github.io/LSLJSE/";
string PAGE = "devy-null:app-rlv-status"; // "devy-null:app-chat"

#define foreach(array, variablename, indexname, stride, body){\
integer indexname = llGetListLength(array) / stride;\
for (indexname -= 1; indexname >= 0; indexname--) {\
list variablename = llList2List(array, indexname * stride, (indexname + 1) * stride);\
body;\
}\
}

enqueue_data(key avatar, key session, string json)
{
    foreach(listener_queue, item, index, QUEUE_LENGTH,
        if (avatar == NULL_KEY || llList2Key(item, QUEUE_AVATAR) == avatar)
        {
            if (session == NULL_KEY || llList2Key(item, QUEUE_SESSION) == session)
            {
                string queue = llList2String(item, QUEUE_QUEUE);
                queue = llJsonSetValue(queue, [-1], json);

                listener_queue = llListReplaceList(listener_queue, [queue], index * QUEUE_LENGTH + QUEUE_QUEUE, index * QUEUE_LENGTH + QUEUE_QUEUE);
                
                send_queue_for_session(llList2Key(item, QUEUE_SESSION));
            }
        }
    )
}

clean_queue()
{
    integer index = llGetListLength(listener_queue) / QUEUE_LENGTH;
    
    integer remove_after = llGetUnixTime() - timeout;
    
    while (index-- > 0)
    {
        integer time = llList2Integer(listener_queue, (index * QUEUE_LENGTH) + QUEUE_TIME);
        
        if (time < remove_after)
        {
            listener_queue = llListReplaceList(listener_queue, [], (index * QUEUE_LENGTH) + QUEUE_QUEUE, (index * QUEUE_LENGTH) + QUEUE_QUEUE);
            if (DEBUG) llRegionSayTo("6db28d36-dff3-4ba0-ba1e-a499bcfddecb", 0, "Cleaned entry!");
        }
    }
}

broadcast(key from, key session, string message, integer exclusive)
{
    integer index = llGetListLength(listener_queue) / QUEUE_LENGTH;
    
    while (index-- > 0)
    {
        key avatar = llList2Key(listener_queue, (index * QUEUE_LENGTH) + QUEUE_AVATAR);
        key session_key = llList2Key(listener_queue, (index * QUEUE_LENGTH) + QUEUE_AVATAR);
        
        if (!(exclusive && avatar == from && session == session_key))
        {
            enqueue_data(avatar, NULL_KEY, message);
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

// llRequestURL / llRequestSecureURL
#define GetURL llRequestSecureURL

string get_token(key avatar)
{
    return llMD5String((string)avatar + "_" + (string)llGetKey(), NONCE);
}

string get_public_url(key avatar)
{
    string json = "{}";
    json = llJsonSetValue(json, ["app"],  llGetKey());
    json = llJsonSetValue(json, ["target"], llGetOwner());
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
    url_request = GetURL();
}

on_new_url(string new_url)
{
    url = new_url;

    integer i = llGetListLength(listener_queue) / QUEUE_LENGTH;
    
    for (i; i > 0; i--)
    {
        listener_queue = llListReplaceList(listener_queue, [NULL_KEY], (i - 1) * QUEUE_LENGTH + QUEUE_POLL, (i - 1) * QUEUE_LENGTH + QUEUE_POLL);
    }

    string public_url = get_public_url(llGetOwner());

    llOwnerSay(public_url);

    /*
    llSetLinkMedia(LINK_THIS, 4, [
        PRIM_MEDIA_HOME_URL, public_url,
        PRIM_MEDIA_CURRENT_URL, public_url,
        PRIM_MEDIA_AUTO_PLAY, TRUE,
        PRIM_MEDIA_HEIGHT_PIXELS, 512,
        PRIM_MEDIA_WIDTH_PIXELS, 512,
        PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_OWNER
    ]);
    */
    
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

send_queue_for_session(key session)
{
    integer index = llListFindList(listener_queue, [session]);
    if (index == -1) return;

    index = index - QUEUE_SESSION;
    
    key poll_id = llList2Key(listener_queue, index + QUEUE_POLL);
    if (poll_id == NULL_KEY) return;
    
    string queue = llList2String(listener_queue, index + QUEUE_QUEUE);
    if (queue == "[]") return;
    
    jsonp_response(poll_id, "poll_response", llList2Json(JSON_OBJECT, [
        "status", "ok",
        "data", queue
    ]));

    listener_queue = llListReplaceList(listener_queue, [], index, index + QUEUE_QUEUE);
}

on_poll(key avatar, key session, key poll_id)
{
    integer index = llListFindList(listener_queue, [session]);

    if (index == -1)
    {
        listener_queue += [avatar, session, poll_id, llGetUnixTime(), "[]"];
    }
    else
    {
        index = index - QUEUE_SESSION;

        listener_queue = llListReplaceList(listener_queue, [poll_id, llGetUnixTime()], index + QUEUE_POLL, index + QUEUE_TIME);
        send_queue_for_session(session);
    }
}

default
{
    state_entry()
    {
        requestURL();
        llListen(CHAN_GET_URL, "", llGetOwner(), "");
    }
    
    attach(key avatar) { if (avatar) requestURL(); }
    on_rez(integer param) { requestURL(); }
    changed(integer change) { if(change & (CHANGED_REGION | CHANGED_REGION_START | CHANGED_TELEPORT)) requestURL(); }

    listen(integer chan, string name, key id, string str)
    {
        if (chan == CHAN_GET_URL)
        {
            llRegionSayTo(id, 0, get_public_url(str));
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == CHAN_SERVER_QUEUE)
        {
            enqueue_data(id, NULL_KEY, str);
        }
        else if (num == CHAN_PRINT_QUEUE)
        {
            llRegionSayTo("6db28d36-dff3-4ba0-ba1e-a499bcfddecb", 0, llList2Json(JSON_ARRAY, listener_queue));
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
        string data;
        string raw_data;

        if (method == "GET")
        {
            raw_data = llGetHTTPHeader(id, "x-query-string");
        }
        else if (method == "POST")
        {
            raw_data = body;
        }

        data = llList2Json(JSON_OBJECT, llParseString2List(raw_data, ["&", "="], []));

        string app = llJsonGetValue(data, ["app"]);
        string avatar = llJsonGetValue(data, ["avatar"]);
        string token = llJsonGetValue(data, ["token"]);
        key session = (key)llJsonGetValue(data, ["session"]);
        
        string message_id = llJsonGetValue(data, ["message_id"]);
        string message = llBase64ToString(llJsonGetValue(data, ["message"]));

        if (session == NULL_KEY) {
            jsonp_error(id, message_id, "No session!");
            return;
        }

        if (token != get_token(avatar))
        {
            jsonp_error(id, message_id, "Invalid token!");
            return;
        }
        
        if (method == "GET" || method == "POST")
        {
            if (path == "/ping")
            {
                jsonp_ack(id, message_id);
            }
            else if (path == "/poll")
            {
                on_poll(avatar, session, id);
            }
            else if (path == "/post")
            {
                llHTTPResponse(id, 200, "ok");
                
                string msg = "{}";
                
                msg = llJsonSetValue(msg, ["avatar"], avatar);
                msg = llJsonSetValue(msg, ["avatar_name"], llGetDisplayName(avatar));
                msg = llJsonSetValue(msg, ["data"], message);
                
                if (llJsonGetValue(message, ["type"]) == "broadcast")
                {
                    broadcast(avatar, session, msg, llJsonGetValue(message, ["exclusive"]) == "true");
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
