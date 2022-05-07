#include "LSLJSE/Functions Header.lsl"

list callbacks = [/* key, name, request, chan, ctrl, time */];

list callbackables = [
    "version",
    "versionnew",
    "versionnum",
    "getblacklist",
    "getcam_avdistmin",
    "getcam_avdistmax",
    "getcam_fovmin",
    "getcam_fovmax",
    "getcam_zoommin",
    "getcam_fov",
    "versionnumbl",
    "getstatus",
    "getstatusall",
    "getsitid",
    "getoutfit",
    "getattach",
    "getinv",
    "getinvworn",
    "findfolder",
    "findfolders",
    "getpath",
    "getpathnew",
    "getgroup"
];

initCallback(key id, string cmd, string request)
{
    integer channel = (integer)llFrand(89999.0) + 10000;
    integer ctrl = llListen(channel, "", "", "");
    
    callbacks += [id, cmd, request, channel, ctrl, llGetUnixTime()];
    
    llOwnerSay(cmd + "=" + (string)channel);
}

default
{
    state_entry()
    {
        llSetTimerEvent(1);
    }

    timer()
    {
        integer current_time = llGetUnixTime();
        
        list times = llList2ListStrided(llList2List(callbacks, 5, -1), 0, -1, 6);
        integer index = llGetListLength(times) - 1;
        
        while (index >= 0)
        {
            integer time = llList2Integer(times, index);
            
            if (current_time > time + 30)
            {
                list data = llList2List(callbacks, index * 6, (index + 1) * 6 - 1);
                callbacks = llListReplaceList(callbacks, [], index * 6, (index + 1) * 6 - 1);

                respond(llList2String(data, 2), llList2Json(JSON_OBJECT, ["status", "timeout"]));
            }
            
            index--;
        }
    }

    listen(integer chan, string name, key id, string text)
    {
        list channels = llList2ListStrided(llList2List(callbacks, 3, -1), 0, -1, 6);
        integer index = llListFindList(channels, [chan]);
        
        if (index != -1)
        {
            list data = llList2List(callbacks, index * 6, (index + 1) * 6 - 1);
            callbacks = llListReplaceList(callbacks, [], index * 6, (index + 1) * 6 - 1);
            
            llListenRemove(llList2Integer(data, 4));

            respond(llList2String(data, 2), llList2Json(JSON_OBJECT, ["status", "ok", "data", text]));
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == 0)
        {
            if (str == "reset") llResetScript();
        }
        else if (num == CHAN_SERVER_POST)
        {
            string message_id = llJsonGetValue(str, ["message_id"]);
            key avatar = (key)llJsonGetValue(str, ["avatar"]);
            string data = llJsonGetValue(str, ["data"]);
            
            if (llJsonGetValue(data, ["type"]) == "RLV")
            {
                string cmd = llJsonGetValue(data, ["cmd"]);
                
                list segments = llParseStringKeepNulls(cmd, [], ["@", "=", ":"]);
                
                if (llList2List(segments, 0, 1) == ["", "@"])
                {
                    if (llListFindList(callbackables, [llList2String(segments, 2)]) != -1)
                    {
                        initCallback(id, cmd, str);
                    }
                    else
                    {
                        llOwnerSay(cmd);

                        emit(llList2Json(JSON_OBJECT, [
                            "type", "rlv",
                            "avatar", avatar,
                            "cmd", cmd,
                            "message_id", message_id
                        ]), NULL_KEY);

                        respond(str, llList2Json(JSON_OBJECT, [
                            "status", "ok"
                        ]));
                    }
                }
            }
        }
    }
}
