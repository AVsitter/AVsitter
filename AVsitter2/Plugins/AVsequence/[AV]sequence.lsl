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
 
string product = "AVsitter™ sequence";
string version = "2.2";
string main_script = "[AV]sitA";
list SITTERS;
integer DEBUG;
string notecard_name = "[AV]sequence_settings";
integer notecard_line;
key notecard_query;
key notecard_key;
list SEQUENCE_DATA_NAMES;
list SEQUENCE_DATA_ACTIONS;
list SEQUENCE_DATA_DATAS;
string CURRENT_SEQUENCE_NAME;
list CURRENT_SEQUENCE_ACTIONS;
list CURRENT_SEQUENCE_DATAS;
integer SEQUENCE_LINKNUMBER = 90210;
integer SEQUENCE_POINTER = -1;
integer sequence_running;
key CONTROLLER;
key CONTROLLED;
integer menu_channel;
integer menu_handle;
integer playsounds = TRUE;
integer no_waits_yet;
integer verbose = 1;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
    }
}
string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls(str, [search], []), replace);
}
DEBUGSay(integer level, string out)
{
    if (DEBUG >= level)
    {
        llWhisper(0, out);
    }
}
run_sequence()
{
    while (SEQUENCE_POINTER >= 0)
    {
        string command = llList2String(CURRENT_SEQUENCE_ACTIONS, SEQUENCE_POINTER);
        string data = llList2String(CURRENT_SEQUENCE_DATAS, SEQUENCE_POINTER);
        list data_list = llParseStringKeepNulls(data, ["|"], []);
        if (command == "PLAY")
        {
            DEBUGSay(2, "Playing pose " + data);
            llMessageLinked(LINK_THIS, 90003, data, "");
            llSleep(0.5);
        }
        else if (command == "SAY")
        {
            llSay(0, parse_text(data));
        }
        else if (command == "WHISPER")
        {
            llWhisper(0, parse_text(data));
        }
        else if (command == "SOUND")
        {
            if (playsounds)
            {
                string sound = llList2String(data_list, 0);
                float volume = (float)llList2String(data_list, 1);
                llPlaySound(sound, volume);
                DEBUGSay(2, "Playing sound " + sound + " at volume " + (string)volume);
            }
        }
        else if (command == "LOOP")
        {
            no_waits_yet = FALSE;
            if (SEQUENCE_POINTER == llGetListLength(CURRENT_SEQUENCE_ACTIONS) - 1)
            {
                SEQUENCE_POINTER = -1;
                DEBUGSay(2, "Looping back to start of sequence");
                if (sequence_running)
                {
                    llSetTimerEvent(0.1);
                }
                return;
            }
        }
        else if (command == "WAIT")
        {
            if (sequence_running)
            {
                float time = (float)data;
                DEBUGSay(2, "Waiting for " + (string)time + " seconds");
                llSetTimerEvent(time);
                if (time >= 2)
                {
                    integer found;
                    integer next_POINTER = SEQUENCE_POINTER;
                    while (next_POINTER++ < llGetListLength(CURRENT_SEQUENCE_ACTIONS) && found == FALSE)
                    {
                        string next_command = llList2String(CURRENT_SEQUENCE_ACTIONS, SEQUENCE_POINTER + 1);
                        if (next_command == "WAIT" || next_command == "SOUND")
                        {
                            found = TRUE;
                            if (next_command == "SOUND")
                            {
                                list next_data_list = llParseStringKeepNulls(llList2String(CURRENT_SEQUENCE_DATAS, next_POINTER), ["|"], []);
                                string sound = llList2String(next_data_list, 0);
                                DEBUGSay(2, "Preloading sound " + sound);
                                llPreloadSound(sound);
                            }
                        }
                    }
                }
                no_waits_yet = FALSE;
            }
            return;
        }
        if (++SEQUENCE_POINTER >= llGetListLength(CURRENT_SEQUENCE_ACTIONS))
        {
            integer index = llListFindList(CURRENT_SEQUENCE_ACTIONS, ["LOOP"]);
            if (index != -1)
            {
                SEQUENCE_POINTER = index;
                DEBUGSay(2, "Looping back to line " + (string)SEQUENCE_POINTER + " of sequence");
                if (sequence_running)
                {
                    llSetTimerEvent(0.1);
                }
                return;
            }
            else
            {
                stop_sequence(FALSE);
                return;
            }
        }
    }
}
integer get_number_of_scripts()
{
    integer i;
    while (llGetInventoryType(main_script + " " + (string)(++i)) == INVENTORY_SCRIPT)
        ;
    return i;
}
string parse_text(string say)
{
    integer i;
    for (i = 0; i < llGetListLength(SITTERS); i++)
    {
        string sitter_name = llList2String(llParseString2List(llKey2Name(llList2String(SITTERS, i)), [" "], []), 0);
        if (sitter_name == "")
        {
            sitter_name = "nobody";
        }
        say = strReplace(say, "/" + (string)i, sitter_name);
    }
    return say;
}
start_sequence(integer index)
{
    no_waits_yet = (sequence_running = TRUE);
    SEQUENCE_POINTER = 0;
    CURRENT_SEQUENCE_NAME = llList2String(SEQUENCE_DATA_NAMES, index);
    CURRENT_SEQUENCE_ACTIONS = llParseStringKeepNulls(llList2String(SEQUENCE_DATA_ACTIONS, index), ["◆"], []);
    CURRENT_SEQUENCE_DATAS = llParseStringKeepNulls(llList2String(SEQUENCE_DATA_DATAS, index), ["◆"], []);
    DEBUGSay(1, "Sequence '" + CURRENT_SEQUENCE_NAME + "' Started!");
}
stop_sequence(integer stopSound)
{
    if (sequence_running)
    {
        DEBUGSay(1, "Sequence '" + CURRENT_SEQUENCE_NAME + "' Ended!");
    }
    sequence_running = FALSE;
    SEQUENCE_POINTER = -1;
    llSetTimerEvent(0);
    if (stopSound && (~llListFindList(CURRENT_SEQUENCE_ACTIONS, ["SOUND"])))
    {
        llStopSound();
    }
}
sequence_control()
{
    llListenRemove(menu_handle);
    menu_channel = ((integer)llFrand(2147483646) + 1) * -1;
    string pauseplay = "▶";
    if (sequence_running)
    {
        pauseplay = "▮▮";
    }
    list menu_items = ["◀◀", pauseplay, "▶▶"];
    menu_handle = llListen(menu_channel, "", CONTROLLER, "");
    llDialog(CONTROLLER, product + " " + version + "\n\n[" + CURRENT_SEQUENCE_NAME + "]\n◀◀ = previous anim in sequence.\n▮▮ = pause sequence.\n▶▶ = skip to next anim in sequence.", order_buttons(["[BACK]"] + menu_items), menu_channel);
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
commit_sequence_data()
{
    SEQUENCE_DATA_NAMES += CURRENT_SEQUENCE_NAME;
    SEQUENCE_DATA_ACTIONS += llDumpList2String(CURRENT_SEQUENCE_ACTIONS, "◆");
    SEQUENCE_DATA_DATAS += llDumpList2String(CURRENT_SEQUENCE_DATAS, "◆");
}
default
{
    state_entry()
    {
        notecard_key = llGetInventoryKey(notecard_name);
        if (llGetInventoryType(notecard_name) == INVENTORY_NOTECARD)
        {
            Out(0, "Loading...");
            notecard_query = llGetNotecardLine(notecard_name, notecard_line);
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
                commit_sequence_data();
                state running;
            }
            else
            {
                list datalist = llParseString2List(data, [" "], []);
                string command = llList2String(datalist, 0);
                data = llStringTrim(llDumpList2String(llList2List(datalist, 1, -1), " "), STRING_TRIM);
                list commands = ["PLAY", "WAIT", "SAY", "WHISPER", "SOUND", "LOOP"];
                if (command == "DEBUG")
                {
                    DEBUG = (integer)data;
                }
                else if (command == "SEQUENCE")
                {
                    if (CURRENT_SEQUENCE_NAME)
                    {
                        commit_sequence_data();
                    }
                    CURRENT_SEQUENCE_NAME = data;
                    CURRENT_SEQUENCE_ACTIONS = [];
                    CURRENT_SEQUENCE_DATAS = [];
                }
                else if (llListFindList(commands, [command]) != -1)
                {
                    CURRENT_SEQUENCE_ACTIONS += command;
                    CURRENT_SEQUENCE_DATAS += data;
                }
                notecard_query = llGetNotecardLine(notecard_name, ++notecard_line);
            }
        }
    }
}
state running
{
    state_entry()
    {
        Out(0, (string)llGetListLength(SEQUENCE_DATA_NAMES) + " Sequences Ready, Mem=" + (string)(65536 - llGetUsedMemory()));
        integer i;
        for (i = 0; i < get_number_of_scripts(); i++)
        {
            SITTERS += NULL_KEY;
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (sender == llGetLinkNumber())
        {
            if (num == 90065)
            {
                integer index = llListFindList(SITTERS, [id]);
                if (index != -1)
                {
                    SITTERS = llListReplaceList(SITTERS, [NULL_KEY], index, index);
                }
                stop_sequence(TRUE);
            }
            else if (num == 90030)
            {
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)((string)id), (integer)((string)id));
                stop_sequence(TRUE);
            }
            else if (num == 90070)
            {
                SITTERS = llListReplaceList(SITTERS, [id], (integer)msg, (integer)msg);
            }
            else if (num == 90000)
            {
                stop_sequence(TRUE);
                integer index = llListFindList(SEQUENCE_DATA_NAMES, [msg]);
                if (index != -1)
                {
                    start_sequence(index);
                    run_sequence();
                }
            }
            else if (num == 90205)
            {
                llMessageLinked(LINK_SET, 90005, "", id);
                playsounds = (!playsounds);
                if (playsounds)
                {
                    llSay(0, "Sounds ON");
                }
                else
                {
                    llSay(0, "Sounds OFF");
                    llStopSound();
                }
            }
            else if (num == SEQUENCE_LINKNUMBER)
            {
                stop_sequence(TRUE);
                list data = llParseStringKeepNulls(id, ["|"], []);
                CONTROLLER = (key)llList2String(data, 0);
                CONTROLLED = (key)llList2String(data, -1);
                integer index = llListFindList(SEQUENCE_DATA_NAMES, [msg]);
                if (index != -1)
                {
                    start_sequence(index);
                    if ((~llListFindList(CURRENT_SEQUENCE_ACTIONS, ["WAIT"])) && (~llListFindList(CURRENT_SEQUENCE_ACTIONS, ["PLAY"])))
                    {
                        sequence_control();
                    }
                    else
                    {
                        llMessageLinked(LINK_SET, 90005, "", id);
                    }
                    run_sequence();
                }
            }
        }
    }
    listen(integer listen_channel, string name, key id, string msg)
    {
        if (msg == "▮▮")
        {
            sequence_running = FALSE;
            llSetTimerEvent(0);
            DEBUGSay(1, "Sequence '" + CURRENT_SEQUENCE_NAME + "' Paused!");
        }
        else if (msg == "▶")
        {
            sequence_running = TRUE;
            SEQUENCE_POINTER++;
            DEBUGSay(1, "Sequence '" + CURRENT_SEQUENCE_NAME + "' Resumed!");
            run_sequence();
        }
        else if (msg == "▶▶")
        {
            SEQUENCE_POINTER++;
            run_sequence();
        }
        else if (msg == "◀◀")
        {
            integer count_waits;
            while (SEQUENCE_POINTER > -1 && count_waits < 2)
            {
                SEQUENCE_POINTER--;
                if (llList2String(CURRENT_SEQUENCE_ACTIONS, SEQUENCE_POINTER) == "WAIT")
                {
                    count_waits++;
                }
            }
            SEQUENCE_POINTER++;
            run_sequence();
        }
        else if (msg == "[BACK]")
        {
            llMessageLinked(LINK_SET, 90005, "", (string)id + "|" + (string)CONTROLLED);
            return;
        }
        sequence_control();
    }
    timer()
    {
        llSetTimerEvent(0);
        SEQUENCE_POINTER++;
        run_sequence();
    }
    on_rez(integer start)
    {
        playsounds = TRUE;
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
        }
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(notecard_name) != notecard_key || get_number_of_scripts() != llGetListLength(SITTERS))
            {
                llResetScript();
            }
        }
    }
}
