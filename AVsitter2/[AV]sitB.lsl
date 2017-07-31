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
 
string product = "AVsitter™";
string version = "2.2";
string BRAND;
integer OLD_HELPER_METHOD;
string main_script = "[AV]sitA";
string select_script = "[AV]select";
integer SET;
integer ETYPE;
integer MTYPE;
integer SWAP;
integer AMENU;
integer SELECT;
integer SCRIPT_CHANNEL;
integer number_of_sitters;
string CUSTOM_TEXT;
string ADJUST_MENU;
string SITTER_INFO;
list MENU_LIST;
list DATA_LIST;
list POS_ROT_LIST;
integer helper_mode;
integer has_RLV;
integer ANIM_INDEX;
integer FIRST_INDEX = -1;
integer menu_handle;
integer menu_channel;
integer current_menu = -1;
integer last_menu;
string submenu_info;
integer menu_page;
key MY_SITTER;
key CONTROLLER;
string RLVDesignations;
string onSit;
integer speed_index;
integer verbose = 0;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "]:" + out);
    }
}
send_anim_info(integer broadcast)
{
    llMessageLinked(LINK_THIS, 90055, (string)SCRIPT_CHANNEL, llDumpList2String([llList2String(MENU_LIST, ANIM_INDEX), llList2String(DATA_LIST, ANIM_INDEX), llList2String(POS_ROT_LIST, ANIM_INDEX * 2), llList2String(POS_ROT_LIST, ANIM_INDEX * 2 + 1), broadcast, speed_index], "|"));
}
Readout_Say(string say)
{
    llMessageLinked(LINK_THIS, 90022, say, (string)SCRIPT_CHANNEL);
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
memory()
{
    llOwnerSay(llGetScriptName() + "[" + version + "] " + (string)(MENU_LIST != []) + " Items Ready, Mem=" + (string)(65536 - llGetUsedMemory()));
}
integer animation_menu(integer animation_menu_function)
{
    if (animation_menu_function == -1 || (MENU_LIST != []) < 2 && (!helper_mode) && llGetInventoryType(select_script) == INVENTORY_SCRIPT)
    {
        llMessageLinked(LINK_SET, 90009, CONTROLLER, MY_SITTER);
    }
    else
    {
        string menu = product + version;
        if (BRAND)
            menu = BRAND;
        if (CONTROLLER != MY_SITTER || has_RLV)
        {
            menu += "\n\nMenu for " + llKey2Name(MY_SITTER);
        }
        menu += "\n\n";
        if (CUSTOM_TEXT)
        {
            menu += CUSTOM_TEXT + "\n";
        }
        if (SITTER_INFO)
        {
            menu += "[" + llList2String(llParseStringKeepNulls(SITTER_INFO, ["�"], []), 0) + "]";
        }
        else if (number_of_sitters > 1)
        {
            menu += "[Sitter " + (string)SCRIPT_CHANNEL + "]";
        }
        integer anim_has_speeds;
        string animation_file = llList2String(llParseStringKeepNulls(llList2String(DATA_LIST, ANIM_INDEX), ["�"], []), 0);
        if (llGetInventoryType(animation_file + "+") == INVENTORY_ANIMATION)
        {
            anim_has_speeds = TRUE;
        }
        string CURRENT_POSE_NAME;
        if (~FIRST_INDEX)
        {
            CURRENT_POSE_NAME = llList2String(MENU_LIST, ANIM_INDEX);
            menu += " [" + llList2String(llParseString2List(CURRENT_POSE_NAME, ["P:"], []), 0);
            if (anim_has_speeds)
            {
                if (speed_index < 0)
                {
                    menu += ", Soft";
                }
                else if (speed_index > 0)
                {
                    menu += ", Hard";
                }
            }
            menu += "]";
        }
        integer total_items;
        integer i = current_menu + 1;
        while (i++ < (MENU_LIST != []) && llSubStringIndex(llList2String(MENU_LIST, i), "M:"))
        {
            ++total_items;
        }
        list menu_items0;
        list menu_items2;
        if ((~current_menu) || llGetInventoryType(select_script) == INVENTORY_SCRIPT)
        {
            menu_items0 += "[BACK]";
        }
        string submenu_info;
        if (~current_menu)
        {
            submenu_info = llList2String(DATA_LIST, current_menu);
        }
        if (helper_mode)
        {
            menu_items2 += "[NEW]";
            if (CURRENT_POSE_NAME)
            {
                menu_items2 += "[DUMP]";
                menu_items2 += "[SAVE]";
            }
        }
        else if (~llSubStringIndex(submenu_info, "V"))
        {
            menu_items0 += "<< Softer";
            menu_items0 += "Harder >>";
        }
        if (AMENU == 2 || (AMENU == 1 && (!~current_menu)) || (~llSubStringIndex(submenu_info, "A")))
        {
            if (!(OLD_HELPER_METHOD && helper_mode))
            {
                menu_items2 += "[ADJUST]";
            }
        }
        if (llSubStringIndex(onSit, "ASK") && ((!~current_menu) && SWAP == 1 || SWAP == 2 || (~llSubStringIndex(submenu_info, "S"))) && (number_of_sitters > 1 && (!(llGetInventoryType(select_script) == INVENTORY_SCRIPT))))
        {
            menu_items2 += "[SWAP]";
        }
        if (!~current_menu)
        {
            if (has_RLV && (llGetSubString(RLVDesignations, SCRIPT_CHANNEL, SCRIPT_CHANNEL) == "D" || CONTROLLER != MY_SITTER))
            {
                menu_items2 += "[STOP]";
                if (!helper_mode)
                {
                    menu_items2 += ["Control..."];
                }
            }
        }
        integer items_per_page = 12 - (menu_items2 != []) - (menu_items0 != []);
        if (items_per_page < total_items)
        {
            menu_items2 += ["[<<]", "[>>]"];
            items_per_page -= 2;
        }
        list menu_items1;
        integer page_start = i = current_menu + 1 + menu_page * items_per_page;
        do
        {
            if (i < (MENU_LIST != []))
            {
                string m = llList2String(MENU_LIST, i);
                if (!llSubStringIndex(m, "M:"))
                {
                    jump end;
                }
                if (!~llListFindList(["T:", "P:", "B:"], [llGetSubString(m, 0, 1)]))
                {
                    menu_items1 += m;
                }
                else
                {
                    menu_items1 += llGetSubString(m, 2, -1);
                }
            }
        }
        while (++i < page_start + items_per_page);
        @end;
        if (animation_menu_function == 1)
        {
            integer pages = total_items / (12 - (menu_items2 != []) - (menu_items0 != []));
            if (!(total_items % (12 - (menu_items2 != []) - (menu_items0 != []))))
            {
                pages--;
            }
            return pages;
        }
        if (submenu_info == "V")
        {
            while ((menu_items1 != []) < items_per_page)
            {
                menu_items1 += " ";
            }
        }
        llListenRemove(menu_handle);
        menu_handle = llListen(menu_channel, "", CONTROLLER, "");
        llDialog(CONTROLLER, menu, order_buttons(menu_items0 + menu_items1 + menu_items2), menu_channel);
    }
    return 0;
}
default
{
    state_entry()
    {
        memory();
        SCRIPT_CHANNEL = (integer)llGetSubString(llGetScriptName(), llSubStringIndex(llGetScriptName(), " "), -1);
        if (SCRIPT_CHANNEL)
            main_script += " " + (string)SCRIPT_CHANNEL;
        if (llGetInventoryType(main_script) == INVENTORY_SCRIPT)
        {
            llResetOtherScript(main_script);
        }
    }
    listen(integer listen_channel, string name, key id, string msg)
    {
        string channel;
        integer index = llListFindList(MENU_LIST, [msg]);
        if (!~index)
        {
            channel = (string)SCRIPT_CHANNEL;
            index = llListFindList(MENU_LIST, ["P:" + msg]);
        }
        if (~index)
        {
            llMessageLinked(LINK_THIS, 90050, (string)channel + "|" + msg + "|" + (string)SET, MY_SITTER);
            llMessageLinked(LINK_THIS, 90000, msg, channel);
            if (MTYPE != 2 && MTYPE != 4)
            {
                llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([id, MY_SITTER], "|"));
            }
            return;
        }
        index = llListFindList(MENU_LIST, ["M:" + msg]);
        if (~index)
        {
            llMessageLinked(LINK_SET, 90051, (string)channel + "|" + llGetSubString(msg, 0, -2) + "|" + (string)SET, MY_SITTER);
            menu_page = 0;
            last_menu = current_menu;
            current_menu = index;
            animation_menu(0);
            return;
        }
        index = llListFindList(MENU_LIST, ["B:" + msg]);
        if (~index)
        {
            list button_data = llParseStringKeepNulls(llList2String(DATA_LIST, index), ["�"], []);
            if (llList2String(button_data, 1))
            {
                msg = llList2String(button_data, 1);
            }
            integer n = llList2Integer(button_data, 0);
            if (llGetListLength(button_data) > 2)
            {
                id = llList2String(button_data, 2);
            }
            else if (CONTROLLER != MY_SITTER)
            {
                id = llDumpList2String([CONTROLLER, MY_SITTER], "|");
            }
            llMessageLinked(LINK_SET, n, msg, id);
            return;
        }
        if (msg == "[>>]" || msg == "[<<]")
        {
            if (msg == "[<<]")
            {
                if (!~--menu_page)
                {
                    menu_page = animation_menu(1);
                }
            }
            else
            {
                if (++menu_page > animation_menu(1))
                {
                    menu_page = 0;
                }
            }
            animation_menu(0);
        }
        else if (msg == "[BACK]")
        {
            menu_page = 0;
            if (!~current_menu)
            {
                if (llGetInventoryType(select_script) == INVENTORY_SCRIPT)
                {
                    llMessageLinked(LINK_SET, 90009, "", id);
                }
                return;
            }
            else
            {
                if (~last_menu)
                {
                    current_menu = last_menu;
                    last_menu = -1;
                }
                else
                {
                    current_menu = llListFindList(MENU_LIST, ["T:" + llGetSubString(llList2String(MENU_LIST, current_menu), 2, -1)]);
                    if (~current_menu)
                    {
                        current_menu -= 1;
                        while ((~current_menu) && llSubStringIndex(llList2String(MENU_LIST, current_menu), "M:") != 0)
                        {
                            current_menu--;
                        }
                    }
                }
            }
            animation_menu(0);
        }
        else if (msg == "Control..." || msg == "[STOP]")
        {
            llMessageLinked(LINK_SET, 90100, llDumpList2String([SCRIPT_CHANNEL, msg, MY_SITTER], "|"), id);
        }
        else if (!~index)
        {
            llMessageLinked(LINK_SET, 90101, llDumpList2String([SCRIPT_CHANNEL, msg, CONTROLLER], "|"), MY_SITTER);
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
            {
                speed_index = 0;
                if (!OLD_HELPER_METHOD)
                {
                    helper_mode = FALSE;
                }
                MY_SITTER = "";
                ANIM_INDEX = FIRST_INDEX;
            }
            else
            {
                if (OLD_HELPER_METHOD)
                {
                    helper_mode = FALSE;
                }
            }
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        integer one = (integer)msg;
        integer two = (integer)((string)id);
        if (num == 90000 || num == 90010 || num == 90003)
        {
            integer index = llListFindList(MENU_LIST, [msg]);
            if (!~index)
            {
                index = llListFindList(MENU_LIST, ["P:" + msg]);
            }
            integer doit;
            if (id == "")
            {
                doit = TRUE;
            }
            else if (id)
            {
                if (id == MY_SITTER)
                {
                    doit = TRUE;
                }
            }
            else if (two == SCRIPT_CHANNEL)
            {
                doit = TRUE;
            }
            if (doit && ((~index) || msg == ""))
            {
                ANIM_INDEX = index;
                integer broadcast = TRUE;
                send_anim_info(broadcast);
                return;
            }
            if (ETYPE == 2)
            {
                if (num != 90010 && llGetSubString(llList2String(MENU_LIST, ANIM_INDEX), 0, 1) != "P:")
                {
                    if (MY_SITTER != "")
                    {
                        llUnSit(MY_SITTER);
                    }
                }
            }
        }
        else if (num == 90045 && sender == llGetLinkNumber() && (ETYPE == 1 || ETYPE == 2))
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            string OLD_SYNC = llList2String(data, 5);
            if (OLD_SYNC != "" && llList2String(MENU_LIST, ANIM_INDEX) == OLD_SYNC)
            {
                ANIM_INDEX = FIRST_INDEX;
                send_anim_info(TRUE);
            }
        }
        else if (num == 90033)
        {
            llListenRemove(menu_handle);
        }
        else if (num == 90004 || num == 90005)
        {
            list data = llParseStringKeepNulls(id, ["|"], []);
            if ((key)llList2String(data, -1) == MY_SITTER)
            {
                key lastController = CONTROLLER;
                CONTROLLER = (key)llList2String(data, 0);
                integer index = llListFindList(MENU_LIST, ["M:" + msg + "*"]);
                if (num == 90004)
                {
                    current_menu = -1;
                }
                else if (~index)
                {
                    last_menu = -1;
                    menu_page = 0;
                    current_menu = index;
                    msg = "";
                }
                animation_menu((integer)msg);
            }
        }
        else if (num == 90030 && (one == SCRIPT_CHANNEL || two == SCRIPT_CHANNEL))
        {
            CONTROLLER = (MY_SITTER = "");
        }
        else if (num == 90100 || num == 90101)
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            if (llList2String(data, 1) == "[HELPER]")
            {
                menu_page = 0;
                helper_mode = (!helper_mode);
                if ((key)llList2String(data, 2) == MY_SITTER && (!OLD_HELPER_METHOD))
                {
                    animation_menu(0);
                }
            }
            else if (llList2String(data, 1) == "[ADJUST]")
            {
                helper_mode = FALSE;
                menu_page = 0;
            }
            else if (llList2String(data, 1) == "Harder >>")
            {
                ++speed_index;
                if (speed_index > 1)
                    speed_index = 1;
                send_anim_info(FALSE);
            }
            else if (llList2String(data, 1) == "<< Softer")
            {
                --speed_index;
                if (speed_index < -1)
                    speed_index = -1;
                send_anim_info(FALSE);
            }
        }
        else if (num == 90201)
        {
            has_RLV = FALSE;
        }
        else if (num == 90202)
        {
            has_RLV = (integer)msg;
        }
        else if (one == SCRIPT_CHANNEL)
        {
            list data = llParseStringKeepNulls(id, ["|"], []);
            integer index = llListFindList(MENU_LIST, [llList2String(data, 0)]);
            if (!~index)
            {
                index = llListFindList(MENU_LIST, ["P:" + llList2String(data, 0)]);
            }
            if (num == 90299)
            {
                MENU_LIST = (DATA_LIST = (POS_ROT_LIST = []));
            }
            else if (num == 90070)
            {
                CONTROLLER = (MY_SITTER = id);
                menu_page = 0;
                current_menu = -1;
                menu_channel = ((integer)llFrand(2147483646) + 1) * -1;
                llListenRemove(menu_handle);
            }
            else if (num == 90065 && sender == llGetLinkNumber())
            {
                CONTROLLER = (MY_SITTER = "");
                llListenRemove(menu_handle);
            }
            else if (num == 90300)
            {
                integer place_to_add = llGetListLength(MENU_LIST);
                if (llGetListLength(data) > 2)
                {
                    place_to_add = current_menu;
                    while (place_to_add < llGetListLength(MENU_LIST) && llSubStringIndex(llList2String(MENU_LIST, place_to_add + 1), "M:"))
                    {
                        ++place_to_add;
                    }
                    if (!llSubStringIndex(llList2String(MENU_LIST, place_to_add + 1), "M:"))
                    {
                        ++place_to_add;
                    }
                }
                MENU_LIST = llListInsertList(MENU_LIST, [llList2String(data, 0)], place_to_add);
                DATA_LIST = llListInsertList(DATA_LIST, [llList2String(data, 1)], place_to_add);
                POS_ROT_LIST = llListInsertList(POS_ROT_LIST, [0, 0], place_to_add * 2);
                if (llGetListLength(data) == 4)
                {
                    if (!~FIRST_INDEX)
                    {
                        FIRST_INDEX = place_to_add;
                    }
                    if (~index)
                    {
                        place_to_add = index;
                    }
                    POS_ROT_LIST = llListReplaceList(POS_ROT_LIST, [(vector)llList2String(data, 2), (vector)llList2String(data, 3)], place_to_add * 2, place_to_add * 2 + 1);
                    ANIM_INDEX = place_to_add;
                    send_anim_info(TRUE);
                    memory();
                }
            }
            else if (num == 90301)
            {
                if (~index)
                {
                    POS_ROT_LIST = llListReplaceList(POS_ROT_LIST, [(vector)llList2String(data, 1), (vector)llList2String(data, 2)], index * 2, index * 2 + 1);
                    if (llGetListLength(data) != 3)
                    {
                        send_anim_info(FALSE);
                    }
                }
            }
            else if (num == 90302)
            {
                number_of_sitters = (integer)llList2String(data, 0);
                SITTER_INFO = llList2String(data, 1);
                SET = (integer)llList2String(data, 2);
                MTYPE = (integer)llList2String(data, 3);
                ETYPE = (integer)llList2String(data, 4);
                SWAP = (integer)llList2String(data, 5);
                FIRST_INDEX = (ANIM_INDEX = llListFindList(MENU_LIST, [llList2String(data, 6)]));
                BRAND = llList2String(data, 7);
                CUSTOM_TEXT = llList2String(data, 8);
                ADJUST_MENU = llList2String(data, 9);
                SELECT = (integer)llList2String(data, 10);
                AMENU = (integer)llList2String(data, 11);
                OLD_HELPER_METHOD = (integer)llList2String(data, 12);
                RLVDesignations = llList2String(data, 13);
                onSit = llList2String(data, 14);
                memory();
            }
            else if (num == 90020 && llList2String(data, 0) == "")
            {
                Readout_Say("V:" + llDumpList2String([version, MTYPE, ETYPE, SET, SWAP, SITTER_INFO, CUSTOM_TEXT, ADJUST_MENU, SELECT, AMENU, OLD_HELPER_METHOD], "|"));
                integer i = -1;
                while (++i < (MENU_LIST != []))
                {
                    llSleep(0.5);
                    Readout_Say("S:" + llList2String(MENU_LIST, i) + "|" + llList2String(DATA_LIST, i));
                }
                i = -1;
                while (++i < (MENU_LIST != []))
                {
                    if (llList2Vector(POS_ROT_LIST, i * 2))
                    {
                        llSleep(0.2);
                        Readout_Say("{" + llList2String(MENU_LIST, i) + "}" + llList2String(POS_ROT_LIST, i * 2) + llList2String(POS_ROT_LIST, i * 2 + 1));
                    }
                }
                llMessageLinked(LINK_THIS, 90021, (string)SCRIPT_CHANNEL, "");
            }
        }
    }
}
