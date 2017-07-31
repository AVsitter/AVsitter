/*
 * This Source Code Form is subject to the terms of the Mozilla Public 
 * License, v. 2.0. If a copy of the MPL was not distributed with this 
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) the AVsitter Contributors (http://avsitter.github.io)
 * AVsitter™ is a trademark. For trademark use policy see:
 * https://avsitter.github.io/TRADEMARK.mediawiki
 * 
 * Please consider supporting continued development of AVsitter and
 * receive automatic updates and other benefits! All details and user 
 * instructions can be found at http://avsitter.github.io
 */
 
 /*
 * The release version of the [AV]object Script has the original AVsitter experience
 * enabled. Scripts with this experience may not be shared in full perms form.
 * Please support further development of AVsitter by not sharing it!
 * If you acquired this script from someone else, please support the
 * developers by purchasing AVsitter (see https://avsitter.github.io)
 * and also obtain the benefit of automatic updates.
 */

string version = "2.020";
integer comm_channel;
integer local_attach_channel = -2907539;
integer listen_handle;
integer prop_type;
integer prop_id;
integer prop_point;
integer experience_denied_reason;
key originalowner;
key give_prop_warning_request;
unsit_all()
{
    integer i = llGetNumberOfPrims();
    while (llGetAgentSize(llGetLinkKey(i)))
    {
        llUnSit(llGetLinkKey(i));
        i--;
    }
}
integer verbose = 5;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
    }
}
default
{
    state_entry()
    {
    }
    on_rez(integer start)
    {
        if (start)
        {
            state prop;
        }
    }
}
state prop
{
    state_entry()
    {
        if (llGetLinkNumber() < 2)
        {
            if (llGetStartParameter() <= -10000000)
            {
                string start_param = (string)llGetStartParameter();
                prop_type = (integer)llGetSubString(start_param, -1, -1);
                prop_point = (integer)llGetSubString(start_param, -3, -2);
                prop_id = (integer)llGetSubString(start_param, -5, -4);
                comm_channel = (integer)llGetSubString(start_param, 0, -6);
                listen_handle = llListen(comm_channel, "", "", "");
                llSay(comm_channel, "REZ|" + (string)prop_id);
            }
            else
            {
            }
        }
        if (prop_type != 2 && prop_type != 1)
        {
            if (llGetInventoryType("[AV]sitA") == INVENTORY_NONE)
            {
                llSetClickAction(-1);
            }
        }
        else
        {
            llSetClickAction(CLICK_ACTION_TOUCH);
        }
    }
    attach(key id)
    {
        if (comm_channel)
        {
            if (llGetAttached())
            {
                llListen(local_attach_channel, "", "", "");
                llSay(comm_channel, "ATTACHED|" + (string)prop_id);
                llSay(local_attach_channel, "LOCAT|" + (string)llGetAttached());
                if (experience_denied_reason == 17)
                {
                    if (llGetOwner() == originalowner)
                    {
                        list details = llGetExperienceDetails("");
                        if (llList2String(details, 3) == "17")
                        {
                            llSay(comm_channel, "NAG|" + llList2String(details, 0));
                        }
                    }
                }
            }
            else
            {
                llSay(comm_channel, "DETACHED|" + (string)prop_id);
            }
        }
    }
    touch_start(integer touched)
    {
        if ((!llGetAttached()) && (prop_type == 2 || prop_type == 1))
        {
            llRequestExperiencePermissions(llDetectedKey(0), "");
        }
    }
    run_time_permissions(integer permissions)
    {
        if (permissions & PERMISSION_ATTACH)
        {
            if (llGetAttached())
            {
                llDetachFromAvatar();
            }
            else
            {
                llAttachToAvatarTemp(prop_point);
            }
        }
        else
        {
            llSay(comm_channel, "DEREZ|" + (string)prop_id);
            llDie();
        }
    }
    experience_permissions(key target_id)
    {
        if (llGetAttached())
        {
            llDetachFromAvatar();
        }
        else
        {
            llAttachToAvatarTemp(prop_point);
        }
    }
    experience_permissions_denied(key agent_id, integer reason)
    {
        originalowner = llGetOwner();
        experience_denied_reason = reason;
        llRequestPermissions(agent_id, PERMISSION_ATTACH);
    }
    on_rez(integer start)
    {
        if (!llGetAttached())
        {
            state restart_prop;
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        list data = llParseString2List(message, ["|"], []);
        string command = llList2String(data, 0);
        if (llList2String(data, 0) == "LOCAT" && llGetOwnerKey(id) == llGetOwner() && llList2String(data, 1) == (string)llGetAttached())
        {
            llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
        }
        else if (command == "ATTACHTO" && prop_type == 1 && (key)llList2String(data, 2) == llGetKey())
        {
            if (llGetAgentSize((key)llList2String(data, 1)) == ZERO_VECTOR)
            {
                llSay(comm_channel, "DEREZ|" + (string)prop_id);
                llDie();
            }
            else
            {
                llRequestExperiencePermissions((key)llList2String(data, 1), "");
            }
        }
        else if (llGetSubString(command, 0, 3) == "REM_")
        {
            integer remove;
            if (command == "REM_ALL")
            {
                remove = TRUE;
            }
            else if (command == "REM_INDEX" || (command == "REM_WORLD" && (!llGetAttached())))
            {
                if (~llListFindList(data, [(string)prop_id]))
                {
                    remove = TRUE;
                }
            }
            else if (llGetAttached() && command == "REM_WORN" && (key)llList2String(data, 1) == llGetOwner())
            {
                remove = TRUE;
            }
            if (remove)
            {
                if (llGetAttached())
                {
                    llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
                }
                else
                {
                    if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())))
                    {
                        unsit_all();
                        llSleep(1);
                    }
                    llSay(comm_channel, "DEREZ|" + (string)prop_id);
                    llDie();
                }
            }
        }
        else if (message == "PROPSEARCH" && (!llGetAttached()))
        {
            llSay(comm_channel, "SAVEPROP|" + (string)prop_id);
        }
    }
}
state restart_prop
{
    state_entry()
    {
        state prop;
    }
}
