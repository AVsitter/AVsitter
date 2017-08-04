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
 
string product = "AVmenu™";
string version = "2.2";
integer verbose = 0;
string prop_script = "[AV]prop";
string notecard_name = "AVpos";
string main_script = "[AV]sitA";
string custom_text;
list MENUCONTROL_TYPES = ["ALL", "OWNER ONLY", "GROUP ONLY"];
integer MENUCONTROL_INDEX;
integer owner_only;
integer last_menu_unixtime;
string last_menu_avatar;
integer menu_channel;
key notecard_key;
key notecard_query;
list MENU_LIST;
list DATA_LIST;
integer MTYPE;
integer notecard_line;
integer current_menu = -1;
integer menu_page;
integer choosing;
string choice;
integer listen_handle;
integer number_per_page = 9;
integer menu_pages;
string last_text;

integer pass_security(key id)
{
    integer access_allowed = FALSE;
    string SECURITY_TYPE = llList2String(MENUCONTROL_TYPES, MENUCONTROL_INDEX);
    if (SECURITY_TYPE == "ALL")
    {
        access_allowed = TRUE;
    }
    else if (SECURITY_TYPE == "GROUP ONLY" && llSameGroup(id) == TRUE)
    {
        access_allowed = TRUE;
    }
    else if (id == llGetOwner())
    {
        access_allowed = TRUE;
    }
    return access_allowed;
}

check_avsit()
{
    if (llGetInventoryType(main_script) == INVENTORY_SCRIPT)
    {
        remove_script("This script can not be used with the sit script in the same prim. Removing script!");
    }
}

list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
    }
}

Readout_Say(string say)
{
    llSleep(0.2);
    string objectname = llGetObjectName();
    llSetObjectName("");
    llRegionSayTo(llGetOwner(), 0, "◆" + say);
    llSetObjectName(objectname);
}

dialog(key av, string menu_text, list menu_items)
{
    llDialog(av, product + " " + version + "\n\n" + menu_text, order_buttons(menu_items), menu_channel);
    last_menu_unixtime = llGetUnixTime();
    llSetTimerEvent(120);
}

integer avprop_is_copy_transfer(integer owner_mask)
{
    integer perms = llGetInventoryPermMask(prop_script, owner_mask);
    if (perms & PERM_COPY && perms & PERM_TRANSFER)
    {
        return 1;
    }
    return 0;
}

integer prim_is_mod()
{
    integer perms = llGetObjectPermMask(MASK_OWNER);
    if (perms & PERM_MODIFY)
    {
        return 1;
    }
    return 0;
}

menu_check(string name, key id)
{
    if (pass_security(id) == TRUE)
    {
        if (name == last_menu_avatar || llGetUnixTime() - last_menu_unixtime > 5)
        {
            last_menu_unixtime = llGetUnixTime();
            last_menu_avatar = name;
            menu_page = 0;
            current_menu = -1;
            prop_menu(FALSE, id);
        }
        else
        {
            llDialog(id, product + " " + version + "\n\n" + llList2String(llParseString2List(last_menu_avatar, [" "], []), 0) + " is already using the menu.\nPlease wait a moment.", [], -585868);
        }
    }
    else
    {
        llDialog(id, product + " " + version + "\n\n" + "Sorry, the owner has set this menu to: " + llList2String(MENUCONTROL_TYPES, MENUCONTROL_INDEX), [], -585868);
    }
}

options_menu()
{
    string text;
    list menu_items = ["[BACK]"];
    text = "Prop options:\n";
    if (avprop_is_copy_transfer(MASK_OWNER) && prim_is_mod())
    {
        menu_items += ["[NEW]", "[DUMP]"];
        text += "\n[NEW] = Add a new prop.";
        text += "\n[DUMP] = Read settings to chat.";
    }
    menu_items += ["[SAVE]", "[CLEAR]", "[SECURITY]", "[RESET]"];
    text += "\n[SAVE] = Save prop positions.";
    text += "\n[CLEAR] = Clear props.";
    text += "\n[SECURITY] = Menu security.";
    text += "\n[RESET] = Reload notecard.";
    dialog(llGetOwner(), text, menu_items);
}

choice_menu(list options, string menu_text)
{
    last_text = menu_text;
    choosing = TRUE;
    menu_text = "\n(Page " + (string)(menu_page + 1) + "/" + (string)menu_pages + ")\n" + menu_text + "\n\n";
    list menu_items;
    integer i;
    if (llGetListLength(options) == 0)
    {
        menu_text = "\nNo items of required type in the prim inventory.";
        menu_items = ["[BACK]"];
    }
    else
    {
        integer cutoff = 65;
        integer all_options_length = llStringLength(llDumpList2String(options, ""));
        integer total_need_to_cut = 412 - all_options_length;
        if (total_need_to_cut < 0)
        {
            cutoff = 43;
        }
        for (i = 0; i < llGetListLength(options); i++)
        {
            menu_items += (string)(i + 1);
            string item = llList2String(options, i);
            if (llStringLength(item) > cutoff)
            {
                item = llGetSubString(item, 0, cutoff) + "..";
            }
            menu_text += (string)(i + 1) + "." + item + "\n";
        }
        while (llGetListLength(menu_items) < number_per_page)
        {
            menu_items += " ";
        }
        menu_items += ["[BACK]", "[<<]", "[>>]"];
    }
    dialog(llGetOwner(), menu_text, menu_items);
}

list get_choices(integer page)
{
    menu_page = page;
    list options;
    integer i;
    integer start = number_per_page * menu_page;
    integer end = start + number_per_page;
    integer type = INVENTORY_OBJECT;
    i = start;
    while (llGetListLength(options) + start < end && i < llGetInventoryNumber(type))
    {
        options += llGetInventoryName(type, i);
        i++;
    }
    i = llGetInventoryNumber(type);
    menu_pages = llCeil((float)i / number_per_page);
    return options;
}

remove_script(string reason)
{
    string message = "\n" + llGetScriptName() + " ==Script Removed==\n\n" + reason;
    llDialog(llGetOwner(), message, ["OK"], -3675);
    llInstantMessage(llGetOwner(), message);
    llRemoveInventory(llGetScriptName());
}

integer prop_menu(integer return_pages, key av)
{
    choosing = FALSE;
    choice = "";
    integer total_items;
    integer i = current_menu + 1;
    while (i < llGetListLength(MENU_LIST) && llSubStringIndex(llList2String(MENU_LIST, i), "M:") != 0)
    {
        total_items++;
        i++;
    }
    list menu_items2;
    if (current_menu != -1)
    {
        menu_items2 = ["[BACK]"] + menu_items2;
    }
    list menu_items1;
    if (llGetInventoryType(prop_script) == INVENTORY_SCRIPT)
    {
        menu_items2 += ["[OWNER]"];
    }
    if (total_items + llGetListLength(menu_items2) > 12)
    {
        menu_items2 += ["[<<]", "[>>]"];
    }
    integer items_per_page = 12 - llGetListLength(menu_items2);
    integer page_start = current_menu + 1 + menu_page * items_per_page;
    for (i = page_start; i < page_start + items_per_page; i++)
    {
        if (i < llGetListLength(MENU_LIST))
        {
            if (llSubStringIndex(llList2String(MENU_LIST, i), "M:") != -1)
            {
                jump end;
            }
            if (llListFindList(["T:", "S:", "B:"], [llGetSubString(llList2String(MENU_LIST, i), 0, 1)]) == -1)
            {
                menu_items1 += llList2String(MENU_LIST, i);
            }
            else
            {
                menu_items1 += llGetSubString(llList2String(llParseString2List(llList2String(MENU_LIST, i), ["|"], []), 0), 2, -1);
            }
        }
    }
    @end;
    if (return_pages)
    {
        integer pages = llCeil(total_items) / (12 - llGetListLength(menu_items2));
        if (total_items % (12 - llGetListLength(menu_items2)) == 0)
        {
            pages--;
        }
        return pages;
    }
    if (llList2String(menu_items2, 0) == "[BACK]")
    {
        menu_items1 = ["[BACK]"] + menu_items1;
        menu_items2 = llDeleteSubList(menu_items2, 0, 0);
    }
    menu_channel = ((integer)llFrand(2147483646) + 1) * -1;
    llListenRemove(listen_handle);
    listen_handle = llListen(menu_channel, "", av, "");
    dialog(av, custom_text, menu_items1 + menu_items2);
    return 0;
}

string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}

naming()
{
    llTextBox(llGetOwner(), "\nPlease type a button name for your prop\nProp: " + choice, menu_channel);
}

default
{
    state_entry()
    {
        if (llSubStringIndex(llGetScriptName(), " ") != -1)
        {
            remove_script("Use only one copy of this script!");
        }
        check_avsit();
        notecard_key = llGetInventoryKey(notecard_name);
        Out(0, "Loading...");
        notecard_query = llGetNotecardLine(notecard_name, notecard_line);
    }

    timer()
    {
        llListenRemove(listen_handle);
    }

    listen(integer listen_channel, string name, key id, string msg)
    {
        if (choice)
        {
            if (msg == "")
            {
                naming();
            }
            else
            {
                integer perms = llGetInventoryPermMask(choice, MASK_NEXT);
                if (!(perms & PERM_COPY))
                {
                    llSay(0, "Could not add prop '" + choice + "'. Props and their content must be COPY-OK for NEXT owner.");
                }
                else
                {
                    llMessageLinked(LINK_THIS, 90173, msg, choice); // add PROP line to [AV]prop
                    MENU_LIST = ["B:" + msg] + MENU_LIST;
                    DATA_LIST = [90200] + DATA_LIST; // Rez prop (with menu)
                }
                choice = "";
                options_menu();
            }
            return;
        }
        if (choosing && llListFindList(["1", "2", "3", "4", "5", "6", "7", "8", "9"], [msg]) != -1)
        {
            choosing = FALSE;
            choice = llList2String(get_choices(menu_page), (integer)msg - 1);
            naming();
            return;
        }
        if (msg == "[SECURITY]")
        {
            if (id == llGetOwner())
            {
                dialog(llGetOwner(), "Who is allowed to control this menu?", MENUCONTROL_TYPES);
            }
            else
            {
                llRegionSayTo(id, 0, "Sorry, only the owner can use this.");
            }
            return;
        }
        integer mindex_test = llListFindList(MENU_LIST, ["M:" + msg]);
        if (mindex_test != -1)
        {
            menu_page = 0;
            current_menu = mindex_test;
        }
        mindex_test = llListFindList(MENU_LIST, ["B:" + msg]);
        if (mindex_test != -1)
        {
            list button_data = llParseStringKeepNulls(llList2String(DATA_LIST, mindex_test), ["�"], []);
            if (llList2String(button_data, 1))
            {
                msg = llList2String(button_data, 1);
            }
            if (llList2String(button_data, 2))
            {
                id = llList2String(button_data, 2);
            }
            llMessageLinked(LINK_SET, (integer)llList2String(button_data, 0), msg, id);
            return;
        }
        else if (msg == "[>>]" || msg == "[<<]")
        {
            if (choosing)
            {
                if (msg == "[>>]")
                {
                    menu_page++;
                    if (menu_page >= menu_pages)
                    {
                        menu_page = 0;
                    }
                }
                else if (msg == "[<<]")
                {
                    menu_page--;
                    if (menu_page < 0)
                    {
                        menu_page = menu_pages - 1;
                    }
                }
                choice_menu(get_choices(menu_page), last_text);
            }
            else
            {
                if (msg == "[<<]")
                {
                    menu_page--;
                    if (menu_page < 0)
                    {
                        menu_page = prop_menu(TRUE, NULL_KEY);
                    }
                }
                else
                {
                    menu_page++;
                    if (menu_page > prop_menu(TRUE, NULL_KEY))
                    {
                        menu_page = 0;
                    }
                }
                prop_menu(FALSE, id);
            }
            return;
        }
        else if (msg == "[BACK]")
        {
            menu_page = 0;
            current_menu = -1;
        }
        else if (msg == "[NEW]")
        {
            llMessageLinked(LINK_THIS, 90200, "", ""); // Clear props
            choice_menu(get_choices(0), "Please choose your prop:\n\n(Props must include the [AV]object script!)");
            return;
        }
        else if (msg == "[DUMP]")
        {
            Readout_Say("");
            Readout_Say("--✄--COPY BELOW INTO \"AVpos\" NOTECARD--✄--");
            Readout_Say("");
            if (custom_text)
            {
                Readout_Say("TEXT " + strReplace(custom_text, "\n", "\\n"));
            }
            integer i;
            for (i = 0; i < llGetListLength(MENU_LIST); i++)
            {
                list change_me = llParseString2List(llList2String(MENU_LIST, i), [":"], []);
                if (llGetListLength(change_me) == 2)
                {
                    if (llList2String(change_me, 0) == "M")
                    {
                        Readout_Say("MENU " + llGetSubString(llList2String(change_me, 1), 0, -2));
                    }
                    else if (llList2String(change_me, 0) == "T")
                    {
                        Readout_Say("TOMENU " + llGetSubString(llList2String(change_me, 1), 0, -2));
                    }
                    else if (llList2String(change_me, 0) == "B")
                    {
                        list l = [llList2String(change_me, 1), strReplace(strReplace(llList2String(DATA_LIST, i), "90200", ""), "�", "|")];
                        if (llList2String(l, 1) == "")
                        {
                            l = llList2List(l, 0, 0);
                        }
                        string end = llDumpList2String(l, "|");
                        Readout_Say("BUTTON " + end);
                    }
                }
            }
            llMessageLinked(LINK_THIS, 90020, "0", prop_script); // Dump prop settings
            return;
        }
        else if (msg == "[SAVE]" && id == llGetOwner())
        {
            llMessageLinked(LINK_SET, 90101, "0|" + msg, ""); // Menu choice notification
            options_menu();
            return;
        }
        else if (msg == "[CLEAR]")
        {
            Out(0, "Props have been cleared!");
            llMessageLinked(LINK_THIS, 90200, "", ""); // Clear props
        }
        else if (msg == "[RESET]")
        {
            llMessageLinked(LINK_THIS, 90200, "", ""); // Clear props
            llSleep(1);
            llResetOtherScript(prop_script);
            llResetScript();
            return;
        }
        else if (msg == "[BACK]")
        {
        }
        else if (msg == "[OWNER]")
        {
            if (id == llGetOwner())
            {
                options_menu();
                return;
            }
            else
            {
                llRegionSayTo(id, 0, "Sorry, only the owner can use this.");
            }
        }
        else if (id == llGetOwner() && llListFindList(MENUCONTROL_TYPES, [msg]) != -1)
        {
            MENUCONTROL_INDEX = llListFindList(MENUCONTROL_TYPES, [msg]);
            Out(0, "Menu access set to: " + llList2String(MENUCONTROL_TYPES, MENUCONTROL_INDEX));
            if (llGetInventoryType(prop_script) == INVENTORY_SCRIPT)
            {
                options_menu();
                return;
            }
            else
            {
            }
        }
        prop_menu(FALSE, id);
    }

    touch_start(integer touched)
    {
        if (MTYPE < 3)
        {
            menu_check(llDetectedName(0), llDetectedKey(0));
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
            check_avsit();
        }
    }

    link_message(integer sender, integer num, string msg, key id)
    {
        if (sender == llGetLinkNumber())
        {
            if (num == 90005) // send menu to id
            {
                menu_check(llKey2Name(id), id);
            }
            else if (num == 90022) // send dump to [AV]adjuster
            {
                Readout_Say(msg);
            }
            else if (num == 90021) // end of dump
            {
                Readout_Say("");
                Readout_Say("--✄--COPY ABOVE INTO \"AVpos\" NOTECARD--✄--");
                Readout_Say("");
            }
        }
    }

    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                Out(0, (string)llGetListLength(MENU_LIST) + " menu items Ready, Memory: " + (string)llGetFreeMemory());
                llPassTouches(FALSE);
                if (MTYPE == 3)
                {
                    llPassTouches(TRUE);
                }
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseStringKeepNulls(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                string part0 = llStringTrim(llList2String(parts, 0), STRING_TRIM);
                string part1 = llList2String(parts, 1);
                if (llGetListLength(parts) > 1)
                {
                    part1 = llStringTrim(llDumpList2String(llList2List(parts, 1, -1), "�"), STRING_TRIM);
                }
                if (command == "TEXT")
                {
                    custom_text = llDumpList2String(llParseStringKeepNulls(part0, ["\\n"], []), "\n");
                }
                part0 = llGetSubString(part0, 0, 22);
                if (command == "MENU")
                {
                    MENU_LIST += ["M:" + part0 + "*"];
                    DATA_LIST += "";
                }
                else if (command == "TOMENU")
                {
                    MENU_LIST += ["T:" + part0 + "*"];
                    DATA_LIST += "";
                }
                else if (command == "BUTTON")
                {
                    MENU_LIST += ["B:" + part0];
                    if (part1 == "")
                    {
                        part1 = "90200";
                    }
                    DATA_LIST += part1;
                }
                else if (command == "MTYPE")
                {
                    MTYPE = (integer)part0;
                }
                notecard_query = llGetNotecardLine(notecard_name, ++notecard_line);
            }
        }
    }
}
