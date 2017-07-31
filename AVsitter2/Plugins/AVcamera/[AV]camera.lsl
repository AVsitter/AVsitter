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
 
string version = "2.2";
string notecard_name = "AVpos";
string main_script = "[AV]sitA";
key notecard_key;
key notecard_query;
integer notecard_line;
integer notecard_section;
integer SCRIPT_CHANNEL;
string myPose;
key mySitter;
list camera_triggers;
list camera_settings;
integer lastByButton = -1;
string lastPose;
integer get_number_of_scripts()
{
    integer i = 1;
    while (llGetInventoryType(main_script + " " + (string)i) == INVENTORY_SCRIPT)
    {
        i++;
    }
    return i;
}
integer verbose = 0;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
    }
}
Readout_Say(string say, string SCRIPT_CHANNEL)
{
    llSleep(0.2);
    llMessageLinked(LINK_THIS, 90022, say, SCRIPT_CHANNEL);
}
set_camera(integer byButton)
{
    if (mySitter)
    {
        if (llGetPermissions() & PERMISSION_CONTROL_CAMERA)
        {
            if (llGetPermissionsKey() == mySitter)
            {
                integer index = llListFindList(camera_triggers, [myPose]);
                if (!~index)
                {
                    if (~lastByButton)
                    {
                        index = lastByButton;
                    }
                    else
                    {
                        index = llListFindList(camera_triggers, ["DEFAULT"]);
                    }
                }
                if (~index)
                {
                    if (byButton)
                    {
                        lastByButton = index;
                    }
                    list settings = llParseStringKeepNulls(llList2String(camera_settings, index), ["|"], []);
                    vector pos = (vector)llList2String(settings, 0) * llGetRot() + llGetPos();
                    vector focus = (vector)llList2String(settings, 1) * llGetRot() + llGetPos();
                    llSetCameraParams([CAMERA_ACTIVE, 1, CAMERA_FOCUS, focus, CAMERA_FOCUS_LOCKED, TRUE, CAMERA_POSITION, pos, CAMERA_POSITION_LOCKED, TRUE, CAMERA_FOCUS_OFFSET, <0,0,0>]);
                }
                else
                {
                    llSetCameraParams([CAMERA_ACTIVE, 0]);
                }
                return;
            }
        }
        llRequestPermissions(mySitter, PERMISSION_CONTROL_CAMERA);
    }
}
default
{
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_CONTROL_CAMERA)
        {
            set_camera(FALSE);
        }
    }
    state_entry()
    {
        SCRIPT_CHANNEL = (integer)llGetSubString(llGetScriptName(), llSubStringIndex(llGetScriptName(), " "), -1);
        notecard_key = llGetInventoryKey(notecard_name);
        if (llGetInventoryType(notecard_name) == INVENTORY_NOTECARD)
        {
            Out(0, "Loading...");
            notecard_query = llGetNotecardLine(notecard_name, 0);
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (sender == llGetLinkNumber())
        {
            if (num == 90230 | num == 90231)
            {
                list data = llParseStringKeepNulls(id, ["|"], []);
                key this_controller = (key)llList2String(data, 0);
                key this_sitter = (key)llList2String(data, -1);
                if (this_sitter == mySitter)
                {
                    myPose = msg;
                    if (myPose == "RESET")
                    {
                        lastByButton = -1;
                        myPose = lastPose;
                    }
                    set_camera(TRUE);
                    if (num == 90230)
                    {
                        llMessageLinked(LINK_THIS, 90005, "", this_controller);
                    }
                }
            }
            else if (num == 90045)
            {
                list data = llParseStringKeepNulls(msg, ["|"], []);
                integer sitter = (integer)llList2String(data, 0);
                if (sitter == SCRIPT_CHANNEL)
                {
                    mySitter = id;
                    myPose = llList2String(data, 1);
                    lastPose = myPose;
                    set_camera(FALSE);
                }
            }
            else if (num == 90065)
            {
                if (id == mySitter)
                {
                    lastByButton = -1;
                    mySitter = NULL_KEY;
                }
                else
                {
                    llSleep(0.1);
                    set_camera(FALSE);
                }
            }
            else if (num == 90174 && (integer)msg == SCRIPT_CHANNEL)
            {
                integer i = llGetListLength(camera_triggers);
                integer index;
                while (~(index = llListFindList(camera_triggers, [myPose])))
                {
                    camera_triggers = llDeleteSubList(camera_triggers, index, index);
                    camera_settings = llDeleteSubList(camera_settings, index, index);
                }
                if (id != "none")
                {
                    camera_triggers += myPose;
                    camera_settings += (string)id;
                    llSay(0, "CAMERA saved to '" + myPose + "' for SITTER " + (string)SCRIPT_CHANNEL + ".");
                    llSay(0, "CAMERA " + myPose + "|" + (string)id);
                }
                else
                {
                    llSay(0, "CAMERA cleared from '" + myPose + "' for SITTER " + (string)SCRIPT_CHANNEL + ".");
                }
                set_camera(FALSE);
            }
            else if (num == 90020 && ((string)id == llGetScriptName() || (string)id + " " + msg == llGetScriptName()))
            {
                if ((integer)msg == SCRIPT_CHANNEL)
                {
                    integer i;
                    for (i = 0; i < llGetListLength(camera_triggers); i++)
                    {
                        Readout_Say("CAMERA " + llList2String(camera_triggers, i) + "|" + llList2String(camera_settings, i), msg);
                    }
                    llMessageLinked(LINK_THIS, 90021, msg, (string)id);
                }
            }
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(notecard_name) != notecard_key)
            {
                llResetScript();
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                Out(0, (string)llGetListLength(camera_triggers) + " Cameras Ready, Mem=" + (string)llGetFreeMemory());
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseStringKeepNulls(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                string part0 = llStringTrim(llList2String(parts, 0), STRING_TRIM);
                if (command == "SITTER")
                {
                    notecard_section = (integer)part0;
                }
                else if (notecard_section == SCRIPT_CHANNEL && command == "CAMERA")
                {
                    string part1 = llStringTrim(llDumpList2String(llList2List(parts, 1, -1), "|"), STRING_TRIM);
                    list sequence = llParseString2List(part1, ["|"], []);
                    camera_triggers += part0;
                    camera_settings += part1;
                }
                notecard_query = llGetNotecardLine(notecard_name, notecard_line += 1);
            }
        }
    }
}
