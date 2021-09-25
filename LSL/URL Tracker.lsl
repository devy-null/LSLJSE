integer CHAN = -5454354;

string APIKEY;

string ID_Database_SL;

string ID_Form_DNS;

string ID_Field_Key;
string ID_Field_URL;

list lookup = [/* key, id */];

integer queue_lifespan = 30;
list queue = [/* id, time, json */];

enqueue(key id, string json)
{
    queue = queue += [id, llGetUnixTime(), json];
    llSetTimerEvent(10);
}

list pop_queue(key id)
{
    integer index = llListFindList(queue, [id]);
    
    if (index != -1)
    {
        list entry = llList2List(queue, index, index + 2);
        queue = llListReplaceList(queue, [], index, index + 2);
        if (llGetListLength(queue) == 0) llSetTimerEvent(0);
        return entry;
    }
    
    return [];
}

expired(key id, integer time, string json)
{
    
}

clean_queue()
{
    integer curr_time = llGetUnixTime();
    integer index = llGetListLength(queue) / 3;
    
    while (index > 0)
    {
        integer time = llList2Integer(queue, (index / 3 - 1));
        if (curr_time > time + queue_lifespan)
        {
            key e_id = llList2Key(queue, index);
            integer e_time = llList2Integer(queue, index + 1);
            string e_json = llList2String(queue, index + 2);
            
            queue = llListReplaceList(queue, [], index, index + 2);
            
            expired(e_id, e_time, e_json);
        }
        index--;
    }
    
    if (llGetListLength(queue) == 0) llSetTimerEvent(0);
}

key post(string endpoint, list query, string json)
{
    endpoint = "https://QuintaDB.com/" + endpoint;
    
    query += ["rest_api_key=" + APIKEY];
    
    if (llGetListLength(query) > 0)
    {
        endpoint += "?" + llDumpList2String(query, "&");
    }
    
    return llHTTPRequest(endpoint, [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json"
    ], json);
}

key search_record(key search_key)
{
    return post("search/"+ID_Database_SL+".json", ["entity_id=" + ID_Form_DNS], llList2Json(JSON_OBJECT, [
        "search", "[[" + llList2Json(JSON_OBJECT, [
            "a", ID_Field_Key,
            "o", "is",
            "b", search_key
        ]) + "]]"
    ]));
}

key create_record(key record_key, string url)
{
    return post("apps/"+ID_Database_SL+"/dtypes.json", [], llList2Json(JSON_OBJECT, [
        "values", llList2Json(JSON_OBJECT, [
            "entity_id", ID_Form_DNS,
            ID_Field_Key, record_key,
            ID_Field_URL, url
        ])
    ]));
}

key update_record(string record_id, string url)
{
    return post("cell_values/"+record_id+"/update_cell_value/"+ID_Field_URL+".json", [], llList2Json(JSON_OBJECT, [
        "val", url
    ]));
}

start_update(key id, string url)
{
    integer index = llListFindList(lookup, [id]);
    if (index != -1) update_record(llList2String(index + 1), url);
    else
    {
        search_record(id);
    }
}

default
{
    state_entry()
    {
        #include "Protected/Keys"
    }
    
    timer()
    {
        clean_queue();
    }
    
    link_message(integer link, integer value, string text, key id)
    {
        if (value == CHAN)
        {
            text = llJsonSetValue(text, ["message_id"], id);
            text = llJsonSetValue(text, ["source_link"], (string)link);
            
            string type = llJsonGetValue(text, ["type"]);
            
            if (type == "set" || type == "get")
            {
                enqueue(search_record(llJsonGetValue(text, ["key"])), llList2Json(JSON_OBJECT, ["type", "search", "cause", text]));
            }   
        }
    }
    
    http_response(key id, integer status, list meta, string body)
    {
        list entry = pop_queue(id);
        
        if (entry)
        {
            string json = llList2String(entry, 2);
            string type = llJsonGetValue(json, ["type"]);
            
            string cause = llJsonGetValue(json, ["cause"]);
            string cause_type = llJsonGetValue(cause, ["type"]);
            
            if (type == "search")
            {
                string records = llJsonGetValue(body, ["records"]);
                
                if (records != "[]")
                {
                    string record_id = llJsonGetValue(records, [0, "id"]);
                    
                    if (cause_type == "get")
                    {
                        string values = llJsonGetValue(records, [0, "values"]);
                        string key_value = llJsonGetValue(values, [ID_Field_Key]);
                        string url_value = llJsonGetValue(values, [ID_Field_URL]);
                        
                        key message_id = (key)llJsonGetValue(cause, ["message_id"]);
                        integer link_source = (integer)llJsonGetValue(cause, ["link_source"]);
                        
                        llMessageLinked(link_source, CHAN, llList2Json(JSON_OBJECT, ["status", "ok", "key", key_value, "url", url_value]), message_id);
                    }
                    else if (cause_type == "set")
                    {
                        enqueue(update_record(record_id, llJsonGetValue(cause, ["value"])), llList2Json(JSON_OBJECT, ["type", "update", "cause", cause]));
                    }
                }
                else
                {
                    enqueue(create_record(llJsonGetValue(cause, ["key"]), llJsonGetValue(cause, ["value"])), llList2Json(JSON_OBJECT, ["type", "create", "cause", cause]));
                }
            }
            else if (type == "create" || type == "update")
            {
                key message_id = (key)llJsonGetValue(cause, ["message_id"]);
                integer link_source = (integer)llJsonGetValue(cause, ["link_source"]);
                
                llMessageLinked(link_source, CHAN, llList2Json(JSON_OBJECT, ["status", "ok"]), message_id);
            }
        }
    }
}
