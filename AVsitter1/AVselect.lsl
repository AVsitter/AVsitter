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
 
string product_and_version = "AVsitter™ AVselect 1.62";
integer has_security;
integer has_texture;
integer has_color;
integer select_type;
list BUTTONS;
integer reading_notecard_section = -1;
key notecard_key;
key notecard_query;
string notecard_name = "AVpos";
list SITTERS;
list SYNCS;
integer menu_channel;
integer menu_handle;
integer menu_type;
integer variable1;
Owner_Say(string say)
{
    llOwnerSay(llGetScriptName() + ":" + say);
}
string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
menu(key av)
{
    integer sitter_index = llListFindList(SITTERS, [av]);
    if (sitter_index != -1)
    {
        list menu_buttons;
        integer i;
        for (i = 0; i < llGetListLength(BUTTONS); i++)
        {
            string avname = llKey2Name(llList2Key(SITTERS, i));
            if ((!select_type) && llList2Integer(SYNCS, i) == FALSE && avname != "" && av != llList2Key(SITTERS, i))
            {
                menu_buttons += "⊘" + llGetSubString(strReplace(avname, " Resident", " "), 0, 11);
            }
            else
            {
                menu_buttons += llList2String(BUTTONS, i);
            }
        }
        if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) != ZERO_VECTOR)
        {
            menu_buttons += "[ADJUST]";
        }
        llListenControl(menu_handle, TRUE);
        llDialog(av, "\n" + product_and_version + "\n" + llList2String(BUTTONS, sitter_index), order_buttons(menu_buttons), menu_channel);
    }
}
integer get_number_of_scripts()
{
    integer i = 1;
    while (llGetInventoryType("AVsit " + (string)i) == INVENTORY_SCRIPT)
    {
        i++;
    }
    return i;
}
default
{
    state_entry()
    {
        menu_channel = ((integer)llFrand(2147483646) + 1) * -1;
        menu_handle = llListen(menu_channel, "", "", "");
        llListenControl(menu_handle, FALSE);
        integer i;
        for (i = 0; i < get_number_of_scripts(); i++)
        {
            SITTERS += NULL_KEY;
            SYNCS += FALSE;
            BUTTONS += "SITTER " + (string)i;
        }
        notecard_key = llGetInventoryKey(notecard_name);
        Owner_Say("Reading " + notecard_name);
        notecard_query = llGetNotecardLine(notecard_name, variable1);
    }
    listen(integer listen_channel, string name, key id, string message)
    {
        integer av_index = llListFindList(SITTERS, [id]);
        integer button_index = llListFindList(BUTTONS, [message]);
        if (av_index != -1)
        {
            if (message == "[ADJUST]")
            {
                llMessageLinked(LINK_SET, 90006, "", id);
            }
            else if (llGetSubString(message, 0, 0) == "⊘" || (llList2Integer(SYNCS, button_index) == FALSE && llList2Key(SITTERS, button_index) != NULL_KEY && llList2Key(SITTERS, button_index) != id && (!select_type)))
            {
                menu(id);
            }
            else if (button_index != -1)
            {
                llMessageLinked(LINK_SET, 90030, (string)av_index, (string)button_index);
            }
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(notecard_name) != notecard_key || get_number_of_scripts() != llGetListLength(SITTERS))
            {
                llResetScript();
            }
        }
        if (change & CHANGED_LINK)
        {
            if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
            {
                llListenControl(menu_handle, FALSE);
            }
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90045)
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            integer index = llListFindList(SITTERS, [id]);
            if (index != -1)
            {
                if (llGetSubString(llList2String(data, 0), 0, 1) == "S:")
                {
                    SYNCS = llListReplaceList(SYNCS, [TRUE], index, index);
                }
                else
                {
                    SYNCS = llListReplaceList(SYNCS, [FALSE], index, index);
                }
            }
        }
        else if (num == 90065)
        {
            integer index = llListFindList(SITTERS, [id]);
            if (index != -1)
            {
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], index, index);
            }
        }
        else if (num == 90030)
        {
            SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
            SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)((string)id), (integer)((string)id));
        }
        else if (num == 90070)
        {
            SITTERS = llListReplaceList(SITTERS, [id], (integer)msg, (integer)msg);
        }
        else if (num == 90075)
        {
            SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
        }
        else if (num == 99899)
        {
            menu(id);
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                integer i;
                while (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) != ZERO_VECTOR)
                {
                    llUnSit(llGetLinkKey(llGetNumberOfPrims()));
                    llSleep(0.1);
                }
                Owner_Say("Ready");
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseString2List(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                string part0 = llList2String(parts, 0);
                if (command == "SITTER")
                {
                    reading_notecard_section = (integer)part0;
                    string button_text = llList2String(parts, 1);
                    if (reading_notecard_section < llGetListLength(SITTERS))
                    {
                        if (button_text != "" && llListFindList(BUTTONS, [button_text]) == -1)
                        {
                            BUTTONS = llListReplaceList(BUTTONS, [button_text], reading_notecard_section, reading_notecard_section);
                        }
                    }
                }
                else if (command == "MTYPE")
                {
                    menu_type = (integer)part0;
                }
                else if (command == "SELECT")
                {
                    select_type = (integer)part0;
                }
                else if (command == "POSE" || command == "SYNC")
                {
                    if (reading_notecard_section < llGetListLength(SITTERS) && reading_notecard_section != -1)
                    {
                        if (llList2String(BUTTONS, reading_notecard_section) == "SITTER " + (string)reading_notecard_section)
                        {
                            if (llStringLength(part0) > 23)
                            {
                                part0 = llGetSubString(part0, 0, 22);
                            }
                            if (llListFindList(BUTTONS, [part0]) == -1)
                            {
                                BUTTONS = llListReplaceList(BUTTONS, [part0], reading_notecard_section, reading_notecard_section);
                                reading_notecard_section = -1;
                            }
                        }
                    }
                }
                notecard_query = llGetNotecardLine(notecard_name, variable1 += 1);
            }
        }
    }
}
