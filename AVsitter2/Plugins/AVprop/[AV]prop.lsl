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
key key_request;
integer comm_channel;
integer WARN = 1;
key notecard_key;
key notecard_query;
integer notecard_line;
integer notecard_section;
integer listen_handle;
list prop_triggers;
list prop_types;
list prop_objects;
list prop_positions;
list prop_rotations;
list prop_groups;
list prop_points;
list sequential_prop_groups;
integer HAVENTNAGGED = TRUE;
list SITTERS;
list SITTER_POSES;
list ATTACH_POINTS =
    [ ATTACH_CHEST,             "chest"
    , ATTACH_HEAD,              "head"
    , ATTACH_LSHOULDER,         "left shoulder"
    , ATTACH_RSHOULDER,         "right shoulder"
    , ATTACH_LHAND,             "left hand"
    , ATTACH_RHAND,             "right hand"
    , ATTACH_LFOOT,             "left foot"
    , ATTACH_RFOOT,             "right foot"
    , ATTACH_BACK,              "back"
    , ATTACH_PELVIS,            "pelvis"
    , ATTACH_MOUTH,             "mouth"
    , ATTACH_CHIN,              "chin"
    , ATTACH_LEAR,              "left ear"
    , ATTACH_REAR,              "right ear"
    , ATTACH_LEYE,              "left eye"
    , ATTACH_REYE,              "right eye"
    , ATTACH_NOSE,              "nose"
    , ATTACH_RUARM,             "right upper arm"
    , ATTACH_RLARM,             "right lower arm"
    , ATTACH_LUARM,             "left upper arm"
    , ATTACH_LLARM,             "left lower arm"
    , ATTACH_RHIP,              "right hip"
    , ATTACH_RULEG,             "right upper leg"
    , ATTACH_RLLEG,             "right lower leg"
    , ATTACH_LHIP,              "left hip"
    , ATTACH_LULEG,             "left upper leg"
    , ATTACH_LLLEG,             "left lower leg"
    , ATTACH_BELLY,             "stomach"
    , ATTACH_LEFT_PEC,          "left pectoral"
    , ATTACH_RIGHT_PEC,         "right pectoral"
    , ATTACH_HUD_CENTER_2,      "HUD center 2"
    , ATTACH_HUD_TOP_RIGHT,     "HUD top right"
    , ATTACH_HUD_TOP_CENTER,    "HUD top"
    , ATTACH_HUD_TOP_LEFT,      "HUD top left"
    , ATTACH_HUD_CENTER_1,      "HUD center"
    , ATTACH_HUD_BOTTOM_LEFT,   "HUD bottom left"
    , ATTACH_HUD_BOTTOM,        "HUD bottom"
    , ATTACH_HUD_BOTTOM_RIGHT,  "HUD bottom right"
    , ATTACH_NECK,              "neck"
    , ATTACH_AVATAR_CENTER,     "avatar center"
    ];

integer verbose = 5;

Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
    }
}

integer IsInteger(string data)
{
    return llParseString2List((string)llParseString2List(data, ["8", "9"], []), ["0", "1", "2", "3", "4", "5", "6", "7"], []) == [] && data != "";
}

integer get_number_of_scripts()
{
    integer i = 1;
    while (llGetInventoryType(main_script + " " + (string)i) == INVENTORY_SCRIPT)
    {
        i++;
    }
    return i;
}

integer get_point(string text)
{
    integer i;
    for (i = 1; i < llGetListLength(ATTACH_POINTS); i = i + 2)
    {
        if (~llSubStringIndex(llToUpper(text), llToUpper(llList2String(ATTACH_POINTS, i))))
        {
            return llList2Integer(ATTACH_POINTS, i - 1);
        }
    }
    return 0;
}

rez_prop(integer index)
{
    integer type = llList2Integer(prop_types, index);
    string object = llList2String(prop_objects, index);
    if (object != "")
    {
        vector pos = llList2Vector(prop_positions, index) * llGetRot() + llGetPos();
        rotation rot = llEuler2Rot(llList2Vector(prop_rotations, index) * DEG_TO_RAD) * llGetRot();
        integer pt = get_point(llList2String(prop_points, index));
        string point = (string)pt;
        if (llStringLength(point) == 1)
        {
            point = "0" + point;
        }
        string prop_id = (string)index;
        if (llStringLength(prop_id) == 1)
        {
            prop_id = "0" + prop_id;
        }
        integer int = (integer)((string)comm_channel + prop_id + point + (string)type);
        if (llGetInventoryType(object) != INVENTORY_OBJECT)
        {
            llSay(0, "Could not find prop '" + object + "'.");
            return;
        }
        integer perms = llGetInventoryPermMask(object, MASK_NEXT);
        string next = "  for NEXT owner";
        if (WARN == 2)
        {
            next = "";
            perms = llGetInventoryPermMask(object, MASK_OWNER);
        }
        if (type == 0 || type == 3)
        {
            if (!(perms & PERM_COPY))
            {
                llSay(0, "Can't rez '" + object + "'. Props and their content must be COPY-OK" + next);
                return;
            }
        }
        else if (type > 0)
        {
            if ((!(perms & PERM_COPY)) || (!(perms & PERM_TRANSFER)))
            {
                llSay(0, "Can't rez '" + object + "'. Attachment props and their content must be COPY-TRANSFER" + next);
                return;
            }
        }
        llRezAtRoot(object, pos, ZERO_VECTOR, rot, int);
    }
}

send_command(string command)
{
    llRegionSay(comm_channel, command);
    llSay(comm_channel, command);
}

remove_all_props()
{
    send_command("REM_ALL");
}

rez_props_by_trigger(string pose_name)
{
    integer i;
    for (; i < llGetListLength(prop_triggers); i++)
    {
        if (llList2String(prop_triggers, i) == pose_name)
        {
            rez_prop(i);
        }
    }
}

list get_props_by_pose(string pose_name)
{
    list props_to_do;
    integer i;
    for (; i < llGetListLength(prop_triggers); i++)
    {
        if (llList2String(prop_triggers, i) == pose_name)
        {
            props_to_do += i;
        }
    }
    return props_to_do;
}

remove_props_by_sitter(string sitter, integer remove_type3)
{
    list text;
    integer i;
    for (; i < llGetListLength(prop_triggers); i++)
    {
        if (llSubStringIndex(llList2String(prop_triggers, i), sitter + "|") == 0)
        {
            if (llList2Integer(prop_types, i) != 3 || remove_type3)
            {
                text += [i];
            }
        }
    }
    string command = "REM_INDEX";
    if (llGetInventoryType(main_script) != INVENTORY_SCRIPT)
    {
        command = "REM_WORLD";
    }
    if (text)
    {
        send_command(llDumpList2String([command] + text, "|"));
    }
}

remove_worn(key av)
{
    send_command(llDumpList2String(["REM_WORN", av], "|"));
}

remove_sitter_props_by_pose(string sitter_pose, integer remove_type3)
{
    list text;
    integer i;
    for (; i < llGetListLength(prop_triggers); i++)
    {
        if (llList2String(prop_triggers, i) == sitter_pose)
        {
            if (llList2Integer(prop_types, i) != 3 || remove_type3)
            {
                text += [i];
            }
        }
    }
    if (text)
    {
        send_command(llDumpList2String(["REM_INDEX"] + text, "|"));
    }
}
remove_sitter_props_by_pose_group(string msg)
{
    list props = get_props_by_pose(msg);
    list groups;
    integer i;
    for (; i < llGetListLength(props); i++)
    {
        string prop_group = llList2String(prop_groups, llList2Integer(props, i));
        if (!~llListFindList(groups, [prop_group]))
        {
            groups += prop_group;
            remove_props_by_group(llListFindList(sequential_prop_groups, [prop_group]));
        }
    }
}

remove_props_by_group(integer gp)
{
    list text;
    string group = llList2String(sequential_prop_groups, gp);
    integer i;
    for (; i < llGetListLength(prop_groups); i++)
    {
        if (llList2String(prop_groups, i) == group)
        {
            text += [i];
        }
    }
    string command = "REM_INDEX";
    if (llGetInventoryType(main_script) != INVENTORY_SCRIPT)
    {
        command = "REM_WORLD";
    }
    if (text)
    {
        send_command(llDumpList2String([command] + text, "|"));
    }
}

Readout_Say(string say)
{
    llSleep(0.2);
    llMessageLinked(LINK_THIS, 90022, say, ""); // dump to [AV]adjuster
}

init_sitters()
{
    SITTERS = [];
    SITTER_POSES = [];
    integer i;
    for (i = 0; i < get_number_of_scripts(); i++)
    {
        SITTERS += NULL_KEY;
        SITTER_POSES += "";
    }
}

init_channel()
{
    llListenRemove(listen_handle);
    comm_channel = ((integer)llFrand(8999) + 1000) * -1;
    listen_handle = llListen(comm_channel, "", "", "");
}

string element(string text, integer x)
{
    return llList2String(llParseStringKeepNulls(text, ["|"], []), x);
}

default
{
    state_entry()
    {
        Out(0, "Mem=" + (string)(65536 - llGetUsedMemory()));
        init_sitters();
        init_channel();
        notecard_key = llGetInventoryKey(notecard_name);
        if (llGetInventoryType(notecard_name) == INVENTORY_NOTECARD)
        {
            Out(0, "Loading...");
            notecard_query = llGetNotecardLine(notecard_name, 0);
        }
    }

    on_rez(integer start)
    {
        init_channel();
    }

    link_message(integer sender, integer num, string msg, key id)
    {
        if (sender == llGetLinkNumber())
        {
            if (num == 90045) // play pose
            {
                list data = llParseStringKeepNulls(msg, ["|"], []);
                integer sitter = (integer)llList2String(data, 0);
                if (id == llList2Key(SITTERS, sitter))
                {
                    remove_sitter_props_by_pose(llList2String(SITTER_POSES, sitter), FALSE);
                    string given_posename = llList2String(data, 1);
                    given_posename = (string)sitter + "|" + given_posename;
                    SITTER_POSES = llListReplaceList(SITTER_POSES, [given_posename], sitter, sitter);
                    remove_sitter_props_by_pose_group(given_posename);
                    rez_props_by_trigger(given_posename);
                }
            }
            else if (num == 90200 || num == 90220) // rez or clear prop with/without sending menu back
            {
                list ids = llParseStringKeepNulls(id, ["|"], []);
                key sitting_av_or_sitter = (key)llList2String(ids, -1);
                if (llGetInventoryType(main_script) != INVENTORY_SCRIPT)
                {
                    SITTERS = [sitting_av_or_sitter];
                }
                integer i;
                if (!llSubStringIndex(msg, "remprop_"))
                {
                    for (; i < llGetListLength(SITTERS); i++)
                    {
                        if (llList2Key(SITTERS, i) == sitting_av_or_sitter || id == "" || (string)sitting_av_or_sitter == (string)i)
                        {
                            remove_sitter_props_by_pose((string)i + "|" + llGetSubString(msg, 8, -1), TRUE);
                        }
                    }
                }
                else
                {
                    integer flag;
                    for (; i < llGetListLength(SITTERS); i++)
                    {
                        if (~llListFindList(prop_triggers, [(string)i + "|" + msg]))
                        {
                            flag = TRUE;
                        }
                    }
                    for (i = 0; i < llGetListLength(SITTERS); i++)
                    {
                        if (llList2Key(SITTERS, i) == sitting_av_or_sitter || id == "" || (string)sitting_av_or_sitter == (string)i)
                        {
                            integer index = llListFindList(prop_triggers, [(string)i + "|" + msg]);
                            if (!~index)
                            {
                                if (llGetInventoryType(main_script) != INVENTORY_SCRIPT)
                                {
                                    remove_all_props();
                                }
                                else if (!flag)
                                {
                                    remove_props_by_sitter((string)i, TRUE);
                                }
                            }
                            else
                            {
                                remove_sitter_props_by_pose_group((string)i + "|" + msg);
                                rez_props_by_trigger((string)i + "|" + msg);
                            }
                        }
                    }
                }
                if (sitting_av_or_sitter)
                {
                    if (num == 90200) // send menu back?
                    {
                        // send menu to same id
                        llMessageLinked(LINK_THIS, 90005, "", id);
                    }
                }
            }
            if (num == 90101) // menu choice
            {
                list data = llParseString2List(msg, ["|"], []);
                if (llList2String(data, 1) == "[SAVE]")
                {
                    llRegionSay(comm_channel, "PROPSEARCH");
                }
            }
            else if (num == 90065) // stand up
            {
                remove_props_by_sitter(msg, FALSE);
                remove_worn(id);
                integer index = llListFindList(SITTERS, [id]);
                if (~index)
                {
                    SITTERS = llListReplaceList(SITTERS, [NULL_KEY], index, index);
                }
            }
            else if (num == 90030) // swap
            {
                remove_props_by_sitter(msg, FALSE);
                remove_props_by_sitter((string)id, FALSE);
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)((string)id), (integer)((string)id));
            }
            else if (num == 90070) // update list of sitters
            {
                SITTERS = llListReplaceList(SITTERS, [id], (integer)msg, (integer)msg);
            }
            else if (num == 90171 || num == 90173) // [AV]adjuster/[AV]menu add PROP line
            {
                integer sitter;
                if (num == 90171) // [AV]adjuster?
                {
                    sitter = (integer)msg;
                    prop_triggers += [llList2String(SITTER_POSES, sitter)];
                }
                else
                {
                    sitter = 0;
                    SITTER_POSES = ["0|" + msg];
                    prop_triggers += "0|" + msg;
                }
                prop_types += 0;
                prop_objects += (string)id;
                string prop_group = (string)sitter + "|G1";
                prop_groups += prop_group;
                if (llListFindList(sequential_prop_groups, [prop_group]) == -1)
                {
                    sequential_prop_groups += prop_group;
                }
                prop_positions += <0,0,1>;
                prop_rotations += <0,0,0>;
                prop_points += "";
                rez_prop(llGetListLength(prop_triggers) - 1);
                string text = "PROP added: '" + (string)id + "' to '" + element(llList2String(SITTER_POSES, sitter), 1) + "'";
                if (llGetListLength(SITTERS) > 1)
                {
                    text += " for SITTER " + (string)sitter;
                }
                llSay(0, text);
                llSay(0, "Position your prop and click [SAVE].");
            }
            else if (num == 90020 && (string)id == llGetScriptName()) // dump our settings
            {
                integer i;
                for (; i < llGetListLength(prop_triggers); i++)
                {
                    if (llSubStringIndex(llList2String(prop_triggers, i), msg + "|") == 0)
                    {
                        string type = (string)llList2Integer(prop_types, i);
                        if (type == "0")
                        {
                            type = "";
                        }
                        Readout_Say("PROP" + type + " " + llDumpList2String([element(llList2String(prop_triggers, i), 1), llList2String(prop_objects, i), element(llList2String(prop_groups, i), 1), llList2String(prop_positions, i), llList2String(prop_rotations, i), llList2String(prop_points, i)], "|"));
                    }
                }
                llMessageLinked(LINK_THIS, 90021, msg, llGetScriptName()); // notify finished dumping
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(notecard_name) != notecard_key)
            {
                remove_all_props();
                llResetScript();
            }
            else if (get_number_of_scripts() != llGetListLength(SITTERS))
            {
                init_sitters();
            }
        }
        else if (change & CHANGED_LINK)
        {
            if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
            {
                HAVENTNAGGED = TRUE;
                if (llGetInventoryType(main_script) == INVENTORY_SCRIPT)
                {
                    remove_all_props();
                }
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        list data = llParseStringKeepNulls(message, ["|"], []);
        if (llList2String(data, 0) == "SAVEPROP")
        {
            integer index = (integer)llList2String(data, 1);
            if (index >= 0 && index < llGetListLength(prop_triggers))
            {
                if (llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0) != ZERO_VECTOR)
                {
                    list details = [OBJECT_POS, OBJECT_ROT];
                    rotation f = llList2Rot(details = llGetObjectDetails(llGetKey(), details) + llGetObjectDetails(id, details), 1);
                    vector target_rot = llRot2Euler(llList2Rot(details, 3) / f) * RAD_TO_DEG;
                    vector target_pos = (llList2Vector(details, 2) - llList2Vector(details, 0)) / f;
                    prop_positions = llListReplaceList(prop_positions, [target_pos], index, index);
                    prop_rotations = llListReplaceList(prop_rotations, [target_rot], index, index);
                    string type = llList2String(prop_types, index);
                    if (type == "0")
                    {
                        type = "";
                    }
                    string text = "PROP Saved to memory, SITTER " + element(llList2String(prop_triggers, index), 0) + ": PROP" + type + " " + element(llList2String(prop_triggers, index), 1) + "|" + name + "|" + element(llList2String(prop_groups, index), 1) + "|" + (string)target_pos + "|" + (string)target_rot + "|" + llList2String(prop_points, index);
                    llSay(0, text);
                }
            }
            else
            {
                Out(0, "Error, cannot find prop: " + name);
            }
        }
        else if (llList2String(data, 0) == "ATTACHED" || llList2String(data, 0) == "DETACHED" || llList2String(data, 0) == "REZ" || llList2String(data, 0) == "DEREZ")
        {
            integer prop_index = (integer)llList2String(data, 1);
            integer sitter = (integer)llList2String(llParseStringKeepNulls(llList2String(prop_triggers, prop_index), ["|"], []), 0);
            key sitter_key = llList2Key(SITTERS, sitter);
            if (sitter_key != NULL_KEY && llList2String(data, 0) == "REZ" && llList2Integer(prop_types, prop_index) == 1)
            {
                llSay(comm_channel, "ATTACHTO|" + (string)sitter_key + "|" + (string)id);
            }
            // send prop event notification
            llMessageLinked(LINK_SET, 90500, llDumpList2String([llList2String(data, 0), llList2String(prop_triggers, prop_index), llList2String(prop_objects, prop_index), llList2String(llParseStringKeepNulls(llList2String(prop_groups, prop_index), ["|"], []), 1), id], "|"), sitter_key);
        }
        else if (llList2String(data, 0) == "NAG" && HAVENTNAGGED && (!llGetAttached()))
        {
            llRegionSayTo(llGetOwner(), 0, "To enable auto-attachments, please enable the experience '" + llList2String(data, 1) + "' by Code Violet in 'About Land'.");
            HAVENTNAGGED = FALSE;
        }
    }

    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                Out(0, (string)llGetListLength(prop_triggers) + " Props Ready, Mem=" + (string)llGetFreeMemory());
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseStringKeepNulls(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                if (command == "SITTER")
                {
                    notecard_section = (integer)llList2String(parts, 0);
                }
                else if (llGetSubString(command, 0, 3) == "PROP")
                {
                    if (llGetListLength(prop_triggers) == 100)
                    {
                        Out(0, "Max props is 100, could not add prop!"); // the real limit is less than this due to memory running out first :)
                    }
                    else
                    {
                        integer prop_type;
                        if (command == "PROP1")
                        {
                            prop_type = 1;
                        }
                        else if (command == "PROP2")
                        {
                            prop_type = 2;
                        }
                        else if (command == "PROP3")
                        {
                            prop_type = 3;
                        }
                        prop_triggers += [(string)notecard_section + "|" + llList2String(parts, 0)];
                        prop_types += prop_type;
                        prop_objects += llList2String(parts, 1);
                        string prop_group = (string)notecard_section + "|" + llList2String(parts, 2);
                        prop_groups += prop_group;
                        if (llListFindList(sequential_prop_groups, [prop_group]) == -1)
                        {
                            sequential_prop_groups += prop_group;
                        }
                        prop_positions += (vector)llList2String(parts, 3);
                        prop_rotations += (vector)llList2String(parts, 4);
                        prop_points += llList2String(parts, 5);
                    }
                }
                else if (command == "WARN")
                {
                    WARN = (integer)llList2String(parts, 0);
                }
                notecard_query = llGetNotecardLine(notecard_name, notecard_line += 1);
            }
        }
    }
}
