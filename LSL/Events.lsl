#include "LSLJSE/Functions Header.lsl"

integer AUTO_PERMISSIONS;

integer LISTENER_TIMEOUT = 60;

list chatcontrol = [/* channel, control */];
list chatlisteners = [/* lastping, id, channel, avatar */];

register_listner(key id, integer channel, key avatar)
{
    integer index = llListFindList(chatlisteners, [id]);
    
    if (index == -1)
    {
        chatlisteners += [llGetUnixTime(), id, channel, avatar];
        if (llListFindList(llList2ListStrided(chatcontrol, 0, -1, 2), [channel]) == -1) chatcontrol += [channel, llListen(channel, "", "", "")];
    }
    else chatlisteners = llListReplaceList(chatlisteners, [llGetUnixTime()], index - 1, index - 1);
}

unregister_listener(key id)
{
    integer index = llListFindList(chatlisteners, [id]);
    
    if (index != -1)
    {
        integer channel = llList2Integer(chatlisteners, index + 1);
        chatlisteners = llListReplaceList(chatlisteners, [], index - 1, index + 2);
        
        if (llListFindList(llList2ListStrided(llList2List(chatlisteners, 1, -1), 0, -1, 4), [channel]) == -1)
        {
            integer controlindex = llListFindList(llList2ListStrided(chatcontrol, 0, -1, 2), [channel]);
            llListenRemove(llList2Integer(chatcontrol, controlindex * 2 + 1));
            chatcontrol = llListReplaceList(chatcontrol, [], controlindex, controlindex + 1);
        }
    }
}

listener_cleanup()
{
    integer index = llGetListLength(chatlisteners) / 4 - 1;
    
    if (index == -1) return;
    
    integer expires_after = llGetUnixTime() - LISTENER_TIMEOUT;
    
    list times = llList2ListStrided(chatlisteners, 0, -1, 4);
    
    while (index >= 0)
    {
        integer time = llList2Integer(times, index);
        
        if (time < expires_after)
        {
            unregister_listener(llList2Key(chatlisteners, index * 4 + 1));
        }
        
        index--;   
    }
}

default
{
    state_entry()
    {
        AUTO_PERMISSIONS = PERMISSION_TAKE_CONTROLS;
        
        llRequestPermissions(llGetOwner(), AUTO_PERMISSIONS);

        llSetTimerEvent(10);

        llListen(3454, "", "", "");
        llListen(3456, "", "", "");
    }

    timer()
    {
        listener_cleanup();
    }
    
    run_time_permissions(integer perm)
    {
        if (perm == AUTO_PERMISSIONS)
        {
            llTakeControls(
                            /*
                            CONTROL_FWD |
                            CONTROL_BACK |
                            CONTROL_LEFT |
                            CONTROL_RIGHT |
                            CONTROL_ROT_LEFT |
                            CONTROL_ROT_RIGHT |
                            CONTROL_UP |
                            CONTROL_DOWN |
                            */
                            CONTROL_LBUTTON |
                            CONTROL_ML_LBUTTON ,
                            TRUE, TRUE);
        }
    }

    control(key id, integer level, integer edge)
    {
        emit(llList2Json(JSON_OBJECT, [
            "type", "control",
            "key", id,
            "level", level,
            "edge", edge
        ]), NULL_KEY);
    }

    listen(integer chan, string name, key id, string text)
    {
        if (chan == 3454)
        {
            emit(llList2Json(JSON_OBJECT, [
                "type", "chat",
                "channel", chan,
                "name", name,
                "id", id,
                "text", text
            ]), NULL_KEY);
            return;
        }
        else if (chan == 3456)
        {
            llOwnerSay(llList2Json(JSON_OBJECT, [
                "chatcontrol", llList2Json(JSON_ARRAY, chatcontrol),
                "chatlisteners", llList2Json(JSON_ARRAY, chatlisteners)
            ]));
            return;
        }

        integer index = llGetListLength(chatlisteners) / 4 - 1;
        if (index == -1) return;
        
        while (index >= 0)
        {
            integer listening_chan = llList2Integer(chatlisteners, index + 2);
            key avatar = llList2Key(chatlisteners, index + 4);

            if (chan == listening_chan)
            {
                emit(llList2Json(JSON_OBJECT, [
                    "type", "chat",
                    "channel", chan,
                    "name", name,
                    "id", id,
                    "text", text
                ]), avatar);
            }
            
            index--;   
        }
    }

    changed(integer change)
    {
        emit(llList2Json(JSON_OBJECT, [
            "type", "changed",
            "value", change
        ]), NULL_KEY);
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

            string type = llJsonGetValue(data, ["type"]);
            
            if (type == "register_chat_listener")
            {
                string session = getJsonValueOrDefault(data, ["session"], (string)llGenerateKey());
                register_listner((key)session, (integer)getJsonValueOrDefault(data, ["channel"], "0"), avatar);

                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", session
                ]));
            }
            else if (type == "unregister_chat_listener")
            {
                unregister_listener((key)llJsonGetValue(data, ["session"]));
                
                ack(str);
            }
            else if (type == "llTakeControls")
            {
                llTakeControls(
                    (integer)getJsonValueOrDefault(data, ["controls"], (string)(
                                CONTROL_FWD |
                                CONTROL_BACK |
                                CONTROL_LEFT |
                                CONTROL_RIGHT |
                                CONTROL_ROT_LEFT |
                                CONTROL_ROT_RIGHT |
                                CONTROL_UP |
                                CONTROL_DOWN)),
                    FALSE,
                    (integer)getJsonValueOrDefault(data, ["block"], "1")
                );
                
                ack(str);
            }
            else if (type == "llReleaseControls")
            {
                llReleaseControls();
                ack(str);
            }
        }
    }
}
