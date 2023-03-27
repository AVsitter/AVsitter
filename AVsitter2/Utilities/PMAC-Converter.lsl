/**
 * PMAC-converter - Convert PMAC version notecards to AVsitter format
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright © the AVsitter Contributors (http://avsitter.github.io)
 * AVsitter™ is a trademark. For trademark use policy see:
 * https://avsitter.github.io/TRADEMARK.mediawiki
 *
 * Please consider supporting continued development of AVsitter and
 * receive automatic updates and other benefits! All details and user
 * instructions can be found at http://avsitter.github.io
 *
 * Based on AVsitter2 MLP converter
 *
 */
  /**
    @author: Zai Dium
    @name: PMAC-Converter
    @localfile: ?defaultpath\AVsitter\AVsitter2\Utilities\?@name.lsl

    Put this script in PMAC object
    It will delete it self after finish
    Copy results from chat into AVpos in the object
    Remove anything started ~~~
    Remove any old script related to PMAC
    Remove .menuxxxx notecards
    Copy AVsitter scripts into it
    Enjoy
 */

string product = "AVsitter2 PMAC converter";
string version = "1.0";
string notecard_basename = "AVpos";
string notecard_name;
list notecards = [];
key notecard_query;
integer notecard_line;
integer notecard_pointer;
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
    float rounding = (float)(".5e-" + (string)num_decimals) - .5e-6;
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

string FormatVector(vector v)
{
    return "<" + FormatFloat(v.x, 2) + "," + FormatFloat(v.y, 2) + "," + FormatFloat(v.z, 2) + ">";
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
        if (llGetSubString(name, 0, 4) == ".menu")
        {
            notecards += name;
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

list aniList1 = []; //* Sitter 0
list posList1 = [];

list aniList2 = []; //* Sitter 1
list posList2 = [];

dumpList()
{
    integer i;
    integer c;
    c = llGetListLength(aniList1);
    if (c>0)
    {
        Readout_Say("");
        i = 0;
        while (i < c)
        {
            Readout_Say(llList2String(aniList1, i));
            i++;
        }

        c = llGetListLength(posList1);
        if (c>0)
            Readout_Say("");
        i = 0;
        while (i < c)
        {
            Readout_Say(llList2String(posList1, i));
            i++;
        }
    }

    c = llGetListLength(aniList2);
    if (c>0)
    {
        Readout_Say("");
        i = 0;
        while (i < c)
        {
            Readout_Say(llList2String(aniList2, i));
            i++;
        }
         Readout_Say("");
        c = llGetListLength(posList2);
        i = 0;
        while (i < c)
        {
            Readout_Say(llList2String(posList2, i));
            i++;
        }
    }

    //* Reset list to start new
    aniList1 = [];
    posList1 = [];

    aniList2 = [];
    posList2 = [];
}

default
{
    state_entry()
    {
        Out(0, "Reading PMAC notecards...");
        Readout_Say(" ");
        notecards = [];
        get_notecards();
        if (llGetListLength(notecards) > 0)
        {
            notecard_name = llList2String(notecards, notecard_pointer);
            Readout_Say("--✄--COPY BELOW INTO " + notecard_basename + " NOTECARD--✄--");
            Readout_Say(" ");
            Readout_Say("SWAP 2");
            string name;
            Readout_Say("SITTER 0");
            integer i = 0;
            while (i < llGetListLength(notecards))
            {
                name = llList2String(notecards, i);
                Readout_Say("TOMENU "+ llGetSubString(name, llSubStringIndex(name, " ") + 1, 9999));
                i++;
            }

            Readout_Say("");
            Readout_Say("SITTER 1");
            i = 0;
            while (i < llGetListLength(notecards))
            {
                name = llList2String(notecards, i);
                Readout_Say("TOMENU "+ llGetSubString(name, llSubStringIndex(name, " ") + 1, 9999));
                i++;
            }

            notecard_query = llGetNotecardLine(notecard_name, notecard_line);
        }
        else
        {
            Out(0, "No PMAC notecards found!");
            finish();
        }
    }

    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                dumpList();
                if (llGetListLength(notecards) - notecard_pointer > 1)
                {
                    notecard_name = llList2String(notecards, ++notecard_pointer);
                    notecard_query = llGetNotecardLine(notecard_name, (notecard_line = 0));
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
                string cmd;
                data = llStringTrim(llList2String(llParseString2List(data, ["//"], []), 0), STRING_TRIM);
                if (llGetSubString(notecard_name, 0, 4) == ".menu")
                {
                    if (data !="")
                    {
                        list parts = llParseStringKeepNulls(data, [" | ", " |", "| ", "|"], []);
                        rotation rot;

                        if (llGetListLength(parts) > 5)
                            cmd = "SYNC";
                        else
                            cmd = "POSE";

                        if (llGetListLength(aniList1) == 0)
                        {
                            aniList1 += "SITTER 0";
                            aniList1 += "MENU "+ llGetSubString(notecard_name, llSubStringIndex(notecard_name, " ") + 1, 9999);
                        }

                        aniList1 += cmd + " " +llList2String(parts, 0)+"|"+llList2String(parts, 2);
                        rot = llList2Rot(parts, 4);
                        posList1 += "{"+llList2String(parts, 0)+"}"+llList2String(parts, 3)+""+FormatVector(llRot2Euler(rot)*RAD_TO_DEG);

                        if (llGetListLength(parts) > 5)
                        {
                            if (llGetListLength(aniList2) == 0)
                            {
                                aniList2 += "SITTER 1";
                                aniList2 += "MENU "+ llGetSubString(notecard_name, llSubStringIndex(notecard_name, " ") + 1, 9999);
                            }

                            aniList2 += cmd + " " + llList2String(parts, 0)+"|"+llList2String(parts, 5);
                            rot = llList2Rot(parts, 7);
                            posList2 += "{"+llList2String(parts, 0)+"}"+llList2String(parts, 6)+""+FormatVector(llRot2Euler(rot)*RAD_TO_DEG);
                        }
                    }
                }
                notecard_query = llGetNotecardLine(notecard_name, ++notecard_line);
            }
        }
    }
}
