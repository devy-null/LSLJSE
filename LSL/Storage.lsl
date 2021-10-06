#include "LSLJSE/Functions Header.lsl"

list store = [];

default
{
    state_entry()
    {

    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == 0)
        {
            if (str == "reset") llResetScript();
        }
        else if (num == CHAN_SERVER_POST)
        {
            string data = llJsonGetValue(str, ["data"]);
            string type = llJsonGetValue(data, ["type"]);
            
            if (type == "GetValue")
            {
                integer index = llListFindList(llList2ListStrided(store, 0, -1, 2), [llJsonGetValue(data, ["key"])]);
                string result = "null";

                if (index != -1)
                {
                    result = llList2String(store, index * 2 + 1);
                }

                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", result
                ]));
            }
            else if (type == "SetValue")
            {
                string key_index = llJsonGetValue(data, ["key"]);
                string value = llJsonGetValue(data, ["value"]);
                integer index = llListFindList(llList2ListStrided(store, 0, -1, 2), [key_index]);

                if (index == -1)
                {
                    store += [key_index, value];
                }
                else
                {
                    store = llListReplaceList(store, [value], index * 2 + 1, index * 2 + 1);
                }

                ack(str);
            }
            else if (type == "RemoveValue")
            {
                string key_index = llJsonGetValue(data, ["key"]);
                integer index = llListFindList(llList2ListStrided(store, 0, -1, 2), [key_index]);

                if (index != -1)
                {
                    store = llListReplaceList(store, [], index * 2, index * 2 + 1);
                }
                
                ack(str);
            }
            else if (type == "GetKeys")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llList2Json(JSON_ARRAY, llList2ListStrided(store, 0, -1, 2))
                ]));
            }
            else if (type == "Dump")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llList2Json(JSON_OBJECT, store)
                ]));
            }
        }
    }
}
