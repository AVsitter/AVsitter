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
 
string product = "AVsitter2 MLP converter";
string version = "2.2";
string notecard_basename = "AVpos";
list NOTECARDS;
list PROPS_NOTECARDS;
string notecard_name;
key notecard_query;
integer notecard_line;
integer notecard_pointer;
integer animator_count;
integer animator_total;
list ommit = ["default", "stand"];
integer verbose = 0;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
    }
}
string FormatFloat(float f, integer num_decimals)
{
    float rounding = (float)(".5e-" + (string)num_decimals) - 5e-07;
    if (f < 0.)
        f -= rounding;
    else
        f += rounding;
    string ret = llGetSubString((string)f, 0, num_decimals - (!num_decimals) - 7);
    if (llSubStringIndex(ret, ".") != -1)
    {
        while (llGetSubString(ret, -1, -1) == "0")
        {
            ret = llGetSubString(ret, 0, -2);
        }
    }
    if (llGetSubString(ret, -1, -1) == ".")
    {
        ret = llGetSubString(ret, 0, -2);
    }
    return ret;
}
finish()
{
    if (llSubStringIndex(llGetObjectName(), "Utilities") == -1) // remove it except from Utilities box
    {
        Out(0, "Removing script");
        llRemoveInventory(llGetScriptName());
    }
}
get_notecards()
{
    integer i;
    for (i = 0; i < llGetInventoryNumber(INVENTORY_NOTECARD); i++)
    {
        string name = llGetInventoryName(INVENTORY_NOTECARD, i);
        if (llGetSubString(name, 0, 9) == ".MENUITEMS" || llGetSubString(name, 0, 9) == ".POSITIONS")
        {
            NOTECARDS += name;
        }
        else if (llGetSubString(name, 0, 5) == ".PROPS")
        {
            PROPS_NOTECARDS += name;
        }
    }
}
Readout_Say(string say)
{
    string objectname = llGetObjectName();
    llSetObjectName("");
    llRegionSayTo(llGetOwner(), 0, "◆" + say);
    llSetObjectName(objectname);
}
default
{
    state_entry()
    {
        Out(0, "Reading MLP notecards...");
        Readout_Say(" ");
        get_notecards();
        if (llGetListLength(NOTECARDS) > 0)
        {
            notecard_name = llList2String(NOTECARDS, notecard_pointer);
            Readout_Say("--✄--COPY BELOW INTO " + notecard_basename + " NOTECARD--✄--");
            Readout_Say(" ");
            Readout_Say("SITTER " + (string)animator_count);
            notecard_query = llGetNotecardLine(notecard_name, notecard_line);
        }
        else
        {
            Out(0, "No MLP notecards found!");
            finish();
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                if (llGetListLength(NOTECARDS) - notecard_pointer > 1)
                {
                    notecard_name = llList2String(NOTECARDS, notecard_pointer += 1);
                    notecard_query = llGetNotecardLine(notecard_name, notecard_line = 0);
                }
                else if (animator_count + 1 < animator_total)
                {
                    animator_count++;
                    Readout_Say(" ");
                    Readout_Say("SITTER " + (string)animator_count);
                    notecard_name = llList2String(NOTECARDS, notecard_pointer = 0);
                    notecard_query = llGetNotecardLine(notecard_name, notecard_line = 0);
                }
                else
                {
                    Readout_Say(" ");
                    Readout_Say("--✄--COPY ABOVE INTO " + notecard_basename + " NOTECARD--✄--");
                    finish();
                }
            }
            else
            {
                string out;
                data = llStringTrim(llList2String(llParseString2List(data, ["//"], []), 0), STRING_TRIM);
                if (llGetSubString(notecard_name, 0, 9) == ".MENUITEMS")
                {
                    string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                    list parts = llParseString2List(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                    if (command == "TOMENU" || command == "MENU")
                    {
                    }
                    else if (command == "POSE")
                    {
                        if (llListFindList(ommit, [llList2String(parts, 0)]) == -1)
                        {
                            if (llGetListLength(parts) - 1 > animator_total)
                            {
                                animator_total = llGetListLength(parts) - 1;
                            }
                            if (llGetListLength(parts) - animator_count > 1)
                            {
                                out = "POSE ";
                                if (llGetListLength(parts) + animator_count > 2)
                                {
                                    out = "SYNC ";
                                }
                                string pose = llStringTrim(llList2String(parts, animator_count + 1), STRING_TRIM);
                                pose = llList2String(llParseString2List(pose, ["::"], []), 0);
                                pose = llList2String(llParseString2List(pose, [";"], []), 0);
                                out += llStringTrim(llList2String(parts, 0), STRING_TRIM) + "|" + pose;
                                Readout_Say(out);
                            }
                        }
                    }
                }
                else
                {
                    if (llSubStringIndex(data, "{") != -1)
                    {
                        string command = llStringTrim(llGetSubString(data, llSubStringIndex(data, "{") + 1, llSubStringIndex(data, "}") - 1), STRING_TRIM);
                        if (llListFindList(ommit, [command]) == -1)
                        {
                            data = llDumpList2String(llParseString2List(data, [" "], [""]), "");
                            list parts = llParseString2List(data, ["<"], []);
                            if (llGetListLength(parts) > animator_count * 2 + 1)
                            {
                                vector pos = (vector)("<" + llList2String(parts, animator_count * 2 + 1));
                                vector rot = (vector)("<" + llList2String(parts, animator_count * 2 + 2));
                                pos += (vector)llGetObjectDesc();
                                string result = "<" + FormatFloat(pos.x, 3) + "," + FormatFloat(pos.y, 3) + "," + FormatFloat(pos.z, 3) + ">";
                                result += "<" + FormatFloat(rot.x, 1) + "," + FormatFloat(rot.y, 1) + "," + FormatFloat(rot.z, 1) + ">";
                                Readout_Say("{" + command + "}" + result);
                            }
                        }
                    }
                }
                notecard_query = llGetNotecardLine(notecard_name, notecard_line += 1);
            }
        }
    }
}
