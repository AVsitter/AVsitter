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
 
string product = "AVsitter™ Security 2.2";
string script_basename = "[AV]sitA";
string menucontrol_script = "[AV]root-control";
string RLV_script = "[AV]root-RLV";
key active_sitter;
integer active_prim;
integer active_script_channel;
integer menu_channel;
integer menu_handle;
list SIT_TYPES = ["ALL", "OWNER", "GROUP"];
list MENU_TYPES = ["ALL", "OWNER", "GROUP"];
integer SIT_INDEX;
integer MENU_INDEX;
string lastmenu;
integer pass_security(key id, string context)
{
    integer ALLOWED = FALSE;
    string TYPE = llList2String(SIT_TYPES, SIT_INDEX);
    if (context == "MENU")
    {
        TYPE = llList2String(MENU_TYPES, MENU_INDEX);
    }
    if (TYPE == "GROUP")
    {
        if (llSameGroup(id) == TRUE)
        {
            ALLOWED = TRUE;
        }
    }
    else if (id == llGetOwner() || TYPE == "ALL")
    {
        ALLOWED = TRUE;
    }
    return ALLOWED;
}
check_sitters()
{
    integer i = llGetNumberOfPrims();
    while (llGetAgentSize(llGetLinkKey(i)) != ZERO_VECTOR)
    {
        key av = llGetLinkKey(i);
        if (pass_security(av, "SIT") == FALSE)
        {
            llUnSit(av);
            llDialog(av, product + "\n\nSorry, Sit access is set to: " + llList2String(SIT_TYPES, SIT_INDEX), [], -164289491);
        }
        i--;
    }
}
back_to_adjust(integer SCRIPT_CHANNEL, key sitter)
{
    llMessageLinked(LINK_SET, 90101, (string)SCRIPT_CHANNEL + "|[ADJUST]", sitter);
}
list order_buttons(list menu_items)
{
    return llList2List(menu_items, -3, -1) + llList2List(menu_items, -6, -4) + llList2List(menu_items, -9, -7) + llList2List(menu_items, -12, -10);
}
register_touch(key id, integer animation_menu_function, integer active_prim, integer giveFailedMessage)
{
    if (pass_security(id, "MENU"))
    {
        if (llGetInventoryType(menucontrol_script) == INVENTORY_SCRIPT)
        {
            if (check_for_RLV())
            {
                llMessageLinked(LINK_THIS, 90012, (string)active_prim, id);
            }
            else
            {
                llMessageLinked(LINK_THIS, 90007, "", id);
            }
        }
        else
        {
            llMessageLinked(LINK_SET, 90005, (string)animation_menu_function, id);
        }
    }
    else if (giveFailedMessage)
    {
        llDialog(id, product + "\n\nSorry, Menu access is set to: " + llList2String(MENU_TYPES, MENU_INDEX), [], -164289491);
    }
}
main_menu()
{
    dialog("Sit access: " + llList2String(SIT_TYPES, SIT_INDEX) + "\nMenu access: " + llList2String(MENU_TYPES, MENU_INDEX) + "\n\nChange security settings:", ["[BACK]", "Sit", "Menu"]);
    lastmenu = "";
}
dialog(string text, list menu_items)
{
    llListenRemove(menu_handle);
    menu_handle = llListen(menu_channel = ((integer)llFrand(2147483646) + 1) * -1, "", llGetOwner(), "");
    llDialog(llGetOwner(), product + "\n\n" + text, order_buttons(menu_items), menu_channel);
    llSetTimerEvent(600);
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
        llMessageLinked(LINK_SET, 90202, (string)check_for_RLV(), "");
    }
    timer()
    {
        llSetTimerEvent(0);
        llListenRemove(menu_handle);
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90201)
        {
            llMessageLinked(LINK_SET, 90202, (string)check_for_RLV(), "");
        }
        else if (num == 90006)
        {
            if (llGetInventoryType(menucontrol_script) != INVENTORY_SCRIPT)
            {
                register_touch(id, (integer)msg, sender, FALSE);
            }
        }
        else if (num == 90100)
        {
            list data = llParseString2List(msg, ["|"], []);
            if (llList2String(data, 1) == "[SECURITY]")
            {
                if (id == llGetOwner())
                {
                    active_prim = sender;
                    active_script_channel = (integer)llList2String(data, 0);
                    active_sitter = (key)llList2String(data, 2);
                    main_menu();
                }
                else
                {
                    llRegionSayTo(id, 0, "Sorry, only the owner can change security settings.");
                    llMessageLinked(sender, 90101, llDumpList2String([llList2String(data, 0), "[ADJUST]", id], "|"), llList2String(data, 2));
                }
            }
        }
        else if (num == 90033)
        {
            llListenRemove(menu_handle);
        }
    }
    listen(integer listen_channel, string name, key id, string msg)
    {
        if (msg == "Sit")
        {
            dialog("Sit security:", SIT_TYPES);
            lastmenu = msg;
            return;
        }
        else if (msg == "Menu")
        {
            dialog("Menu security:", MENU_TYPES);
            lastmenu = msg;
            return;
        }
        else
        {
            if (msg == "[BACK]")
            {
                llMessageLinked(LINK_SET, 90101, llDumpList2String([active_script_channel, "[ADJUST]", id], "|"), active_sitter);
            }
            else if (lastmenu == "Sit")
            {
                SIT_INDEX = llListFindList(SIT_TYPES, [msg]);
                main_menu();
                check_sitters();
                return;
            }
            else if (lastmenu == "Menu")
            {
                MENU_INDEX = llListFindList(MENU_TYPES, [msg]);
                main_menu();
                return;
            }
        }
        llListenRemove(menu_handle);
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            check_sitters();
        }
    }
    touch_end(integer touched)
    {
        if (check_for_RLV() || llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) != ZERO_VECTOR)
        {
            register_touch(llDetectedKey(0), 0, llDetectedLinkNumber(0), TRUE);
        }
    }
}
