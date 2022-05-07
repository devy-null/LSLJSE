#include "LSLJSE/Functions Header.lsl"

integer AUTO_PERMISSIONS;

string sensor_request = NULL_KEY;

list dataserver_requests = [/* query_id, request_id, time */];

dataserver_cleanup()
{
    integer index = llGetListLength(dataserver_requests) / 3 - 1;
    
    if (index == -1) return;
    
    integer expires_after = llGetUnixTime() - 30;
    
    while (index >= 0)
    {
        integer time = llList2Integer(dataserver_requests, index * 3 + 2);
        
        if (time < expires_after)
        {
            respond(llList2String(dataserver_requests, index * 3 + 1), llList2Json(JSON_OBJECT, ["status", "timeout"]));
            dataserver_requests = llListReplaceList(dataserver_requests, [], index * 3, index * 3 + 2);
        }
        
        index--;   
    }
}

default
{
    state_entry()
    {
        AUTO_PERMISSIONS = 
            PERMISSION_TRIGGER_ANIMATION |
            PERMISSION_ATTACH |
            PERMISSION_TRACK_CAMERA |
            PERMISSION_CONTROL_CAMERA |
            PERMISSION_OVERRIDE_ANIMATIONS;
        
        llRequestPermissions(llGetOwner(), AUTO_PERMISSIONS);
        llSetTimerEvent(10);
    }

    timer()
    {
        dataserver_cleanup();
    }
    
    run_time_permissions(integer perm)
    {
        if (perm == AUTO_PERMISSIONS)
        {
            // llMessageLinked(LINK_SET, 2, llList2Json(JSON_OBJECT, ["type", "functions_available"]), llGenerateKey());
        }
    }

    sensor (integer num_detected)
    {
        if (sensor_request)
        {
            list arr = [];
            
            integer index = 0;
            
            while (index < num_detected)
            {
                arr += llList2Json(JSON_OBJECT, [
                    "name", llDetectedName(index),
                    "key", llDetectedKey(index),
                    "group", llDetectedGroup(index),
                    "pos", llDetectedPos(index),
                    "rot", llDetectedRot(index),
                    "vel", llDetectedVel(index)
                ]);
                
                index++;
            }

            respond(sensor_request, llList2Json(JSON_OBJECT, ["status", "ok", "data", llList2Json(JSON_ARRAY, arr)]));
            sensor_request = NULL_KEY;
        }
    }
    
    no_sensor()
    {
        if (sensor_request)
        {
            respond(sensor_request, llList2Json(JSON_OBJECT, ["status", "ok", "data", llList2Json(JSON_ARRAY, [])]));
            sensor_request = NULL_KEY;
        }
    }

    dataserver(key queryId, string data)
    {
        integer index = llListFindList(dataserver_requests, [queryId]);

        if (index != -1)
        {
            respond(llList2String(dataserver_requests, index + 1), llList2Json(JSON_OBJECT, ["status", "ok", "data", data]));
            dataserver_requests = llListReplaceList(dataserver_requests, [], index, index + 2);
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

            integer isOwner = avatar == llGetOwner();

            string type = llJsonGetValue(data, ["type"]);

            string old_name = llGetObjectName();
            string name = llJsonGetValue(data, ["name"]);
            integer name_is_valid = name != JSON_INVALID && name != JSON_NULL && name != "";

            if (name_is_valid && (type == "llSay" || type == "llShout" || type == "llWhisper" || type == "llOwnerSay" || type == "llRegionSayTo")) {
                llSetObjectName(name);
            }
            
            if (type == "llGetAgentInfo")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llGetAgentInfo(getJsonValueOrDefault(data, ["id"], llGetOwner()))
                ]));
            }
            else if (type == "llKey2Name")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llKey2Name(getJsonValueOrDefault(data, ["key"], llGetOwner()))
                ]));
            }
            else if (type == "llGetDisplayName")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llGetDisplayName(getJsonValueOrDefault(data, ["key"], llGetOwner()))
                ]));
            }
            else if (type == "llRequestDisplayName") {
                dataserver_requests += [llRequestDisplayName(llJsonGetValue(data, ["key"])), str, llGetUnixTime()];
            }
            else if (type == "llGetObjectDetails")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llList2Json(JSON_ARRAY,llGetObjectDetails(getJsonValueOrDefault(data, ["key"], llGetOwner()), llJson2List(llJsonGetValue(data, ["parameters"]))))
                ]));
            }
            else if (type == "llGetAttachedList")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llList2Json(JSON_ARRAY,llGetAttachedList(getJsonValueOrDefault(data, ["key"], llGetOwner())))
                ]));
            }
            else if (type == "llStartAnimation")
            {
                llStartAnimation(llJsonGetValue(data, ["name"]));
                ack(str);
            }
            else if (type == "llStopAnimation")
            {
                llStopAnimation(llJsonGetValue(data, ["name"]));
                ack(str);
            }
            else if (type == "llGetAnimation")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llGetAnimation(getJsonValueOrDefault(data, ["key"], llGetOwner()))
                ]));
            }
            else if (type == "llGetAnimationOverride")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llGetAnimationOverride(llJsonGetValue(data, ["state"]))
                ]));
            }
            else if (type == "llGetAnimationList")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llList2Json(JSON_ARRAY,llGetAnimationList(getJsonValueOrDefault(data, ["key"], llGetOwner())))
                ]));
            }
            else if (type == "llSay")
            {
                llSay((integer)getJsonValueOrDefault(data, ["channel"], "0"), llJsonGetValue(data, ["text"]));
                ack(str);
            }
            else if (type == "llShout")
            {
                llShout((integer)getJsonValueOrDefault(data, ["channel"], "0"), llJsonGetValue(data, ["text"]));
                ack(str);
            }
            else if (type == "llWhisper")
            {
                llWhisper((integer)getJsonValueOrDefault(data, ["channel"], "0"), llJsonGetValue(data, ["text"]));
                ack(str);
            }
            else if (type == "llOwnerSay")
            {
                llOwnerSay(llJsonGetValue(data, ["text"]));
                ack(str);
            }
            else if (type == "llRegionSayTo")
            {
                llRegionSayTo(llJsonGetValue(data, ["target"]), (integer)getJsonValueOrDefault(data, ["channel"], "0"), llJsonGetValue(data, ["text"]));
                ack(str);
            }
            else if (type == "llGetLinkPrimitiveParams")
            {
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llList2Json(JSON_ARRAY, llGetLinkPrimitiveParams(
                        (integer)getJsonValueOrDefault(data, ["link"], (string)LINK_SET),
                        llJson2List(llJsonGetValue(data, ["parameters"]))
                    ))
                ]));
            }
            else if (type == "llSetLinkPrimitiveParamsFast")
            {
                llSetLinkPrimitiveParamsFast(
                    (integer)getJsonValueOrDefault(data, ["link"], (string)LINK_SET),
                    llJson2List(llJsonGetValue(data, ["parameters"]))
                );
                ack(str);
            }
            else if (type == "llSensor")
            {
                sensor_request = str;
                
                llSensor(
                    getJsonValueOrDefault(data, ["name"], ""),
                    getJsonValueOrDefault(data, ["id"], NULL_KEY),
                    (integer)getJsonValueOrDefault(data, ["sensor_type"], (string)AGENT_BY_LEGACY_NAME),
                    (integer)getJsonValueOrDefault(data, ["range"], "10.0"),
                    (integer)getJsonValueOrDefault(data, ["arc"], (string) PI)
                );
            }
            else if (type == "llSetCameraParams")
            {
                llSetCameraParams(llJson2List(llJsonGetValue(data, ["rules"])));
                ack(str);
            }
            else if (type == "llCastRay")
            {
                vector start = (vector)getJsonValueOrDefault(data, ["start"], (string)llGetCameraPos());
                float dist = (float)getJsonValueOrDefault(data, ["dist"], "60");
                vector end = (vector)getJsonValueOrDefault(data, ["end"], (string)(start + <dist, 0, 0> * llGetCameraRot()));
                
                respond(str, llList2Json(JSON_OBJECT, [
                    "status", "ok",
                    "data", llList2Json(JSON_ARRAY, llCastRay(start, end, llJson2List(llJsonGetValue(data, ["options"]))))
                ]));
            }

            if (name_is_valid && (type == "llSay" || type == "llShout" || type == "llWhisper" || type == "llOwnerSay" || type == "llRegionSayTo")) {
                llSetObjectName(old_name);
            }
        }
    }
}
