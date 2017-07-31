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
 
integer is_running = TRUE;
list facial_anim_list = ["express_afraid_emote", "express_anger_emote", "express_laugh_emote", "express_bored_emote", "express_cry_emote", "express_embarrassed_emote", "express_sad_emote", "express_toothsmile", "express_smile", "express_surprise_emote", "express_worry_emote", "express_repulsed_emote", "express_shrug_emote", "express_wink_emote", "express_disdain", "express_frown", "express_kiss", "express_open_mouth", "express_tongue_out"];
integer IsInteger(string data)
{
    return llParseString2List((string)llParseString2List(data, ["8", "9"], []), ["0", "1", "2", "3", "4", "5", "6", "7"], []) == [] && data != "";
}
string version = "2.1";
string notecard_name = "AVpos";
string main_script = "[AV]sitA";
key key_request;
key notecard_key;
key notecard_query;
integer notecard_line;
integer notecard_section;
integer listen_handle;
list anim_triggers;
list anim_animsequences;
list running_uuid;
list running_sequence_indexes;
list running_pointers;
list SITTERS;
list SITTER_POSES;
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
string Key2Number(key objKey)
{
    return llGetSubString((string)llAbs((integer)("0x" + llGetSubString((string)objKey, -8, -1)) & 1073741823 ^ -1073741825), 6, -1);
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
string element(string text, integer x)
{
    return llList2String(llParseStringKeepNulls(text, ["|"], []), x);
}
start_sequence(integer sequence_index, key av)
{
    integer wasRunning = llListFindList(running_sequence_indexes, [sequence_index]);
    if (~wasRunning)
    {
        if (llList2Key(running_uuid, wasRunning) == av)
        {
            running_uuid = llListReplaceList(running_uuid, [], wasRunning, wasRunning);
            running_sequence_indexes = llListReplaceList(running_sequence_indexes, [], wasRunning, wasRunning);
            running_pointers = llListReplaceList(running_pointers, [], wasRunning, wasRunning);
        }
    }
    running_uuid += av;
    running_sequence_indexes += sequence_index;
    running_pointers += 0;
    llSetTimerEvent(0.01);
}
sequence()
{
    list anims;
    list uuids;
    integer i;
    while (i < llGetListLength(running_pointers))
    {
        integer sequence_pointer = llList2Integer(running_pointers, i);
        integer sequence_index = llList2Integer(running_sequence_indexes, i);
        list sequence = llParseStringKeepNulls(llList2String(anim_animsequences, sequence_index), ["|"], []);
        list sequence_anims = llList2ListStrided(sequence, 0, -1, 2);
        list sequence_durations = llList2ListStrided(llDeleteSubList(sequence, 0, 0), 0, -1, 2);
        integer sequence_length;
        integer j;
        while (j <= llGetListLength(sequence_durations))
        {
            integer lastDuration = (integer)llList2String(sequence_durations, j - 1);
            integer repeats = FALSE;
            if (lastDuration < 0)
            {
                repeats = TRUE;
                lastDuration = llAbs(lastDuration);
            }
            string anim;
            if (sequence_pointer == sequence_length)
            {
                anim = llStringTrim(llList2String(sequence_anims, j), STRING_TRIM);
            }
            else if (repeats && sequence_pointer > sequence_length - lastDuration && sequence_pointer < sequence_length - 1)
            {
                anim = llStringTrim(llList2String(sequence_anims, j - 1), STRING_TRIM);
            }
            if (anim)
            {
                if (IsInteger(anim))
                {
                    anim = llList2String(facial_anim_list, (integer)anim);
                }
                anims += anim;
                uuids += llList2Key(running_uuid, i);
            }
            if (llList2String(sequence_durations, j) == "-")
            {
                sequence_pointer++;
                jump go;
            }
            integer duration = llAbs((integer)llList2String(sequence_durations, j));
            sequence_length += duration;
            j++;
        }
        sequence_pointer++;
        if (sequence_pointer == sequence_length)
        {
            sequence_pointer = 0;
        }
        @go;
        running_pointers = llListReplaceList(running_pointers, [sequence_pointer], i, i);
        i++;
    }
    for (i = 0; i < llGetListLength(anims); i++)
    {
        if (llList2String(anims, i) != "none")
        {
            if (is_running)
            {
                llMessageLinked(LINK_THIS, 90001, llList2String(anims, i), llList2Key(uuids, i));
            }
        }
    }
}
remove_sequences(key id)
{
    integer index;
    while (~llListFindList(running_uuid, [id]))
    {
        index = llListFindList(running_uuid, [id]);
        running_uuid = llDeleteSubList(running_uuid, index, index);
        list sequence = llParseStringKeepNulls(llList2String(anim_animsequences, llList2Integer(running_sequence_indexes, index)), ["|"], []);
        running_sequence_indexes = llDeleteSubList(running_sequence_indexes, index, index);
        running_pointers = llDeleteSubList(running_pointers, index, index);
        while (sequence)
        {
            if ((!IsInteger(llList2String(sequence, 0))) && llList2String(sequence, 0) != "none")
            {
                llMessageLinked(LINK_THIS, 90002, llList2String(sequence, 0), id);
            }
            sequence = llDeleteSubList(sequence, 0, 1);
        }
    }
    if (llGetListLength(running_uuid) == 0)
    {
        llSetTimerEvent(0);
    }
}
default
{
    state_entry()
    {
        init_sitters();
        notecard_key = llGetInventoryKey(notecard_name);
        if (llGetInventoryType(notecard_name) == INVENTORY_NOTECARD)
        {
            Out(0, "Loading...");
            notecard_query = llGetNotecardLine(notecard_name, 0);
        }
    }
    timer()
    {
        sequence();
        llSetTimerEvent(1);
    }
    on_rez(integer start)
    {
        is_running = TRUE;
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90100)
        {
            list data = llParseString2List(msg, ["|"], []);
            if (llList2String(data, 1) == "[FACES]")
            {
                llMessageLinked(sender, 90101, llDumpList2String([llList2String(data, 0), "[ADJUST]", id], "|"), llList2String(data, 2));
                if (id == llGetOwner())
                {
                    is_running = (!is_running);
                    if (sender == llGetLinkNumber())
                    {
                        llRegionSayTo(id, 0, "Facial Expressions " + llList2String(["OFF", "ON"], is_running));
                    }
                }
                else
                {
                    llRegionSayTo(id, 0, "Sorry, only the owner can change this.");
                }
            }
        }
        else if (sender == llGetLinkNumber())
        {
            if (num == 90045)
            {
                list data = llParseStringKeepNulls(msg, ["|"], []);
                integer sitter = (integer)llList2String(data, 0);
                if (id == llList2Key(SITTERS, sitter))
                {
                    string given_posename = llList2String(data, 1);
                    SITTER_POSES = llListReplaceList(SITTER_POSES, [given_posename], sitter, sitter);
                    given_posename = (string)sitter + "|" + given_posename;
                    remove_sequences(id);
                    integer i;
                    while (i < llGetListLength(anim_triggers))
                    {
                        if (llList2String(anim_triggers, i) == given_posename)
                        {
                            integer reference = llListFindList(anim_triggers, [(string)sitter + "|" + llList2String(anim_animsequences, i)]);
                            if (!~reference)
                            {
                                reference = i;
                            }
                            start_sequence(reference, id);
                        }
                        i++;
                    }
                }
            }
            else if (num == 90065)
            {
                remove_sequences(id);
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
            else if (num == 90172)
            {
                is_running = TRUE;
                integer sitter = (integer)msg;
                remove_sequences(llList2Key(SITTERS, sitter));
                integer i = llGetListLength(anim_triggers);
                while (i > 0)
                {
                    i--;
                    if (llList2String(anim_triggers, i) == msg + "|" + llList2String(SITTER_POSES, sitter))
                    {
                        anim_triggers = llDeleteSubList(anim_triggers, i, i);
                        anim_animsequences = llDeleteSubList(anim_animsequences, i, i);
                    }
                }
                if (id != "none")
                {
                    anim_triggers += [msg + "|" + llList2String(SITTER_POSES, sitter)];
                    anim_animsequences += (string)id + "|1";
                    start_sequence(llGetListLength(anim_animsequences) - 1, llList2Key(SITTERS, sitter));
                    llSay(0, "FACE added: '" + (string)id + "' to '" + llList2String(SITTER_POSES, sitter) + "' for SITTER " + (string)sitter + ".");
                }
            }
            else if (num == 90020 && (string)id == llGetScriptName())
            {
                integer i;
                for (i = 0; i < llGetListLength(anim_triggers); i++)
                {
                    if (!llSubStringIndex(llList2String(anim_triggers, i), msg + "|"))
                    {
                        list trigger = llParseString2List(llList2String(anim_triggers, i), ["|"], []);
                        list sequence = llParseString2List(llList2String(anim_animsequences, i), ["|"], []);
                        integer x;
                        for (x = 0; x < llGetListLength(sequence); x += 2)
                        {
                            if (IsInteger(llList2String(sequence, x)))
                            {
                                sequence = llListReplaceList(sequence, [llList2String(facial_anim_list, (integer)llList2String(sequence, x))], x, x);
                            }
                        }
                        Readout_Say("ANIM " + llList2String(trigger, 1) + "|" + llDumpList2String(sequence, "|"), msg);
                    }
                }
                llMessageLinked(LINK_THIS, 90021, msg, llGetScriptName());
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
            else if (get_number_of_scripts() != llGetListLength(SITTERS))
            {
                init_sitters();
            }
        }
        else if (change & CHANGED_LINK)
        {
            if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
            {
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                Out(0, (string)llGetListLength(anim_triggers) + " Expressions Ready, Mem=" + (string)llGetFreeMemory());
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
                else if (command == "ANIM")
                {
                    string part1 = llStringTrim(llDumpList2String(llList2List(parts, 1, -1), "|"), STRING_TRIM);
                    list sequence = llParseString2List(part1, ["|"], []);
                    integer x;
                    for (x = 0; x < llGetListLength(sequence); x += 2)
                    {
                        integer index = llListFindList(facial_anim_list, [llList2String(sequence, x)]);
                        if (~index)
                        {
                            sequence = llListReplaceList(sequence, [index], x, x);
                        }
                    }
                    anim_triggers += [(string)notecard_section + "|" + part0];
                    anim_animsequences += llDumpList2String(sequence, "|");
                }
                notecard_query = llGetNotecardLine(notecard_name, notecard_line += 1);
            }
        }
    }
}
