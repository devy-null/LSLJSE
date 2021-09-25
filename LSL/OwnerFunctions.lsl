#include "LSLJSE/Functions Header.lsl"

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == CHAN_SERVER_POST)
        {
            string message_id = llJsonGetValue(str, ["message_id"]);
            key avatar = (key)llJsonGetValue(str, ["avatar"]);
            string data = llJsonGetValue(str, ["data"]);
            
            if (avatar == llGetOwner())
            {
                if (llJsonGetValue(data, ["type"]) == "llGetKey")
                {
                    respond(str, llList2Json(JSON_OBJECT, ["key", llGetKey()]));
                }
                else if (llJsonGetValue(data, ["type"]) == "llOwnerSay")
                {
                    llOwnerSay(llJsonGetValue(data, ["message"]));
                    ack(str);
                }
            }
            else if (llJsonGetValue(data, ["type"]) == "llOwnerSay")
            {
                llOwnerSay("secondlife:///app/agent/" + (string)avatar + "/inspect : " + llJsonGetValue(data, ["message"]));
                ack(str);
            }
        }
    }
}
