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
 
float version = 1.2;
string notecard_name = "AVpos";
string url = "https://avsitter.com/settings.php"; // the settings dump service remains up for AVsitter customers. settings clear periodically.
key notecard_query;
integer notecard_line;
vector target_prim_pos;
rotation target_prim_rot;
vector rot_offset;
vector pos_offset;
string cache;
string webkey;
integer webcount;
web(string say, integer force){
    cache+=say;
    if(llStringLength(llEscapeURL(cache))>1024 || force){
        webcount++;
        llHTTPRequest(url, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded",HTTP_VERIFY_CERT,FALSE], "w="+webkey+"&c="+(string)webcount+"&t="+llEscapeURL(cache));
        cache="";
    }
}
integer IsVector(string s)
{
    list split = llParseString2List(s, [" "], ["<", ">", ","]);
    if (llGetListLength(split) != 7)
        return FALSE;
    return !((string)((vector)s) == (string)((vector)((string)llListInsertList(split, ["-"], 5))));
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
instructions()
{
    llOwnerSay("\n\nINSTRUCTIONS:\n\nFOR MOVING ALL POSE & PROP POSITIONS BY AN OFFSET:\nManual Position: specify a position offset on channel 5, and positions will be converted by that offset. E.g. /5 <0,0,1.5>\nManual Rotation: specify a rotation offset on channel 6 (in degrees), and rotations will be converted by that offset, relative to the prim center. E.g. /6 <0,0,180>\n\nFOR RELOCATING SCRIPTS TO NEW PRIM:\n1. Unlink your object and re-link so that the prim you want to move the animations from is the root prim, then place this script inside the root prim.\n2. Touch the prim you want to locate the poses to. This prim should be empty or contain a script with llPassTouches(TRUE);\n3. The script will read out the notecard in chat, with pos/rot modified to the prim you touched.\n\nHave Fun! :)\n");
}
cut_above_text()
{
    webkey = (string)llGenerateKey();
    webcount = 0;
    Readout_Say("");
    Readout_Say("--✄--COPY BELOW INTO \"AVpos\" NOTECARD--✄--");
    Readout_Say("");
}
cut_below_text()
{
    Readout_Say("");
    Readout_Say("--✄--COPY ABOVE INTO \"AVpos\" NOTECARD--✄--");
    Readout_Say("");
}
Readout_Say(string say)
{
    llSleep(0.1);
    string objectname = llGetObjectName();
    llSetObjectName("");
    llRegionSayTo(llGetOwner(), 0, "◆" + say);
    llSetObjectName(objectname);
    web(say+"\n",FALSE);
}
integer check_in_root()
{
    if (llGetLinkNumber() > 1 || llGetInventoryType("AVpos") != INVENTORY_NOTECARD)
    {
        if (llGetInventoryCreator(llGetScriptName()) != llGetOwner())
        {
            llOwnerSay("This script must be placed only in the root prim and with AVpos notecard! - Removing script!");
            llRemoveInventory(llGetScriptName());
            return FALSE;
        }
    }
    return TRUE;
}
default
{
    state_entry()
    {
        check_in_root();
        instructions();
        llListen(5, "", llGetOwner(), "");
        llListen(6, "", llGetOwner(), "");
    }
    touch_start(integer touched)
    {
        check_in_root();
        if (llDetectedLinkNumber(0) > 1)
        {
            notecard_line = 0;
            target_prim_pos = llList2Vector(llGetLinkPrimitiveParams(llDetectedLinkNumber(0), [PRIM_POS_LOCAL]), 0);
            target_prim_rot = llList2Rot(llGetLinkPrimitiveParams(llDetectedLinkNumber(0), [PRIM_ROT_LOCAL]), 0);
            llOwnerSay("Converting " + notecard_name + " for use in prim #" + (string)llDetectedLinkNumber(0));
            cut_above_text();
            notecard_query = llGetNotecardLine(notecard_name, notecard_line);
        }
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (chan == 5)
        {
            vector v = (vector)msg;
            if (v != ZERO_VECTOR)
            {
                llOwnerSay("Converting positions in " + notecard_name + " by offset: " + (string)v);
                cut_above_text();
                target_prim_pos = -v;
                notecard_query = llGetNotecardLine(notecard_name, notecard_line);
            }
            else
            {
                llOwnerSay("You didn't enter a vector!");
            }
        }
        if (chan == 6)
        {
            vector v = (vector)msg;
            if (v != ZERO_VECTOR)
            {
                target_prim_rot = llEuler2Rot(v * DEG_TO_RAD);
                llOwnerSay("Converting rotations in " + notecard_name + " by offset: " + (string)v);
                cut_above_text();
                notecard_query = llGetNotecardLine(notecard_name, notecard_line);
            }
            else
            {
                llOwnerSay("You didn't enter a vector!");
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                cut_below_text();
                web("\n\nend",TRUE);
                llOwnerSay("Conversion complete, removing script.");
                llRegionSayTo(llGetOwner(),0,"Settings copy: "+url+"?q="+webkey);
                llRemoveInventory(llGetScriptName());
            }
            else
            {
                data = llStringTrim(llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1), STRING_TRIM);
                if (llGetSubString(data, 0, 0) == "{")
                {
                    string command = llStringTrim(llGetSubString(data, 1, llSubStringIndex(data, "}") - 1), STRING_TRIM);
                    data = llDumpList2String(llParseString2List(data, [" "], [""]), "");
                    data = llGetSubString(data, llSubStringIndex(data, "}") + 1, -1);
                    list parts = llParseStringKeepNulls(data, ["<"], []);
                    vector pos = (vector)("<" + llList2String(parts, 1));
                    pos = -target_prim_pos / target_prim_rot + pos / target_prim_rot;
                    rotation rot = llEuler2Rot((vector)("<" + llList2String(parts, 2)) * DEG_TO_RAD);
                    vector vec_rot = llRot2Euler(rot / target_prim_rot) * RAD_TO_DEG;
                    string result = "<" + FormatFloat(pos.x, 3) + "," + FormatFloat(pos.y, 3) + "," + FormatFloat(pos.z, 3) + ">";
                    result += "<" + FormatFloat(vec_rot.x, 1) + "," + FormatFloat(vec_rot.y, 1) + "," + FormatFloat(vec_rot.z, 1) + ">";
                    Readout_Say("{" + command + "}" + result);
                }
                else if (llSubStringIndex(llGetSubString(data, 0, 0), "PROP"))
                {
                    integer index;
                    vector pos;
                    rotation rot;
                    list parts = llParseStringKeepNulls(data, ["|"], [""]);
                    if (IsVector(llList2String(parts, 2)) && IsVector(llList2String(parts, 3)))
                    {
                        index = 2;
                    }
                    else if (IsVector(llList2String(parts, 3)) && IsVector(llList2String(parts, 4)))
                    {
                        index = 3;
                    }
                    if (index)
                    {
                        pos = (vector)llList2String(parts, index);
                        rot = llEuler2Rot((vector)llList2String(parts, index + 1) * DEG_TO_RAD);
                        pos = -target_prim_pos / target_prim_rot + pos / target_prim_rot;
                        vector vec_rot = llRot2Euler(rot / target_prim_rot) * RAD_TO_DEG;
                        string pos_string = "<" + FormatFloat(pos.x, 3) + "," + FormatFloat(pos.y, 3) + "," + FormatFloat(pos.z, 3) + ">";
                        string rot_string = "<" + FormatFloat(vec_rot.x, 1) + "," + FormatFloat(vec_rot.y, 1) + "," + FormatFloat(vec_rot.z, 1) + ">";
                        parts = llListReplaceList(parts, [pos_string, rot_string], index, index + 1);
                    }
                    Readout_Say(llDumpList2String(parts, "|"));
                }
                else if (data != "")
                {
                    Readout_Say(data);
                }
                notecard_query = llGetNotecardLine(notecard_name, notecard_line += 1);
            }
        }
    }
}
