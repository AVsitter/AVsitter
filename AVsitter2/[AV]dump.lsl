/*
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
 */

string rlv_script = "[AV]root-RLV";
string main_script = "[AV]sitA";
string menu_script = "[AV]menu";
string prop_script = "[AV]prop";
string expression_script = "[AV]faces";
string camera_script = "[AV]camera";
string SEP = "�"; // OSS::string SEP = "\u007F";

string cache;
integer webcount;
string url = "https://avsitter.com/settings.php";
string webkey;

string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls(str, [search], []), replace);
}

integer get_number_of_scripts()
{
    integer i;
    while (llGetInventoryType(main_script + " " + (string)(++i)) == INVENTORY_SCRIPT)
        ;
    return i;
}

web(integer force)
{
    if (llStringLength(llEscapeURL(cache)) > 1024 || force)
    {
        if (force)
        {
            cache += "\n\nend";
        }
        cache = llEscapeURL(cache);
        webcount++;
        llHTTPRequest(url, [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded", HTTP_VERIFY_CERT, FALSE], "w=" + webkey + "&c=" + (string)webcount + "&t=" + cache);
        cache = "";
    }
}

Readout_Say(string say)
{
    string objectname = llGetObjectName();
    llSetObjectName("");
    llOwnerSay("◆" + say);
    llSetObjectName(objectname);
    cache += say + "\n";
    say = "";
}

string FormatFloat(float f, integer num_decimals)
{
    f += ((integer)(f > 0) - (integer)(f < 0)) * ((float)(".5e-" + (string)num_decimals) - .5e-6);
    string ret = llGetSubString((string)f, 0, num_decimals - (!num_decimals) - 7);
    if (num_decimals)
    {
        num_decimals = -1;
        while (llGetSubString(ret, num_decimals, num_decimals) == "0")
        {
            --num_decimals;
        }
        if (llGetSubString(ret, num_decimals, num_decimals) == ".")
        {
            --num_decimals;
        }

        return llGetSubString(ret, 0, num_decimals);
    }
    return ret;
}

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        if (sender == llGetLinkNumber())
        {
            integer script_channel;
            if (num == 90020 && id == "")
            {
                webkey = llGenerateKey();
                webcount = 0;
                Readout_Say("");
                Readout_Say("--✄--COPY BELOW INTO \"AVpos\" NOTECARD--✄--");
                Readout_Say("");

                // Start dump cycle
                if (llGetInventoryType(menu_script) == INVENTORY_SCRIPT)
                {
                    // If the prop menu is present, that's our only target.
                    msg = menu_script;
                }
                else if (llGetInventoryType(rlv_script) == INVENTORY_SCRIPT)
                {
                    // If the RLV is present, start with it.
                    msg = rlv_script;
                }
                else
                {
                    // Start with the main scripts.
                    msg = main_script;
                }
                llMessageLinked(LINK_THIS, 90020, "0", msg);
                return;
            }
            if (num == 90021)
            {
                // Dump next script
                if (id == rlv_script)
                {
                    Readout_Say("");
                    llMessageLinked(LINK_THIS, 90020, "0", main_script);
                    return;
                }
                script_channel = (integer)msg;
                list scripts = [prop_script, expression_script, camera_script];
                integer index = llListFindList(scripts, [(string)id]);
                while (index < llGetListLength(scripts))
                {
                    index++;
                    string lookfor = llList2String(scripts, index);
                    if (lookfor == camera_script && script_channel > 0)
                    {
                        lookfor = lookfor + " " + (string)script_channel;
                    }
                    if (llGetInventoryType(lookfor) == INVENTORY_SCRIPT)
                    {
                        llMessageLinked(LINK_THIS, 90020, (string)script_channel, llList2String(scripts, index));
                        return;
                    }
                }
                // Finished with plug-ins, check next main script
                if (llGetInventoryType(main_script + " " + (string)(script_channel + 1)) == INVENTORY_SCRIPT)
                {
                    llMessageLinked(LINK_THIS, 90020, (string)(script_channel + 1), main_script);
                    return;
                }
                Readout_Say("");
                Readout_Say("--✄--COPY ABOVE INTO \"AVpos\" NOTECARD--✄--");
                Readout_Say("");
                web(TRUE);
                llRegionSayTo(llGetOwner(), 0, "Settings copy: " + url + "?q=" + webkey);
            }
            if (num == 90022)
            {
                script_channel = (integer)((string)id);
                // Interpret a dump line
                list data = llParseStringKeepNulls(msg, ["|"], []);
                if (llGetSubString(msg, 0, 3) == "S:M:" || llGetSubString(msg, 0, 3) == "S:T:")
                {
                    msg = strReplace(msg, "*|", "|");
                }
                if (llGetSubString(msg, 0, 1) == "V:")
                {
                    if (!script_channel)
                    {
                        Readout_Say("\"" + llToUpper(llGetObjectName()) + "\" " + strReplace(llList2String(data, 0), "V:", "AVsitter "));
                        if ((integer)llList2String(data, 1))
                        {
                            Readout_Say("MTYPE " + llList2String(data, 1));
                        }
                        if ((integer)llList2String(data, 2) != 1)
                        {
                            Readout_Say("ETYPE " + llList2String(data, 2));
                        }
                        if ((integer)llList2String(data, 3) > -1)
                        {
                            Readout_Say("SET " + llList2String(data, 3));
                        }
                        if ((integer)llList2String(data, 4) != 2)
                        {
                            Readout_Say("SWAP " + llList2String(data, 4));
                        }
                        if (llList2String(data, 6) != "")
                        {
                            Readout_Say("TEXT " + strReplace(llList2String(data, 6), "\n", "\\n"));
                        }
                        if (llList2String(data, 7) != "")
                        {
                            Readout_Say("ADJUST " + strReplace(llList2String(data, 7), SEP, "|"));
                        }
                        if ((integer)llList2String(data, 8))
                        {
                            Readout_Say("SELECT " + llList2String(data, 8));
                        }
                        if ((integer)llList2String(data, 9) != 2)
                        {
                            Readout_Say("AMENU " + llList2String(data, 9));
                        }
                        if ((integer)llList2String(data, 10))
                        {
                            Readout_Say("HELPER " + llList2String(data, 10));
                        }
                    }
                    Readout_Say("");
                    if (get_number_of_scripts() > 1 || llList2String(data, 5) != "")
                    {
                        string SITTER_TEXT;
                        if (llList2String(data, 5) != "")
                        {
                            SITTER_TEXT = "|" + strReplace(llList2String(data, 5), SEP, "|");
                        }
                        Readout_Say("SITTER " + (string)script_channel + SITTER_TEXT);
                        Readout_Say("");
                    }
                    data = llParseStringKeepNulls(id, ["|"], []);
                    llMessageLinked(LINK_THIS, 90024, (string)script_channel + "|" + llList2String(data, 1), "-1|D");
                    return;
                }
                if (llGetSubString(msg, 0, 0) == "{")
                {
                    msg = strReplace(msg, "{P:", "{");
                    data = llParseString2List(msg, ["}<", ",", "><", ">"], []);
                    msg = llGetSubString(msg, 0, llSubStringIndex(msg, "}"));
                    msg += "<" + FormatFloat(llList2Float(data, -6), 3);
                    msg += "," + FormatFloat(llList2Float(data, -5), 3);
                    msg += "," + FormatFloat(llList2Float(data, -4), 3);
                    msg += "><" + FormatFloat(llList2Float(data, -3), 3);
                    msg += "," + FormatFloat(llList2Float(data, -2), 3);
                    msg += "," + FormatFloat(llList2Float(data, -1), 3);
                    msg += ">";
                }
                else if (llGetSubString(msg, 1, 1) == ":")
                {
                    msg = strReplace(msg, "S:P:", "POSE ");
                    msg = strReplace(msg, "S:M:", "MENU ");
                    msg = strReplace(msg, "S:T:", "TOMENU ");
                    if (llGetSubString(msg, -6, -1) == "|90210")
                    {
                        msg = strReplace(llGetSubString(msg, 0, -7), "S:B:", "SEQUENCE ");
                    }
                    else
                    {
                        msg = strReplace(msg, "S:B:", "BUTTON ");
                        if (llSubStringIndex(msg, SEP) == -1)
                        {
                            msg = strReplace(msg, "|90200", "");
                        }
                    }
                    msg = strReplace(msg, "S:", "SYNC ");
                    msg = strReplace(msg, SEP, "|");
                }
                if (llGetSubString(msg, -1, -1) == "*")
                {
                    msg = llGetSubString(msg, 0, -2);
                }
                if (llGetSubString(msg, -1, -1) == "|")
                {
                    msg = llGetSubString(msg, 0, -2);
                }
                if (llGetSubString(msg, 0, 4) == "MENU ")
                {
                    Readout_Say("");
                }
                Readout_Say(msg);
                data = llParseStringKeepNulls(id, ["|"], []);

                llSleep(0.2 + 0.3 * (llList2String(data, 3) != "P"));

                llMessageLinked(LINK_THIS, 90024, (string)script_channel + "|" + llList2String(data, 1), llList2String(data, 2) + "|" + llList2String(data, 3));
            }
        }
    }
}
