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
 
float version = 1.1;
string helper_name = "AVhelper";
string notecard_name = "AVpos";
key notecard_key;
integer active_link;
integer active_sitter;
string pose_name;
integer total_scripts;
list HELPER_KEY_LIST;
list HELPER_AV_LIST;
list INVOLVED;
list HELPER_POS_ROT;
list HELPERS_REZZED;
integer menu_page;
string adding;
string last_text;
integer choosing;
integer choice_page;
integer choice_pages;
integer number_per_page = 9;
string chosen_animation;
string chosen_animation2;
integer dont_move;
integer comm_channel;
string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}
Owner_Say(string say)
{
    llOwnerSay(llGetScriptName() + ": " + say);
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
clean_avhelper()
{
    integer i;
    for (i = 0; i < llGetInventoryNumber(INVENTORY_OBJECT); i++)
    {
        if (llGetSubString(llGetInventoryName(INVENTORY_OBJECT, i), 0, llStringLength(helper_name) - 1) == helper_name)
        {
            llOwnerSay("Cleaning \"" + llGetInventoryName(INVENTORY_OBJECT, i) + "\" from prim " + (string)llGetLinkNumber());
            llRemoveInventory(llGetInventoryName(INVENTORY_OBJECT, i));
            i--;
        }
    }
}
calc_sit_target(integer script, key av, key target)
{
    if (llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0) != ZERO_VECTOR)
    {
        list details = [OBJECT_POS, OBJECT_ROT];
        rotation f = llList2Rot(details = llGetObjectDetails(llGetLinkKey(active_link), details) + llGetObjectDetails(target, details), 1);
        rotation target_rot = llList2Rot(details, 3) / f;
        vector target_pos = (llList2Vector(details, 2) - llList2Vector(details, 0)) / f;
        string posrot = (string)target_pos + "|" + (string)(llRot2Euler(target_rot) * RAD_TO_DEG);
        llMessageLinked(active_link, 90090, (string)script, posrot);
        HELPER_POS_ROT = llListReplaceList(HELPER_POS_ROT, [posrot], script, script);
        llRegionSay(comm_channel, "POS|" + (string)script + "|" + convert_to_world_positions(script));
    }
}
string convert_to_world_positions(integer num)
{
    list details = llGetObjectDetails(llGetLinkKey(active_link), [OBJECT_POS, OBJECT_ROT]);
    list HELPER_POSITION = llParseStringKeepNulls(llList2String(HELPER_POS_ROT, num), ["|"], []);
    rotation target_rot = llEuler2Rot((vector)llList2String(HELPER_POSITION, 1) * DEG_TO_RAD) * llList2Rot(details, 1);
    vector target_pos = (vector)llList2String(HELPER_POSITION, 0) * llList2Rot(details, 1) + llList2Vector(details, 0);
    return (string)target_pos + "|" + (string)target_rot;
}
new_menu()
{
    menu_page = 0;
    list menu_items = ["[BACK]", "~", "~", "[POSE]", "[SYNC]", "[SUBMENU]"];
    string menu_text = "\nWhat would you like to create?:";
    llDialog(llGetOwner(), menu_text, order_buttons(menu_items), comm_channel);
}
choice_menu(list options, string menu_text)
{
    last_text = menu_text;
    choosing = TRUE;
    menu_text = "\n" + menu_text + "\n\n";
    list menu_items;
    integer i;
    if (llGetListLength(options) == 0)
    {
        menu_text = "\nNo animations in the prim inventory.";
        menu_items = ["[BACK]"];
    }
    else
    {
        for (i = 0; i < llGetListLength(options); i++)
        {
            menu_items += (string)(i + 1);
            menu_text += (string)(i + 1) + "." + llList2String(options, i) + "\n";
        }
        while (llGetListLength(menu_items) < number_per_page)
        {
            menu_items += "~";
        }
        menu_items += ["[BACK]", "[PAGE-]", "[PAGE+]"];
    }
    llDialog(llGetOwner(), menu_text, order_buttons(menu_items), comm_channel);
}
list get_contents(integer type, integer newpage)
{
    choice_page = newpage;
    list contents;
    integer i;
    integer start = number_per_page * choice_page;
    integer end = start + number_per_page;
    for (i = start; i < end; i++)
    {
        if (i < llGetInventoryNumber(type))
        {
            if (type != INVENTORY_OBJECT || type == INVENTORY_OBJECT && llGetInventoryName(type, i) != "AVhelper")
            {
                contents += llGetInventoryName(type, i);
            }
        }
    }
    i = llGetInventoryNumber(type);
    if (type == INVENTORY_OBJECT)
    {
        i--;
    }
    choice_pages = i / number_per_page;
    return contents;
}
default
{
    state_entry()
    {
        notecard_key = llGetInventoryKey(notecard_name);
        comm_channel = ((integer)llFrand(999999) + 1) * 1000 * -1;
        llMessageLinked(LINK_SET, comm_channel, "Adjuster-Check", NULL_KEY);
        llListen(comm_channel, "", "", "");
        llListen(5, "", llGetOwner(), "cleanup");
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (llGetInventoryType(helper_name) == INVENTORY_OBJECT)
            {
                llMessageLinked(LINK_SET, 90085, "", NULL_KEY);
            }
        }
        else if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(notecard_name) != notecard_key)
            {
                llRegionSay(comm_channel, "DONEA");
                notecard_key = llGetInventoryKey(notecard_name);
            }
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90030)
        {
            HELPER_AV_LIST = llListReplaceList(HELPER_AV_LIST, [NULL_KEY], (integer)msg, (integer)msg);
            HELPER_AV_LIST = llListReplaceList(HELPER_AV_LIST, [NULL_KEY], (integer)((string)id), (integer)((string)id));
            integer i = llList2Integer(HELPERS_REZZED, (integer)msg);
            HELPERS_REZZED = llListReplaceList(HELPERS_REZZED, [llList2Integer(HELPERS_REZZED, (integer)((string)id))], (integer)msg, (integer)msg);
            HELPERS_REZZED = llListReplaceList(HELPERS_REZZED, [i], (integer)((string)id), (integer)((string)id));
            llRegionSay(comm_channel, "SWAP|" + (string)((integer)msg) + "|" + (string)((integer)((string)id)));
        }
        else if (num == 90010)
        {
            integer i;
            for (i = 0; i < llGetListLength(HELPER_AV_LIST); i++)
            {
                if (llList2Integer(HELPERS_REZZED, i) == TRUE)
                {
                    if (llList2Key(HELPER_AV_LIST, i) != NULL_KEY)
                    {
                        calc_sit_target(i, llList2Key(HELPER_AV_LIST, i), llList2Key(HELPER_AV_LIST, i));
                    }
                    else
                    {
                        calc_sit_target(i, llList2Key(HELPER_AV_LIST, i), llList2Key(HELPER_KEY_LIST, i));
                    }
                }
            }
            string type = "POSE '" + pose_name;
            if (llSubStringIndex(pose_name, "S:") == 0)
            {
                type = "SYNC '" + llGetSubString(pose_name, 2, -1);
            }
            llSay(0, type + "' saved to memory.");
        }
        else if (num == 90060)
        {
            llRegionSay(comm_channel, "DONEA");
        }
        else if (num == 90040)
        {
            active_link = sender;
            if (llGetNumberOfPrims() == 1)
            {
                active_link = 0;
            }
            list data = llParseString2List(msg, ["|"], []);
            HELPER_POS_ROT = [];
            INVOLVED = [];
            total_scripts = llList2Integer(data, 1);
            integer i;
            for (i = 0; i < total_scripts; i++)
            {
                HELPER_POS_ROT += "~";
                INVOLVED += FALSE;
            }
            active_sitter = llList2Integer(data, 0);
            llMessageLinked(active_link, 90110, (string)active_sitter, "");
        }
        else if (num == 90100)
        {
            llRegionSay(comm_channel, "DONEA");
            integer i = llGetNumberOfPrims();
            while (llGetAgentSize(llGetLinkKey(i)) != ZERO_VECTOR)
            {
                llUnSit(llGetLinkKey(i));
                i--;
            }
            active_link = sender;
            if (llGetNumberOfPrims() == 1)
            {
                active_link = 0;
            }
            list data = llParseString2List(msg, ["|"], []);
            HELPER_KEY_LIST = [];
            HELPER_AV_LIST = [];
            INVOLVED = [];
            HELPER_POS_ROT = [];
            HELPERS_REZZED = [];
            total_scripts = llList2Integer(data, 1);
            for (i = 0; i < total_scripts; i++)
            {
                HELPER_KEY_LIST += NULL_KEY;
                HELPER_AV_LIST += NULL_KEY;
                INVOLVED += FALSE;
                HELPER_POS_ROT += "~";
                HELPERS_REZZED += FALSE;
            }
            active_sitter = llList2Integer(data, 0);
            llMessageLinked(active_link, 90110, (string)active_sitter, "");
        }
        else if (num == 90070 && sender == active_link)
        {
            HELPER_AV_LIST = llListReplaceList(HELPER_AV_LIST, [id], (integer)msg, (integer)msg);
        }
        else if (num == 90130)
        {
            list data = llParseString2List(msg, [">"], []);
            integer sending_script = (integer)((string)id);
            HELPER_POS_ROT = llListReplaceList(HELPER_POS_ROT, [llList2String(data, 0) + ">" + "|" + llList2String(data, 1) + ">"], sending_script, sending_script);
            INVOLVED = llListReplaceList(INVOLVED, [llList2Integer(data, 2)], sending_script, sending_script);
            if (llListFindList(HELPER_POS_ROT, ["~"]) == -1)
            {
                integer i;
                for (i = 0; i < llGetListLength(HELPERS_REZZED); i++)
                {
                    if (llList2Integer(INVOLVED, i) != FALSE)
                    {
                        if (llList2Integer(HELPERS_REZZED, i) == FALSE)
                        {
                            llRezObject(helper_name, llGetPos(), ZERO_VECTOR, llGetRot(), comm_channel + i * -1);
                            HELPERS_REZZED = llListReplaceList(HELPERS_REZZED, [TRUE], i, i);
                        }
                        else
                        {
                            if (!dont_move)
                            {
                                llRegionSay(comm_channel, "POS|" + (string)i + "|" + convert_to_world_positions(i));
                            }
                        }
                    }
                    else if (llList2Integer(HELPERS_REZZED, i) == TRUE)
                    {
                        if (llList2Key(HELPER_AV_LIST, i) != NULL_KEY)
                        {
                            HELPER_AV_LIST = llListReplaceList(HELPER_AV_LIST, [NULL_KEY], i, i);
                            llMessageLinked(LINK_THIS, 90075, (string)i, NULL_KEY);
                        }
                        HELPERS_REZZED = llListReplaceList(HELPERS_REZZED, [FALSE], i, i);
                        llRegionSay(comm_channel, "DONE|" + (string)i);
                    }
                }
                dont_move = FALSE;
            }
        }
        if (num == 90160)
        {
            if (id == llGetOwner())
            {
                active_sitter = (integer)msg;
                if (sender == llGetLinkNumber())
                {
                    adding = "";
                    new_menu();
                }
                else
                {
                    llInstantMessage(id, "Sorry, the [NEW] menu is only available if your AVadjuster and AVhelper are in the same prim as your AVsit.");
                }
            }
            else
            {
                llInstantMessage(id, "Sorry, the [NEW] menu is for owner only.");
            }
        }
        else if (msg == "Adjuster-Check" && num != comm_channel)
        {
            clean_avhelper();
            llOwnerSay("Deleting \"" + llGetScriptName() + "\" from prim " + (string)llGetLinkNumber());
            llOwnerSay("Please place only one Adjuster in your linkset!");
            llRemoveInventory(llGetScriptName());
        }
        else if (num == 90045)
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            pose_name = llList2String(data, 0);
        }
    }
    listen(integer chan, string name, key id, string message)
    {
        if (chan == 5)
        {
            llRegionSay(comm_channel, "DONEA");
            clean_avhelper();
            llOwnerSay("Cleaning \"" + llGetScriptName() + "\" from prim " + (string)llGetLinkNumber());
            llRemoveInventory(llGetScriptName());
        }
        else if (id == llGetOwner())
        {
            if (message == "[PAGE+]")
            {
                choice_page++;
                if (choice_page > choice_pages)
                {
                    choice_page = 0;
                }
                choice_menu(get_contents(INVENTORY_ANIMATION, choice_page), last_text);
            }
            else if (message == "[PAGE-]")
            {
                choice_page--;
                if (choice_page < 0)
                {
                    choice_page = choice_pages;
                }
                choice_menu(get_contents(INVENTORY_ANIMATION, choice_page), last_text);
            }
            else if (message == "[BACK]")
            {
                llMessageLinked(LINK_SET, 90005, "", id);
            }
            else if (message == "[POSE]")
            {
                adding = message;
                choice_menu(get_contents(INVENTORY_ANIMATION, 0), "Please choose your animation:");
            }
            else if (message == "[SYNC]")
            {
                if (total_scripts < 2)
                {
                    Owner_Say("To create a SYNC via menu requires 2 AVsit scripts in the prim!");
                    new_menu();
                }
                else
                {
                    adding = message;
                    choice_menu(get_contents(INVENTORY_ANIMATION, 0), "Please choose your first animation:");
                }
            }
            else if (message == "[SUBMENU]")
            {
                adding = message;
                llTextBox(llGetOwner(), "\n\nPlease type a name for your submenu:", comm_channel);
            }
            else if (llListFindList(["1", "2", "3", "4", "5", "6", "7", "8", "9"], [message]) != -1 && (adding == "[POSE]" || adding == "[SYNC]" || adding == "[SYNC]2"))
            {
                string anim = llList2String(get_contents(INVENTORY_ANIMATION, choice_page), (integer)message - 1);
                if (adding == "[POSE]")
                {
                    adding = "[POSE]2";
                    chosen_animation = anim;
                    llTextBox(llGetOwner(), "\n\nPlease type a menu name for pose\n\nAnimation: " + chosen_animation, comm_channel);
                }
                else if (adding == "[SYNC]2")
                {
                    adding = "[SYNC]3";
                    chosen_animation2 = anim;
                    llTextBox(llGetOwner(), "\n\nPlease type a menu name for sync\n\nAnimation1: " + chosen_animation + "\nAnimation2: " + chosen_animation2, comm_channel);
                }
                else if (adding == "[SYNC]")
                {
                    adding = "[SYNC]2";
                    chosen_animation = anim;
                    choice_menu(get_contents(INVENTORY_ANIMATION, 0), "Please choose your second animation:");
                }
            }
            else
            {
                message = strReplace(message, "\n", "");
                message = strReplace(message, "|", "");
                message = llGetSubString(message, 0, 22);
                if (message == "")
                {
                    llMessageLinked(LINK_SET, 90005, "", id);
                }
                else if (adding == "[SUBMENU]")
                {
                    llMessageLinked(active_link, 90170, (string)active_sitter, "T:" + message + "*|");
                    llMessageLinked(active_link, 90170, (string)active_sitter, "M:" + message + "*|");
                    Owner_Say("Created submenu '" + message + "' in SITTER " + (string)active_sitter);
                    llMessageLinked(LINK_SET, 90005, "", id);
                }
                else if (adding == "[POSE]2")
                {
                    llMessageLinked(active_link, 90170, (string)active_sitter, message + "|" + chosen_animation);
                    llMessageLinked(active_link, 90110, (string)active_sitter, "");
                    llSay(0, "Added POSE '" + message + "' using anim '" + chosen_animation + "' in SITTER " + (string)active_sitter);
                    dont_move = TRUE;
                }
                else if (adding == "[SYNC]3")
                {
                    message = "S:" + message;
                    llMessageLinked(active_link, 90170, (string)0, message + "|" + chosen_animation);
                    llMessageLinked(active_link, 90170, (string)1, message + "|" + chosen_animation2);
                    llMessageLinked(active_link, 90110, (string)active_sitter, "");
                    llSay(0, "Added SYNC '" + llGetSubString(message, 2, -1) + "' using anms '" + chosen_animation + "' and '" + chosen_animation2 + "'");
                    dont_move = TRUE;
                }
                if (adding == "[POSE]2" || adding == "[SYNC]3")
                {
                    llMessageLinked(LINK_SET, 90005, "", id);
                    HELPER_POS_ROT = [];
                    INVOLVED = [];
                    integer i;
                    for (i = 0; i < total_scripts; i++)
                    {
                        HELPER_POS_ROT += "~";
                        INVOLVED += FALSE;
                    }
                }
            }
        }
        else if (llGetOwnerKey(id) == llGetOwner())
        {
            list data = llParseString2List(message, ["|"], []);
            integer num = llList2Integer(data, 1);
            if (llList2String(data, 0) == "REG")
            {
                HELPER_KEY_LIST = llListReplaceList(HELPER_KEY_LIST, [id], num, num);
                llRegionSay(comm_channel, "POS|" + (string)num + "|" + convert_to_world_positions(num));
            }
            else if (llList2String(data, 0) == "ANIMA")
            {
                integer i;
                for (i = 0; i < llGetListLength(HELPER_AV_LIST); i++)
                {
                    if (llList2Key(HELPER_AV_LIST, i) == llList2Key(data, 2))
                    {
                        HELPER_AV_LIST = llListReplaceList(HELPER_AV_LIST, [NULL_KEY], i, i);
                        llMessageLinked(LINK_SET, 90075, (string)i, NULL_KEY);
                    }
                }
                llMessageLinked(active_link, 90050, (string)llList2Key(data, 1), llList2Key(data, 2));
            }
            else if (llList2String(data, 0) == "GETUP")
            {
                HELPER_AV_LIST = llListReplaceList(HELPER_AV_LIST, [NULL_KEY], num, num);
                llMessageLinked(LINK_SET, 90075, (string)num, NULL_KEY);
            }
            else if (llList2String(data, 0) == "MENU")
            {
                llMessageLinked(LINK_SET, 90005, "3", llList2Key(data, 2));
            }
        }
    }
    on_rez(integer x)
    {
        llResetScript();
    }
}
