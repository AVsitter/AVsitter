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
 
string product = "AVsitter™ Xcite!";
string version = "1.02";
string notecard_name = "[AV]Xcite_settings";
key notecard_key;
key notecard_query;
integer notecard_line;
integer verbose = 0;
list POSE_AND_SITTER;
list XCITE_COMMANDS;
list XCITE_TILT;
integer TIMER_DEFAULT = 30;
string CURRENT_POSE;
list TIMERS;
list SITTERS;
integer DEBUG;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "]:" + out);
    }
}
key key_request;
string parse_text(string say)
{
    integer i;
    for (i = 0; i < llGetListLength(SITTERS); i++)
    {
        string sitter_name = llList2String(llParseString2List(llKey2Name(llList2String(SITTERS, i)), [" "], []), 0);
        if (sitter_name == "")
        {
            sitter_name = "(nobody)";
        }
        say = strReplace(say, "/" + (string)i, sitter_name);
    }
    return say;
}
string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls(str, [search], []), replace);
}
default
{
    state_entry()
    {
        notecard_key = llGetInventoryKey(notecard_name);
        Out(0, "Loading...");
        notecard_query = llGetNotecardLine(notecard_name, 0);
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
        if (change & CHANGED_LINK)
        {
            if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
            {
                TIMERS = [];
            }
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (sender == llGetLinkNumber())
        {
            if (num == 90045)
            {
                string name = llKey2Name(id);
                if (name != "")
                {
                    integer i = llGetListLength(TIMERS);
                    while (i > 0)
                    {
                        i--;
                        if (!llSubStringIndex(llList2String(TIMERS, i), name + "|"))
                        {
                            TIMERS = llDeleteSubList(TIMERS, i, i);
                        }
                    }
                    llSetTimerEvent(TIMER_DEFAULT);
                    list data = llParseStringKeepNulls(msg, ["|"], []);
                    integer script_channel = (integer)llList2String(data, 0);
                    CURRENT_POSE = llList2String(data, 1);
                    SITTERS = llParseStringKeepNulls(llList2String(data, 4), ["@"], []);
                    integer index = llListFindList(POSE_AND_SITTER, [CURRENT_POSE + "|" + (string)script_channel]);
                    if (!~index)
                    {
                        index = llListFindList(POSE_AND_SITTER, [CURRENT_POSE + "|*"]);
                        if (!~index)
                        {
                            index = llListFindList(POSE_AND_SITTER, ["*|*"]);
                            if (!~index)
                            {
                                return;
                            }
                        }
                    }
                    if (llList2Integer(XCITE_TILT, index) != 0)
                    {
                        if (DEBUG)
                        {
                            Out(0, "Setting " + name + "'s tilt to " + (string)llList2Integer(XCITE_TILT, index));
                        }
                        llMessageLinked(LINK_SET, 20020, name + "|" + (string)llList2Integer(XCITE_TILT, index), "");
                    }
                    else
                    {
                        if (DEBUG)
                        {
                            Out(0, "Restoring " + name + "'s tilt.");
                        }
                        llMessageLinked(LINK_SET, 20014, name, "");
                    }
                    data = llParseStringKeepNulls(llList2String(XCITE_COMMANDS, index), ["|"], []);
                    TIMERS += [name + "|" + llList2String(data, 0) + "|" + llList2String(data, 1) + "||" + llList2String(data, 3)];
                    string commands = parse_text(llList2String(XCITE_COMMANDS, index));
                    llMessageLinked(LINK_SET, 20001, name + "|" + commands, NULL_KEY);
                    if (DEBUG)
                    {
                        Out(0, "Sending xcite commands: " + name + "|" + commands);
                    }
                }
            }
        }
    }
    timer()
    {
        integer i;
        for (; i < llGetListLength(TIMERS); i++)
        {
            llMessageLinked(LINK_SET, 20001, llList2String(TIMERS, i), NULL_KEY);
            if (DEBUG)
            {
                Out(0, "Sending xcite commands: " + llList2String(TIMERS, i));
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF || llStringTrim(llToLower(data), STRING_TRIM) == "end")
            {
                Out(0, (string)llGetListLength(POSE_AND_SITTER) + " items Ready, Mem=" + (string)llGetFreeMemory());
            }
            else
            {
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseStringKeepNulls(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                if (command == "TIMER")
                {
                    TIMER_DEFAULT = (integer)llList2String(parts, 0);
                }
                else if (command == "DEBUG")
                {
                    DEBUG = (integer)llList2String(parts, 0);
                }
                else if (command == "XCITE")
                {
                    POSE_AND_SITTER += [llStringTrim(llList2String(parts, 0), STRING_TRIM) + "|" + llList2String(parts, 1)];
                    XCITE_COMMANDS += [llList2String(parts, 2) + "|" + llList2String(parts, 3) + "|" + llList2String(parts, 4) + "|" + llList2String(parts, 5)];
                    XCITE_TILT += (integer)llList2String(parts, 6);
                }
                notecard_query = llGetNotecardLine(notecard_name, ++notecard_line);
            }
        }
    }
}
