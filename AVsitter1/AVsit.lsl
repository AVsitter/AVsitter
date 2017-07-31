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
 
/*
AVsitter1 link message notes (rough)
99899 = Bring up AVselect menu
89999 = Another avatar controls menu
90000 = Play an animation llList2String(llParseStringKeepNulls(llList2String(MENU_STRUCTURE,mindex_test),[":"],[]),1),(string)script_channel);
90001 = Play an additional animation
90005 = Touched "", llDetectedKey(0)); // give the menu
90006 = Bring the ADJUST MENU
90010 = Tell the Adjuster to Save
90020 = Tell Animators to Readout (string)(script_channel+1),"");    
90025 = Tell AVselect to dump SITTER line
90030 = Tell Animators and Adjuster to SWAP (string)script_channel, (string)target_script);    
90040 = New Helper Animation (string)script_channel+"|"+(string)llGetListLength(SITTERS),"");    
90045 = play_anim reports the pose name and animation name and avatar
90050 = Adjuster tells Animator to animate an avi (string)llList2Key(data,1),llList2Key(data,2));
90055 = Outgoing/internal version of 90000
90060 = Done All (clear helpers) and Welcome Sitter "",llAvatarOnSitTarget()); 
90065 = Goodbye Sitter "",llList2Key(SITTERS,script_channel));
90070 = Manipulate SITTERS list and Adjusters sitters list from another animators perms granted
90075 = Manipulate SITTERS with NULL_KEY
90085 = Adjuster informs has helper "",NULL_KEY);
90090 = Save a Pose when in HELPER mode posrot,(string)script);
90100 = Animator tells Adjuster to Start HELPER mode (string)script_channel+"|"+(string)llGetListLength(SITTERS),"");
90110 = Adjuster replies Helper Mode Started (string)initiating_script,"");
90120 = Animator asks all Animators to inform Adjuster of animation involvement llList2String(ANIMATION_GIVENNAMES,anim_index),(string)script_channel
90130 = Reply to Adjuster of involvement (string)CURRENT_POSITION+"|"+(string)CURRENT_ROTATION+"|"+(string)involved,(string)script_channel);
90140 = Tell AVplay to open the EXTRAS menu
90150 = AVplay tells other AVplay to adjust camera for an avi
90160 = [NEW] pressed
90170 = add POSE/SYNC/SUBMENU
90180 = message to set sit target
90190 = sit-target scripts say "here I am"
90200 = For buttons within the same prim to tell AVplay to 'sticky rez' a prop
*/

string product_and_version = "AVsitter™ 1.29";
key avkey;
key controller;
string notecard_name = "AVpos";
string sitter_text;
list SITTERS;
integer script_channel;
key notecard_key;
key notecard_query;
integer has_helper;
integer helper_mode;
string swap_text;
integer menu_type;
integer exit_type;
integer select_type;
list loops;
integer menu_handle;
integer menu_channel;
list MENU_LIST;
list DATA_LIST;
list POS_LIST;
list ROT_LIST;
list CUSTOMS;
integer variable1;
integer reading_notecard_section;
vector CURRENT_POSITION;
vector CURRENT_ROTATION;
vector DEFAULT_POSITION;
vector DEFAULT_ROTATION;
string CURRENT_ANIMATION_FILENAME;
integer anim_index;
integer first_anim = -1;
integer current_menu = -1;
integer menu_page;
integer increment_pointer;
integer pos_rot_adjust_toggle;
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
Owner_Say(string say)
{
    llOwnerSay(llGetScriptName() + ":" + say);
}
Readout_Say(string say)
{
    llSleep(0.2);
    llRegionSayTo(llGetOwner(), 0, "◆" + say);
}
integer animation_menu(integer return_pages)
{
    if (return_pages == 2 || llGetListLength(MENU_LIST) < 2 && (!helper_mode) && llGetInventoryType("AVselect") == INVENTORY_SCRIPT)
    {
        llMessageLinked(LINK_SET, 99899, "", controller);
    }
    else
    {
        swap_text = "[SWAP]";
        if (llGetInventoryType("AVselect") == INVENTORY_SCRIPT)
        {
            swap_text = "[SELECT]";
        }
        string menu;
        if (llGetListLength(SITTERS) > 1)
        {
            menu = "Sitter " + (string)script_channel;
        }
        if (sitter_text != "")
        {
            menu = sitter_text;
        }
        if (current_menu != -1)
        {
            menu += ">" + llGetSubString(llList2String(MENU_LIST, current_menu), 2, -2);
        }
        string menu_text = "\n" + product_and_version + "\n" + menu;
        integer total_items;
        integer i = current_menu + 1;
        while (i < llGetListLength(MENU_LIST) && llSubStringIndex(llList2String(MENU_LIST, i), "M:") != 0)
        {
            total_items++;
            i++;
        }
        list menu_items2;
        if (helper_mode)
        {
            if (llGetInventoryType("AVplus") == INVENTORY_SCRIPT)
            {
                menu_items2 += ["[EXTRA]"];
            }
            menu_items2 += ["[NEW]", "[DUMP]"];
        }
        if (llGetListLength(SITTERS) > 1)
        {
            menu_items2 += [swap_text];
        }
        if (helper_mode)
        {
            menu_items2 += ["[SAVE]"];
        }
        else if (current_menu == -1)
        {
            menu_items2 += ["[ADJUST]"];
        }
        if (current_menu != -1)
        {
            menu_items2 = ["[BACK]"] + menu_items2;
        }
        list menu_items1;
        if (total_items + llGetListLength(menu_items2) > 12)
        {
            menu_items2 += ["[PAGE-]", "[PAGE+]"];
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
        if (return_pages == 1)
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
        llDialog(controller, menu_text, order_buttons(menu_items1 + menu_items2), menu_channel);
    }
    return 0;
}
adjust_menu()
{
    list menu_items = ["[BACK]", "[SAVE]", "[DEFAULT]"];
    string helper = " - ";
    if (has_helper)
    {
        helper = "[HELPER]";
    }
    if (pos_rot_adjust_toggle)
    {
        menu_items += ["ROT", helper, llList2String(["5°", "25°", "1°"], increment_pointer)];
    }
    else
    {
        menu_items += ["POS", helper, llList2String(["0.05m", "0.25m", "0.01m"], increment_pointer)];
    }
    menu_items += ["X+", "Y+", "Z+", "X-", "Y-", "Z-"];
    llDialog(controller, "\nPersonal Adjust:", order_buttons(menu_items), menu_channel);
}
integer get_number_of_scripts()
{
    integer i = 1;
    while (llGetInventoryType("AVsit " + (string)i) == INVENTORY_SCRIPT)
    {
        i++;
    }
    return i;
}
sit_using_prim_params()
{
    integer sitter_prim = llGetNumberOfPrims();
    while (llGetAgentSize(llGetLinkKey(sitter_prim)) != ZERO_VECTOR)
    {
        if (llGetLinkKey(sitter_prim) == llList2Key(SITTERS, script_channel))
        {
            jump ok;
        }
        sitter_prim--;
    }
    return;
    @ok;
    rotation rot = llEuler2Rot((CURRENT_ROTATION + <0,0,0.002>) * DEG_TO_RAD);
    rotation localrot = ZERO_ROTATION;
    vector localpos = ZERO_VECTOR;
    if (llGetLinkNumber() > 1)
    {
        localrot = llGetLocalRot();
        localpos = llGetLocalPos();
    }
    rotation rootrot = llGetRootRotation();
    rootrot *= llEuler2Rot(<0.002,0.002,0.002>);
    llSetLinkPrimitiveParamsFast(sitter_prim, [PRIM_ROTATION, rot * localrot / rootrot, PRIM_POSITION, CURRENT_POSITION * localrot + localpos]);
}
play_anim(integer new_index)
{
    anim_index = new_index;
    string OLD = CURRENT_ANIMATION_FILENAME;
    CURRENT_ANIMATION_FILENAME = llList2String(DATA_LIST, anim_index);
    CURRENT_POSITION = (DEFAULT_POSITION = llList2Vector(POS_LIST, anim_index));
    CURRENT_ROTATION = (DEFAULT_ROTATION = llList2Vector(ROT_LIST, anim_index));
    integer custom_index = llListFindList(CUSTOMS, [anim_index, llList2Key(SITTERS, script_channel)]);
    if (custom_index != -1)
    {
        CURRENT_POSITION = llList2Vector(CUSTOMS, custom_index + 2);
        CURRENT_ROTATION = llList2Vector(CUSTOMS, custom_index + 3);
        CUSTOMS = llListReplaceList(CUSTOMS, [], custom_index, custom_index + 3) + [anim_index, llList2Key(SITTERS, script_channel), CURRENT_POSITION, CURRENT_ROTATION];
    }
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
    {
        if (llGetAgentSize(llList2Key(SITTERS, script_channel)))
        {
            llMessageLinked(LINK_SET, 90045, llList2String(MENU_LIST, anim_index) + "|" + CURRENT_ANIMATION_FILENAME, llList2Key(SITTERS, script_channel));
            if (!helper_mode)
            {
                sit_using_prim_params();
            }
            if (CURRENT_ANIMATION_FILENAME != "")
            {
                llStartAnimation(CURRENT_ANIMATION_FILENAME);
            }
            llSleep(0.5);
            if (OLD != "" && OLD != CURRENT_ANIMATION_FILENAME)
            {
                llStopAnimation(OLD);
            }
        }
    }
}
default
{
    state_entry()
    {
        script_channel = (integer)llGetSubString(llGetScriptName(), llSubStringIndex(llGetScriptName(), " "), -1);
        if (script_channel == 0)
        {
            reading_notecard_section = TRUE;
        }
        integer i;
        for (i = 0; i < get_number_of_scripts(); i++)
        {
            SITTERS += NULL_KEY;
        }
        notecard_key = llGetInventoryKey(notecard_name);
        if (script_channel == 0)
        {
            Owner_Say("Reading...");
        }
        notecard_query = llGetNotecardLine(notecard_name, variable1);
    }
    listen(integer listen_channel, string name, key id, string message)
    {
        if (message == "[BACK]")
        {
            if (menu_type == 3 || llGetListLength(MENU_LIST) == 1 && llGetInventoryType("AVselect") == INVENTORY_SCRIPT)
            {
                llMessageLinked(LINK_SET, 99899, "", id);
                return;
            }
            else
            {
                menu_page = 0;
                current_menu = -1;
                animation_menu(0);
                return;
            }
        }
        integer mindex_test = llListFindList(MENU_LIST, ["S:" + message]);
        if (mindex_test != -1)
        {
            animation_menu(0);
            llMessageLinked(LINK_SET, 90055, "S:" + message, id);
            if (helper_mode)
            {
                llMessageLinked(LINK_SET, 90040, (string)script_channel + "|" + (string)llGetListLength(SITTERS), "");
            }
            return;
        }
        mindex_test = llListFindList(MENU_LIST, [message]);
        if (mindex_test != -1)
        {
            llMessageLinked(LINK_SET, 90055, message, id);
            if (helper_mode)
            {
                llMessageLinked(LINK_SET, 90040, (string)script_channel + "|" + (string)llGetListLength(SITTERS), "");
            }
            play_anim(mindex_test);
            animation_menu(0);
            return;
        }
        mindex_test = llListFindList(MENU_LIST, ["M:" + message]);
        if (mindex_test != -1)
        {
            menu_page = 0;
            current_menu = mindex_test;
            animation_menu(0);
            return;
        }
        mindex_test = llListFindList(MENU_LIST, ["B:" + message]);
        if (mindex_test != -1)
        {
            llMessageLinked(LINK_SET, llList2Integer(DATA_LIST, mindex_test), message, id);
            return;
        }
        if (message == "[PAGE+]" || message == "[PAGE-]")
        {
            if (message == "[PAGE-]")
            {
                menu_page--;
                if (menu_page < 0)
                {
                    menu_page = animation_menu(1);
                }
            }
            else
            {
                menu_page++;
                if (menu_page > animation_menu(1))
                {
                    menu_page = 0;
                }
            }
            animation_menu(0);
        }
        else if (message == swap_text)
        {
            if (llGetInventoryType("AVselect") == INVENTORY_SCRIPT)
            {
                llMessageLinked(LINK_SET, 99899, "", id);
            }
            else
            {
                integer target_script = script_channel + 1;
                if (llSubStringIndex(llList2String(MENU_LIST, anim_index), "S:") == 0 && (!helper_mode))
                {
                    list X = SITTERS + SITTERS;
                    while (llList2Key(X, target_script) == NULL_KEY && target_script + 1 < llGetListLength(X))
                    {
                        target_script++;
                    }
                    if (llList2Key(X, target_script) == llList2Key(SITTERS, script_channel))
                    {
                        target_script++;
                    }
                }
                else if (!helper_mode)
                {
                    list X = SITTERS + SITTERS;
                    while (llList2Key(X, target_script) != NULL_KEY && target_script < llGetListLength(SITTERS) + script_channel + 1)
                    {
                        target_script++;
                    }
                }
                target_script = target_script % llGetListLength(SITTERS);
                llMessageLinked(LINK_SET, 90030, (string)script_channel, (string)target_script);
            }
        }
        else if (message == "[DUMP]")
        {
            llMessageLinked(LINK_THIS, 90020, "0", "");
            animation_menu(0);
        }
        else if (message == "[SAVE]")
        {
            if (helper_mode)
            {
                llMessageLinked(LINK_SET, 90010, "", "");
                animation_menu(0);
            }
            else
            {
                integer custom_index = llListFindList(CUSTOMS, [anim_index, llList2Key(SITTERS, script_channel)]);
                if (custom_index != -1)
                {
                    CUSTOMS = llListReplaceList(CUSTOMS, [], custom_index, custom_index + 3);
                }
                if (CURRENT_POSITION != DEFAULT_POSITION || CURRENT_ROTATION != DEFAULT_ROTATION)
                {
                    if (llGetListLength(CUSTOMS) / 4 >= variable1)
                    {
                        CUSTOMS = llListReplaceList(CUSTOMS, [], 0, 3);
                    }
                    CUSTOMS += [anim_index, llList2Key(SITTERS, script_channel), CURRENT_POSITION, CURRENT_ROTATION];
                }
                llInstantMessage(id, "Saved");
                adjust_menu();
            }
        }
        else if (message == "[DEFAULT]")
        {
            CURRENT_POSITION = DEFAULT_POSITION;
            CURRENT_ROTATION = DEFAULT_ROTATION;
            sit_using_prim_params();
            adjust_menu();
        }
        else if (message == "[ADJUST]")
        {
            adjust_menu();
        }
        else if (message == "POS" || message == "ROT")
        {
            pos_rot_adjust_toggle = (!pos_rot_adjust_toggle);
            adjust_menu();
        }
        else if (llListFindList(["X+", "Y+", "Z+", "X-", "Y-", "Z-"], [message]) != -1)
        {
            float change;
            list increments = ["0.05m", "0.25m", "0.01m"];
            if (pos_rot_adjust_toggle)
            {
                increments = ["5°", "25°", "1°"];
            }
            change += (float)llGetSubString(llList2String(increments, increment_pointer), 0, -1);
            if (llGetSubString(message, 1, 1) == "-")
            {
                change = -1 * change;
            }
            vector direction = <1,0,0>;
            if (llGetSubString(message, 0, 0) == "Y")
            {
                direction = <0,1,0>;
            }
            else if (llGetSubString(message, 0, 0) == "Z")
            {
                direction = <0,0,1>;
            }
            if (pos_rot_adjust_toggle)
            {
                CURRENT_ROTATION += direction * change;
            }
            else
            {
                CURRENT_POSITION += direction * change;
            }
            sit_using_prim_params();
            adjust_menu();
        }
        else if (llListFindList(["0.05m", "0.25m", "0.01m"] + ["5°", "25°", "1°"], [message]) != -1)
        {
            increment_pointer++;
            if (increment_pointer > 2)
            {
                increment_pointer = 0;
            }
            adjust_menu();
        }
        else if (message == "[EXTRA]")
        {
            llMessageLinked(LINK_THIS, 90140, "", id);
        }
        else if (message == "[NEW]")
        {
            llMessageLinked(LINK_SET, 90160, (string)script_channel, id);
        }
        else if (message == "[HELPER]")
        {
            llMessageLinked(LINK_SET, 90100, (string)script_channel + "|" + (string)llGetListLength(SITTERS), "");
        }
    }
    touch_start(integer touched)
    {
        llResetTime();
    }
    touch_end(integer touched)
    {
        if (script_channel == 0 && menu_type != 3)
        {
            llMessageLinked(LINK_SET, 90005, (string)llGetTime(), llDetectedKey(0));
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (helper_mode)
            {
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], script_channel, script_channel);
            }
            list AVRPRIMS;
            integer i = llGetNumberOfPrims();
            if (llGetListLength(SITTERS) == 1)
            {
                if (llAvatarOnSitTarget() != NULL_KEY)
                {
                    if (llAvatarOnSitTarget() != llList2Key(SITTERS, 0))
                    {
                        llSleep(0.1);
                        llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
                        llMessageLinked(LINK_SET, 90060, "", llAvatarOnSitTarget());
                    }
                    AVRPRIMS += llAvatarOnSitTarget();
                }
            }
            else
            {
                while (llGetAgentSize(llGetLinkKey(i)) != ZERO_VECTOR)
                {
                    if (llListFindList(SITTERS, [llGetLinkKey(i)]) == -1)
                    {
                        integer first_available = llListFindList(SITTERS, [NULL_KEY]);
                        if (first_available == script_channel)
                        {
                            llRequestPermissions(llGetLinkKey(i), PERMISSION_TRIGGER_ANIMATION);
                            llMessageLinked(LINK_SET, 90060, "", llGetLinkKey(i));
                        }
                    }
                    AVRPRIMS += llGetLinkKey(i);
                    i--;
                }
            }
            for (i = 0; i < llGetListLength(SITTERS); i++)
            {
                if (llListFindList(AVRPRIMS, [llList2Key(SITTERS, i)]) == -1)
                {
                    if (i == script_channel)
                    {
                        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                        {
                            llListenRemove(menu_handle);
                            if (llList2Key(SITTERS, script_channel) != NULL_KEY)
                            {
                                llMessageLinked(LINK_SET, 90065, "", llList2Key(SITTERS, script_channel));
                                controller = NULL_KEY;
                            }
                            if (llGetAgentSize(llList2Key(SITTERS, script_channel)) != ZERO_VECTOR && CURRENT_ANIMATION_FILENAME != "")
                            {
                                llStopAnimation(CURRENT_ANIMATION_FILENAME);
                            }
                        }
                    }
                    SITTERS = llListReplaceList(SITTERS, [NULL_KEY], i, i);
                }
            }
            if (llGetListLength(AVRPRIMS) > 0)
            {
                helper_mode = FALSE;
            }
            else
            {
                play_anim(first_anim);
                has_helper = FALSE;
            }
        }
        else if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(notecard_name) != notecard_key || get_number_of_scripts() != llGetListLength(SITTERS))
            {
                llResetScript();
            }
        }
    }
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStopAnimation("1a5fe8ac-a804-8a5d-7cbd-56bd83184568");
            if (llGetInventoryType("AVhipfix") == INVENTORY_ANIMATION)
            {
                llStartAnimation("AVhipfix");
            }
            integer new;
            if (llGetPermissionsKey() != avkey)
            {
                new = 2;
            }
            avkey = "";
            llMessageLinked(LINK_SET, 90070, (string)script_channel, llGetPermissionsKey());
            controller = llGetPermissionsKey();
            SITTERS = llListReplaceList(SITTERS, [llGetPermissionsKey()], script_channel, script_channel);
            menu_channel = ((integer)llFrand(2147483646) + 1) * -1;
            menu_handle = llListen(menu_channel, "", llGetPermissionsKey(), "");
            menu_page = 0;
            current_menu = -1;
            llMessageLinked(LINK_SET, 90055, llList2String(MENU_LIST, anim_index), llGetPermissionsKey());
            if (llSubStringIndex(llList2String(MENU_LIST, anim_index), "S:") != 0)
            {
                play_anim(anim_index);
            }
            if (helper_mode || menu_type == 0)
            {
                animation_menu(new);
            }
            if (helper_mode)
            {
                llMessageLinked(LINK_SET, 90040, (string)script_channel + "|" + (string)llGetListLength(SITTERS), "");
            }
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90030)
        {
            if ((integer)msg == script_channel || (integer)((string)id) == script_channel)
            {
                if (llList2Key(SITTERS, script_channel) != NULL_KEY)
                {
                    if (CURRENT_ANIMATION_FILENAME != "")
                    {
                        llStopAnimation(CURRENT_ANIMATION_FILENAME);
                    }
                    if (helper_mode)
                    {
                        llStartAnimation("sit");
                    }
                }
                if ((integer)msg == script_channel && llList2Key(SITTERS, (integer)((string)id)) != NULL_KEY)
                {
                    llRequestPermissions(llList2Key(SITTERS, (integer)((string)id)), PERMISSION_TRIGGER_ANIMATION);
                    avkey = llList2Key(SITTERS, (integer)((string)id));
                }
                else if ((integer)((string)id) == script_channel && llList2Key(SITTERS, (integer)msg) != NULL_KEY)
                {
                    llRequestPermissions(llList2Key(SITTERS, (integer)msg), PERMISSION_TRIGGER_ANIMATION);
                    avkey = llList2Key(SITTERS, (integer)msg);
                }
                llListenRemove(menu_handle);
            }
            SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
            SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)((string)id), (integer)((string)id));
        }
        else if (num == 90001 && id == llList2Key(SITTERS, script_channel))
        {
            llStartAnimation(msg);
        }
        else if (num == 90000 || num == 90055)
        {
            integer x = llListFindList(MENU_LIST, [msg]);
            if (x != -1 && (llSubStringIndex(msg, "S:") == 0 || num == 90000))
            {
                play_anim(x);
            }
            else if (llList2Key(SITTERS, script_channel) == NULL_KEY)
            {
                play_anim(first_anim);
            }
            else if (exit_type && llSubStringIndex(llList2String(MENU_LIST, anim_index), "S:") == 0)
            {
                play_anim(first_anim);
            }
        }
        else if (num == 90070)
        {
            if ((integer)msg != script_channel && sender == llGetLinkNumber())
            {
                SITTERS = llListReplaceList(SITTERS, [id], (integer)msg, (integer)msg);
            }
        }
        else if (num == 90075)
        {
            if ((integer)msg == script_channel)
            {
                if (llGetAgentSize(llList2Key(SITTERS, script_channel)) != ZERO_VECTOR && CURRENT_ANIMATION_FILENAME != "")
                {
                    llStopAnimation(CURRENT_ANIMATION_FILENAME);
                }
                llListenRemove(menu_handle);
            }
            SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
        }
        else if (num == 90085)
        {
            has_helper = TRUE;
        }
        else if (num == 90120)
        {
            helper_mode = TRUE;
            integer involved = FALSE;
            if (llSubStringIndex(llList2String(MENU_LIST, anim_index), "S:") == 0 && id == llList2String(MENU_LIST, anim_index) || (integer)msg == script_channel)
            {
                involved = TRUE;
            }
            llMessageLinked(LINK_SET, 90130, (string)CURRENT_POSITION + (string)CURRENT_ROTATION + (string)involved, (string)script_channel);
        }
        else if (num == 90006 && id == llList2Key(SITTERS, script_channel))
        {
            adjust_menu();
        }
        else if (num == 90005 && id == llList2Key(SITTERS, script_channel))
        {
            if ((float)msg > 2 || menu_type < 2 || menu_type == 3)
            {
                animation_menu(0);
            }
            else
            {
                integer next_anim;
                integer i;
                for (i = anim_index + 1; i < llGetListLength(MENU_LIST); i++)
                {
                    integer x = llListFindList(loops, [i]);
                    if (x == -1)
                    {
                        if (llListFindList(["T:", "M:", "B:"], [llGetSubString(llList2String(MENU_LIST, i), 0, 1)]) == -1)
                        {
                            next_anim = i;
                            jump gg;
                        }
                    }
                    else
                    {
                        next_anim = llList2Integer(loops, x - 1);
                        if (x == 0)
                        {
                            next_anim = first_anim;
                        }
                        jump gg;
                    }
                }
                next_anim = first_anim;
                if (llGetListLength(loops) > 0)
                {
                    next_anim = llList2Integer(loops, -1);
                }
                @gg;
                llMessageLinked(LINK_SET, 90055, llList2String(MENU_LIST, next_anim), id);
                if (llSubStringIndex(llList2String(MENU_LIST, next_anim), "S:") != 0)
                {
                    play_anim(next_anim);
                }
            }
        }
        else if (num == 89999 && id == llList2Key(SITTERS, script_channel))
        {
            controller = (key)msg;
            llListenRemove(menu_handle);
            menu_handle = llListen(menu_channel, "", controller, "");
            animation_menu(0);
        }
        else if ((integer)msg == script_channel)
        {
            if (num == 90110)
            {
                llMessageLinked(LINK_THIS, 90120, (string)script_channel, llList2String(MENU_LIST, anim_index));
            }
            else if (num == 90050)
            {
                llRequestPermissions(id, PERMISSION_TRIGGER_ANIMATION);
            }
            else if (num == 90090)
            {
                list parts = llParseString2List((string)id, ["<"], []);
                POS_LIST = llListReplaceList(POS_LIST, [(vector)("<" + llList2String(parts, 0))], anim_index, anim_index);
                ROT_LIST = llListReplaceList(ROT_LIST, [(vector)("<" + llList2String(parts, 1))], anim_index, anim_index);
            }
            else if (num == 90170 && (integer)msg == script_channel)
            {
                integer place_to_add = current_menu;
                while (place_to_add < llGetListLength(MENU_LIST) && llSubStringIndex(llList2String(MENU_LIST, place_to_add + 1), "M:") != 0)
                {
                    place_to_add++;
                }
                if (llSubStringIndex(llList2String(MENU_LIST, place_to_add + 1), "M:") == 0)
                {
                    place_to_add++;
                }
                list data = llParseStringKeepNulls(id, ["|"], []);
                MENU_LIST = llListInsertList(MENU_LIST, [llList2String(data, 0)], place_to_add);
                DATA_LIST = llListInsertList(DATA_LIST, [llList2String(data, 1)], place_to_add);
                POS_LIST = llListInsertList(POS_LIST, [0], place_to_add);
                ROT_LIST = llListInsertList(ROT_LIST, [0], place_to_add);
                if (llList2String(data, 1) != "")
                {
                    play_anim(place_to_add);
                }
            }
            else if (num == 90020)
            {
                if (!script_channel)
                {
                    if (menu_type)
                    {
                        Readout_Say("MTYPE " + (string)menu_type);
                    }
                    if (exit_type)
                    {
                        Readout_Say("ETYPE " + (string)exit_type);
                    }
                    if (select_type)
                    {
                        Readout_Say("SELECT " + (string)select_type);
                    }
                }
                Readout_Say("");
                Readout_Say("SITTER " + (string)script_channel + "|" + sitter_text);
                integer i;
                for (i = 0; i < llGetListLength(MENU_LIST); i++)
                {
                    list change_me = llParseString2List(llList2String(MENU_LIST, i), [":"], []);
                    if (llListFindList(loops, [i]) != -1)
                    {
                        Readout_Say("LOOP");
                    }
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
                            Readout_Say("BUTTON " + llList2String(change_me, 1) + "|" + llList2String(DATA_LIST, i));
                        }
                        else if (llList2String(change_me, 0) == "S")
                        {
                            Readout_Say("SYNC " + llList2String(change_me, 1) + "|" + llList2String(DATA_LIST, i));
                        }
                    }
                    else
                    {
                        Readout_Say("POSE " + llList2String(change_me, 0) + "|" + llList2String(DATA_LIST, i));
                    }
                }
                for (i = 0; i < llGetListLength(MENU_LIST); i++)
                {
                    if (llList2String(POS_LIST, i) != "0")
                    {
                        string name = llList2String(MENU_LIST, i);
                        list change_me = llParseString2List(name, [":"], []);
                        if (llGetListLength(change_me) == 2)
                        {
                            name = llList2String(change_me, 1);
                        }
                        Readout_Say("{" + name + "}" + llList2String(POS_LIST, i) + llList2String(ROT_LIST, i));
                    }
                }
                llSleep(0.2);
                llMessageLinked(LINK_THIS, 90020, (string)(script_channel + 1), "");
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                play_anim(first_anim);
                if (!script_channel)
                {
                    if (CURRENT_POSITION.x == 0.35)
                        CURRENT_POSITION.x += 0.001;
                    llSitTarget(CURRENT_POSITION - <0,0,0.35>, llEuler2Rot(CURRENT_ROTATION * DEG_TO_RAD));
                }
                else
                {
                    llMessageLinked(LINK_SET, 90180, (string)script_channel, (string)CURRENT_POSITION + "|" + (string)CURRENT_ROTATION);
                }
                llSleep((float)script_channel);
                Owner_Say((string)llGetListLength(MENU_LIST) + " items Ready, Memory: " + (string)llGetFreeMemory());
                variable1 = (llGetFreeMemory() - 2000) / 200;
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseString2List(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                string part0 = llStringTrim(llList2String(parts, 0), STRING_TRIM);
                string part1 = llList2String(parts, 1);
                if (command == "SITTER")
                {
                    reading_notecard_section = FALSE;
                    if ((integer)part0 == script_channel)
                    {
                        reading_notecard_section = TRUE;
                        sitter_text = part1;
                    }
                }
                else if (command == "MTYPE")
                {
                    menu_type = (integer)part0;
                    llPassTouches(FALSE);
                    if (menu_type == 3)
                    {
                        llPassTouches(TRUE);
                    }
                }
                else if (command == "ETYPE")
                {
                    exit_type = (integer)part0;
                }
                else if (command == "SELECT")
                {
                    select_type = (integer)part0;
                }
                else if (reading_notecard_section == TRUE)
                {
                    if (llGetSubString(data, 0, 0) == "{")
                    {
                        command = llStringTrim(llGetSubString(data, 1, llSubStringIndex(data, "}") - 1), STRING_TRIM);
                        integer index = llListFindList(MENU_LIST, [command]);
                        if (index == -1)
                        {
                            index = llListFindList(MENU_LIST, ["S:" + command]);
                        }
                        if (index == -1)
                        {
                            Owner_Say("Error: '" + command + "' not found in menu structure");
                        }
                        else
                        {
                            data = llDumpList2String(llParseString2List(data, [" "], [""]), "");
                            data = llGetSubString(data, llSubStringIndex(data, "}") + 1, -1);
                            parts = llParseStringKeepNulls(data, ["<"], []);
                            POS_LIST = llListReplaceList(POS_LIST, [(vector)("<" + llList2String(parts, 1))], index, index);
                            ROT_LIST = llListReplaceList(ROT_LIST, [(vector)("<" + llList2String(parts, 2))], index, index);
                        }
                    }
                    else
                    {
                        if (llStringLength(part0) > 23)
                        {
                            part0 = llGetSubString(part0, 0, 22);
                        }
                        if (command == "POSE" || command == "SYNC")
                        {
                            if (command == "SYNC")
                            {
                                part0 = "S:" + part0;
                            }
                            if (llListFindList(MENU_LIST, [part0]) == -1)
                            {
                                MENU_LIST += part0;
                                DATA_LIST += part1;
                                POS_LIST += 0;
                                ROT_LIST += 0;
                                if (first_anim == -1)
                                {
                                    first_anim = llGetListLength(MENU_LIST) - 1;
                                }
                            }
                        }
                        else if (command == "MENU")
                        {
                            MENU_LIST += ["M:" + part0 + "*"];
                            DATA_LIST += "";
                            POS_LIST += 0;
                            ROT_LIST += 0;
                        }
                        else if (command == "TOMENU")
                        {
                            MENU_LIST += ["T:" + part0 + "*"];
                            DATA_LIST += "";
                            POS_LIST += 0;
                            ROT_LIST += 0;
                        }
                        else if (command == "BUTTON")
                        {
                            MENU_LIST += ["B:" + part0];
                            DATA_LIST += llList2Integer(parts, 1);
                            POS_LIST += 0;
                            ROT_LIST += 0;
                        }
                        else if (command == "LOO")
                        {
                            loops += llGetListLength(MENU_LIST);
                        }
                    }
                }
                notecard_query = llGetNotecardLine(notecard_name, variable1 += 1);
            }
        }
    }
}
