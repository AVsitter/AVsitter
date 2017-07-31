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
 
string product = "AVsitter™ Menu Control";
string version = "2.2";
string security_script = "[AV]root-security";
string RLV_script = "[AV]root-RLV";
list DESIGNATIONS_NOW;
key CONTROLLER = NULL_KEY;
integer KEY_TAKEN;
string CONTROLLER_NAME;
list SITTERS_MENUKEYS;
list SITTERS_SHORTNAMES;
integer menu_channel;
integer menu_handle;
key key_request;
integer verbose = 1;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "]:" + out);
    }
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls(str, [search], []), replace);
}
controller_menu(key id)
{
    CONTROLLER = id;
    CONTROLLER_NAME = llKey2Name(id);
    list SITTERS;
    integer count = llGetNumberOfPrims();
    while (llGetAgentSize(llGetLinkKey(count)) != ZERO_VECTOR)
    {
        SITTERS += llGetLinkKey(count);
        count--;
    }
    if ((~llListFindList(SITTERS, [id])) && check_for_RLV())
    {
        llMessageLinked(LINK_SET, 90005, "", id);
    }
    else
    {
        if (llGetListLength(SITTERS) == 1 && ((!check_for_RLV()) || (!~llListFindList(DESIGNATIONS_NOW, ["S"])) || llGetListLength(DESIGNATIONS_NOW) == 1))
        {
            if (check_for_RLV())
            {
                llMessageLinked(LINK_THIS, 90100, "x|Control...|" + llList2String(SITTERS, 0), id);
            }
            else
            {
                llMessageLinked(LINK_SET, 90005, "", llDumpList2String([id, llList2Key(SITTERS, 0)], "|"));
            }
        }
        else
        {
            list menu_items;
            SITTERS_MENUKEYS = [];
            integer i;
            for (i = 0; i < llGetListLength(SITTERS); i++)
            {
                if (llList2Key(SITTERS, i) != NULL_KEY)
                {
                    menu_items += llGetSubString(strReplace(llKey2Name(llList2Key(SITTERS, i)), " Resident", ""), 0, 11);
                    SITTERS_MENUKEYS += llList2Key(SITTERS, i);
                }
            }
            SITTERS_SHORTNAMES = menu_items;
            string text = "Which avatar?";
            if (check_for_RLV())
            {
                if (!llGetListLength(menu_items))
                {
                    llMessageLinked(LINK_THIS, 90211, "", id);
                    return;
                }
                if ((~llListFindList(DESIGNATIONS_NOW, ["S"])) && llGetListLength(SITTERS) < llGetListLength(DESIGNATIONS_NOW))
                {
                    text += "\n\nCapture = trap a new avatar.";
                    menu_items += "Capture...";
                }
            }
            if (llGetListLength(menu_items))
            {
                dialog(text, order_buttons(menu_items), id);
            }
        }
    }
}
dialog(string text, list menu_items, key id)
{
    llListenRemove(menu_handle);
    menu_handle = llListen(menu_channel = ((integer)llFrand(2147483646) + 1) * -1, "", id, "");
    llDialog(id, product + " " + version + "\n\n" + text + "\n", order_buttons(menu_items), menu_channel);
    llSetTimerEvent(120);
}
integer check_for_RLV()
{
    if (llGetInventoryType(RLV_script) == INVENTORY_SCRIPT)
    {
        return TRUE;
    }
    return FALSE;
}
default
{
    state_entry()
    {
        llSetTimerEvent(0);
    }
    on_rez(integer x)
    {
        llResetScript();
    }
    timer()
    {
        llListenRemove(menu_handle);
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90007)
        {
            if (id == CONTROLLER || CONTROLLER == NULL_KEY)
            {
                controller_menu(id);
            }
            else
            {
                string text = "Take control of the menu?";
                if (llGetAgentSize(CONTROLLER) != ZERO_VECTOR)
                {
                    text += "\n\nCurrently controlled by: " + CONTROLLER_NAME;
                }
                dialog(text, ["Take Control", "[CANCEL]"], id);
            }
        }
        else if (num == 90206)
        {
            DESIGNATIONS_NOW = llParseStringKeepNulls(msg, ["|"], []);
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        llListenRemove(menu_handle);
        integer index = llListFindList(SITTERS_SHORTNAMES, [message]);
        if (~index)
        {
            if (check_for_RLV())
            {
                llMessageLinked(LINK_THIS, 90100, "x|Control...|" + llList2String(SITTERS_MENUKEYS, index), CONTROLLER);
            }
            else
            {
                llMessageLinked(LINK_SET, 90005, "", llDumpList2String([CONTROLLER, llList2Key(SITTERS_MENUKEYS, index)], "|"));
            }
        }
        else if (message == "Capture...")
        {
            llMessageLinked(LINK_THIS, 90211, "", id);
        }
        else if (message == "Take Control")
        {
            llMessageLinked(LINK_SET, 90033, "", "");
            if (id != CONTROLLER)
            {
                llRegionSayTo(CONTROLLER, 0, llKey2Name(id) + " has taken control of the menu.");
            }
            controller_menu(id);
        }
    }
    changed(integer change)
    {
        if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
        {
            CONTROLLER = NULL_KEY;
        }
    }
}
