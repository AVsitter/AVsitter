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
 
string product = "AVsitter™ seat select";
string version = "2.2";
integer select_type;
list BUTTONS;
integer reading_notecard_section = -1;
key notecard_key;
key notecard_query;
string notecard_name = "AVpos";
string main_script = "[AV]sitA";
string adjust_script = "[AV]adjuster";
string helper_object = "[AV]helper";
string CUSTOM_TEXT;
list SITTERS;
list SYNCS;
integer menu_channel;
integer menu_handle;
integer menu_type;
integer variable1;
integer verbose = 0;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
    }
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
            if ((!select_type) && llList2Integer(SYNCS, i) == FALSE || select_type == 2 && avname != "" && av != llList2Key(SITTERS, i))
            {
                menu_buttons += "⊘" + llGetSubString(strReplace(avname, " Resident", " "), 0, 11);
            }
            else
            {
                menu_buttons += llList2String(BUTTONS, i);
            }
        }
        while ((llGetListLength(menu_buttons) + 1) % 3)
        {
            menu_buttons += " ";
        }
        menu_buttons += "[ADJUST]";
        llListenControl(menu_handle, TRUE);
        llDialog(av, product + " " + version + "\n\n" + CUSTOM_TEXT + "[" + llList2String(BUTTONS, sitter_index) + "]", order_buttons(menu_buttons), menu_channel);
    }
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
            BUTTONS += "Sitter " + (string)i;
        }
        notecard_key = llGetInventoryKey(notecard_name);
        Out(0, "Loading...");
        notecard_query = llGetNotecardLine(notecard_name, variable1);
    }
    listen(integer listen_channel, string name, key id, string message)
    {
        integer av_index = llListFindList(SITTERS, [id]);
        integer button_index = llListFindList(BUTTONS, [message]);
        if (av_index != -1)
        {
            if (message == "[ADJUST]" || message == "[HELPER]")
            {
                llMessageLinked(LINK_SET, 90101, llDumpList2String(["X", message, id], "|"), id);
            }
            else if (llGetSubString(message, 0, 0) == "⊘" || ((!select_type) && llList2Integer(SYNCS, button_index) == FALSE && llList2Key(SITTERS, button_index) != NULL_KEY && llList2Key(SITTERS, button_index) != id))
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
        if (sender == llGetLinkNumber())
        {
            if (num == 90055)
            {
                list data = llParseStringKeepNulls(id, ["|"], []);
                if (llGetSubString(llList2String(data, 0), 0, 1) != "P:")
                {
                    SYNCS = llListReplaceList(SYNCS, [TRUE], (integer)msg, (integer)msg);
                }
                else
                {
                    SYNCS = llListReplaceList(SYNCS, [FALSE], (integer)msg, (integer)msg);
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
            else if (num == 90009)
            {
                menu(id);
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                integer i;
                Out(0, "Ready");
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseString2List(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                string part0 = llList2String(parts, 0);
                if (command == "TEXT")
                {
                    CUSTOM_TEXT = llDumpList2String(llParseStringKeepNulls(part0, ["\\n"], []), "\n") + "\n";
                }
                else if (command == "SITTER")
                {
                    reading_notecard_section = (integer)part0;
                    string button_text = llList2String(parts, 1);
                    if (reading_notecard_section < llGetListLength(SITTERS))
                    {
                        if (button_text != "" && llListFindList(BUTTONS, [button_text]) == -1)
                        {
                            BUTTONS = llListReplaceList(BUTTONS, [button_text], reading_notecard_section, reading_notecard_section);
                            reading_notecard_section = -1;
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
                        if (llList2String(BUTTONS, reading_notecard_section) == "Sitter " + (string)reading_notecard_section)
                        {
                            part0 = llGetSubString(part0, 0, 22);
                            if (llListFindList(BUTTONS, [part0]) == -1)
                            {
                                BUTTONS = llListReplaceList(BUTTONS, [part0], reading_notecard_section, reading_notecard_section);
                            }
                        }
                        else
                        {
                            BUTTONS = llListReplaceList(BUTTONS, ["Sitter " + (string)reading_notecard_section], reading_notecard_section, reading_notecard_section);
                            reading_notecard_section = -1;
                        }
                    }
                }
                notecard_query = llGetNotecardLine(notecard_name, variable1 += 1);
            }
        }
    }
}
