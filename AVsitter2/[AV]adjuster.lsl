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
 
integer OLD_HELPER_METHOD;
key key_request;
string url = "https://avsitter.com/settings.php"; // the settings dump service remains up for AVsitter customers. settings clear periodically.
string version = "2.2";
string helper_name = "[AV]helper";
string prop_script = "[AV]prop";
string expression_script = "[AV]faces";
string camera_script = "[AV]camera";
string mainscript = "[AV]sitA";
string notecard_name = "AVpos";
list POS_LIST;
list ROT_LIST;
list HELPER_KEY_LIST;
list SITTER_POSES;
list SITTERS;
integer sitter_count;
integer end_count;
integer verbose = 0;
integer chat_channel = 5;
integer helper_mode;
integer comm_channel;
integer listen_handle;
integer active_sitter;
key controller;
integer menu_page;
string adding;
integer adding_item_type;
string last_text;
integer menu_pages;
integer number_per_page = 9;
list chosen_animations;
string cache;
string webkey;
integer webcount;
string FormatFloat(float f, integer num_decimals)
{
    float rounding = (float)(".5e-" + (string)num_decimals) - 5e-07;
    if (f < 0.)
        f -= rounding;
    else
        f += rounding;
    string ret = llGetSubString((string)f, 0, num_decimals - (!num_decimals) - 7);
    if (~llSubStringIndex(ret, "."))
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
    llRegionSayTo(llGetOwner(), 0, "◆" + say);
    llSetObjectName(objectname);
    cache += say + "\n";
    say = "";
    web(FALSE);
}
stop_all_anims(key id)
{
    list animations = llGetAnimationList(id);
    integer i;
    for (i = 0; i < llGetListLength(animations); i++)
    {
        llMessageLinked(LINK_THIS, 90002, llList2String(animations, i), id);
    }
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}
preview_anim(string anim, key id)
{
    if (id)
    {
        stop_all_anims(id);
        llMessageLinked(LINK_THIS, 90001, anim, id);
    }
}
list get_choices()
{
    integer my_number_per_page = number_per_page;
    if (adding == "[SYNC]" && sitter_count > 1)
    {
        my_number_per_page--;
    }
    list options;
    integer i;
    integer start = my_number_per_page * menu_page;
    integer end = start + my_number_per_page;
    if (adding == "[FACE]")
    {
        list facial_anim_list = ["none", "express_afraid_emote", "express_anger_emote", "express_laugh_emote", "express_bored_emote", "express_cry_emote", "express_embarrassed_emote", "express_sad_emote", "express_toothsmile", "express_smile", "express_surprise_emote", "express_worry_emote", "express_repulsed_emote", "express_shrug_emote", "express_wink_emote", "express_disdain", "express_frown", "express_kiss", "express_open_mouth", "express_tongue_out"];
        i = llGetListLength(facial_anim_list);
        options = llList2List(facial_anim_list, start, end - 1);
    }
    else
    {
        integer type = INVENTORY_ANIMATION;
        if (adding == "[PROP]")
        {
            type = INVENTORY_OBJECT;
        }
        i = start;
        while (i < end && i < llGetInventoryNumber(type))
        {
            if (llGetInventoryName(type, i) != helper_name)
            {
                options += llGetInventoryName(type, i);
            }
            i++;
        }
        i = llGetInventoryNumber(type);
    }
    menu_pages = llCeil((float)i / my_number_per_page);
    return options;
}
ask_anim()
{
    choice_menu(get_choices(), "Choose anim" + sitter_text(sitter_count) + ":");
}
choice_menu(list options, string menu_text)
{
    last_text = menu_text;
    menu_text = "\n(Page " + (string)(menu_page + 1) + "/" + (string)menu_pages + ")\n" + menu_text + "\n\n";
    list menu_items;
    integer i;
    if (llGetListLength(options) == 0)
    {
        menu_text = "\nNo items of required type in prim inventory.";
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
        if (adding == "[SYNC]" && sitter_count > 1)
        {
            menu_items += "[DONE]";
        }
        menu_items += ["[BACK]", "[<<]", "[>>]"];
    }
    llDialog(controller, menu_text, order_buttons(menu_items), comm_channel);
}
new_menu()
{
    menu_page = 0;
    list menu_items = ["[BACK]", "[POSE]", "[SYNC]", "[SUBMENU]"];
    if (llList2String(SITTER_POSES, active_sitter) != "")
    {
        menu_items += ["[PROP]", "[FACE]"];
    }
    menu_items += "[CAMERA]";
    string menu_text = "\nWhat would you like to create?\n";
    llDialog(controller, menu_text, order_buttons(menu_items), comm_channel);
}
end_helper_mode()
{
    llRegionSay(comm_channel, "DONEA");
    helper_mode = FALSE;
}
Out(string out)
{
    llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
}
integer get_number_of_scripts()
{
    integer i;
    while (llGetInventoryType(mainscript + " " + (string)(++i)) == INVENTORY_SCRIPT)
        ;
    return i;
}
string convert_to_world_positions(integer num)
{
    list details = llGetObjectDetails(llGetLinkKey(llGetLinkNumber()), [OBJECT_POS, OBJECT_ROT]);
    rotation target_rot = llEuler2Rot(llList2Vector(ROT_LIST, num) * DEG_TO_RAD) * llList2Rot(details, 1);
    vector target_pos = llList2Vector(POS_LIST, num) * llList2Rot(details, 1) + llList2Vector(details, 0);
    return (string)target_pos + "|" + (string)target_rot;
}
string sitter_text(integer sitter)
{
    return " for SITTER " + (string)sitter;
}
remove_script(string reason)
{
    string message = "\n" + llGetScriptName() + " ==Script Removed==\n\n" + reason;
    llDialog(llGetOwner(), message, [], -3675);
    llInstantMessage(llGetOwner(), message);
    llRemoveInventory(llGetScriptName());
}
done_choosing_anims()
{
    string adding_text = llList2String(llParseString2List(adding, ["[", "]"], []), 0);
    adding += "2";
    integer i;
    string text;
    for (i = 0; i < llGetListLength(chosen_animations); i++)
    {
        text += "\nSITTER " + (string)i + ": " + llList2String(chosen_animations, i);
    }
    llTextBox(controller, "\nType a menu name for " + adding_text + text, comm_channel);
}
camera_menu()
{
    string text = "\nCamera:\n\n";
    if (llGetInventoryType(camera_script) == INVENTORY_SCRIPT)
    {
        text += "(using [AV]camera scripts)";
    }
    else
    {
        text += "(prim property)";
    }
    llDialog(controller, text, ["[BACK]", "[SAVE]", "[CLEAR]"], comm_channel);
}
unsit_all()
{
    integer i = llGetNumberOfPrims();
    while (llGetAgentSize(llGetLinkKey(i)))
    {
        stop_all_anims(llGetLinkKey(i));
        llUnSit(llGetLinkKey(i));
        i--;
    }
}
toggle_helper_mode()
{
    helper_mode = (!helper_mode);
    if (helper_mode)
    {
        if (OLD_HELPER_METHOD)
        {
            unsit_all();
        }
        listen_handle = llListen(comm_channel, "", "", "");
        integer i;
        for (i = 0; i < llGetListLength(SITTERS); i++)
        {
            integer param = comm_channel + i * -1;
            if (llGetListLength(SITTERS) == 1)
            {
                param = comm_channel + llGetLinkNumber() * -1;
            }
            vector offset = llList2Vector(POS_LIST, i);
            if (llVecMag(offset) > 10)
            {
                offset = ZERO_VECTOR;
            }
            llRezObject(helper_name, llGetPos() + offset * llGetRot(), ZERO_VECTOR, llEuler2Rot(llList2Vector(ROT_LIST, i) * DEG_TO_RAD) * llGetRot(), param);
        }
    }
    else
    {
        end_helper_mode();
    }
}
default
{
    state_entry()
    {
        if (~llSubStringIndex(llGetScriptName(), " "))
        {
            remove_script("Use only one of this script!");
        }
        llListen(chat_channel, "", llGetOwner(), "");
        comm_channel = ((integer)llFrand(99999) + 1) * 1000 * -1;
        integer i;
        while (i++ < get_number_of_scripts())
        {
            SITTERS += 0;
            POS_LIST += 0;
            ROT_LIST += 0;
            HELPER_KEY_LIST += 0;
            SITTER_POSES += "";
        }
        if (llGetListLength(SITTERS) == 1)
        {
            comm_channel -= 1000000000;
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        integer one = (integer)msg;
        integer two = (integer)((string)id);
        if (sender == llGetLinkNumber())
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            if (num == 90065)
            {
                integer index = llListFindList(SITTERS, [id]);
                if (~index)
                {
                    SITTERS = llListReplaceList(SITTERS, [NULL_KEY], index, index);
                }
            }
            else if (num == 90030)
            {
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)((string)id), (integer)((string)id));
                if (OLD_HELPER_METHOD && helper_mode)
                {
                    integer i = llList2Integer(HELPER_KEY_LIST, (integer)msg);
                    HELPER_KEY_LIST = llListReplaceList(HELPER_KEY_LIST, [llList2Integer(HELPER_KEY_LIST, (integer)((string)id))], (integer)msg, (integer)msg);
                    HELPER_KEY_LIST = llListReplaceList(HELPER_KEY_LIST, [i], (integer)((string)id), (integer)((string)id));
                    llRegionSay(comm_channel, "SWAP|" + (string)msg + "|" + (string)id);
                }
            }
            else if (num == 90070)
            {
                SITTERS = llListReplaceList(SITTERS, [id], (integer)msg, (integer)msg);
            }
            else if (num == 90021)
            {
                integer script_channel = (integer)msg;
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
                if (llGetInventoryType(mainscript + " " + (string)(script_channel + 1)) == INVENTORY_SCRIPT)
                {
                    llMessageLinked(LINK_THIS, 90020, (string)(script_channel + 1), "");
                }
                else
                {
                    Readout_Say("");
                    Readout_Say("--✄--COPY ABOVE INTO \"AVpos\" NOTECARD--✄--");
                    Readout_Say("");
                    web(TRUE);
                    llRegionSayTo(llGetOwner(), 0, "Settings copy: " + url + "?q=" + webkey);
                }
            }
            else if (num == 90022)
            {
                if (llGetSubString(msg, 0, 3) == "S:M:" || llGetSubString(msg, 0, 3) == "S:T:")
                {
                    msg = strReplace(msg, "*|", "|");
                }
                if (llGetSubString(msg, 0, 1) == "V:")
                {
                    if (!(integer)((string)id))
                    {
                        webkey = (string)llGenerateKey();
                        webcount = 0;
                        Readout_Say("");
                        Readout_Say("--✄--COPY BELOW INTO \"AVpos\" NOTECARD--✄--");
                        Readout_Say("");
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
                        if (llList2String(data, 6))
                        {
                            Readout_Say("TEXT " + strReplace(llList2String(data, 6), "\n", "\\n"));
                        }
                        if (llList2String(data, 7))
                        {
                            Readout_Say("ADJUST " + strReplace(llList2String(data, 7), "�", "|"));
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
                    if (llGetListLength(SITTERS) > 1 || llList2String(data, 5) != "")
                    {
                        string SITTER_TEXT;
                        if (llList2String(data, 5))
                        {
                            SITTER_TEXT = "|" + strReplace(llList2String(data, 5), "�", "|");
                        }
                        Readout_Say("SITTER " + (string)id + SITTER_TEXT);
                        Readout_Say("");
                    }
                    return;
                }
                else if (llGetSubString(msg, 0, 0) == "{")
                {
                    msg = strReplace(msg, "{P:", "{");
                    list parts = llParseStringKeepNulls(llDumpList2String(llParseString2List(llGetSubString(msg, llSubStringIndex(msg, "}") + 1, -1), [" "], [""]), ""), ["<"], []);
                    string pos = "<" + llList2String(parts, 1);
                    string rot = "<" + llList2String(parts, 2);
                    vector pos2 = (vector)pos;
                    vector rot2 = (vector)rot;
                    string result = "<" + FormatFloat(pos2.x, 3) + "," + FormatFloat(pos2.y, 3) + "," + FormatFloat(pos2.z, 3) + ">";
                    result += "<" + FormatFloat(rot2.x, 1) + "," + FormatFloat(rot2.y, 1) + "," + FormatFloat(rot2.z, 1) + ">";
                    msg = llGetSubString(msg, 0, llSubStringIndex(msg, "}")) + result;
                }
                else if (llGetSubString(msg, 1, 1) == ":")
                {
                    msg = strReplace(msg, "S:P:", "POSE ");
                    msg = strReplace(msg, "S:M:", "MENU ");
                    msg = strReplace(msg, "S:T:", "TOMENU ");
                    if (llGetSubString(msg, -6, -1) == "|90210")
                    {
                        msg = strReplace(msg, "S:B:", "SEQUENCE ");
                        msg = strReplace(msg, "|90210", "");
                    }
                    else
                    {
                        msg = strReplace(msg, "S:B:", "BUTTON ");
                        if (!~llSubStringIndex(msg, "�"))
                        {
                            msg = strReplace(msg, "|90200", "");
                        }
                    }
                    msg = strReplace(msg, "S:", "SYNC ");
                    msg = strReplace(msg, "�", "|");
                }
                if (llGetSubString(msg, -1, -1) == "*")
                {
                    msg = llGetSubString(msg, 0, -2);
                }
                if (llGetSubString(msg, -1, -1) == "|")
                {
                    msg = llGetSubString(msg, 0, -2);
                }
                if (llGetSubString(msg, 0, 3) == "MENU")
                {
                    Readout_Say("");
                }
                Readout_Say(msg);
            }
            else if (num == 90100 || num == 90101)
            {
                if (llList2String(data, 1) == "[DUMP]")
                {
                    if (id != llGetOwner())
                    {
                        llRegionSayTo(id, 0, "Dumping settings to Owner");
                    }
                    llMessageLinked(LINK_THIS, 90020, "0", "");
                }
                else if (llList2String(data, 1) == "[NEW]")
                {
                    controller = (key)llList2String(data, 2);
                    active_sitter = (integer)llList2String(data, 0);
                    adding = "";
                    new_menu();
                }
                else if (llList2String(data, 1) == "[SAVE]")
                {
                    integer i;
                    for (i = 0; i < llGetListLength(SITTERS); i++)
                    {
                        if (llList2String(SITTER_POSES, i))
                        {
                            string type = "SYNC";
                            string temp_pose_name = llList2String(SITTER_POSES, i);
                            if (!llSubStringIndex(llList2String(SITTER_POSES, i), "P:"))
                            {
                                type = "POSE";
                                temp_pose_name = llGetSubString(temp_pose_name, 2, -1);
                            }
                            llMessageLinked(LINK_THIS, 90301, (string)i, llList2String(SITTER_POSES, i) + "|" + llList2String(POS_LIST, i) + "|" + llList2String(ROT_LIST, i) + "|");
                            vector pos = llList2Vector(POS_LIST, i);
                            vector rot = llList2Vector(ROT_LIST, i);
                            llSay(0, type + " Saved to memory " + sitter_text(i) + ": {" + temp_pose_name + "}" + llList2String(POS_LIST, i) + llList2String(ROT_LIST, i));
                        }
                    }
                    llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([llList2String(data, 2), id], "|"));
                }
                else if (llList2String(data, 1) == "[HELPER]")
                {
                    controller = id;
                    OLD_HELPER_METHOD = (integer)llList2String(data, 3);
                    toggle_helper_mode();
                }
                else if (llList2String(data, 1) == "[ADJUST]")
                {
                    end_helper_mode();
                }
            }
            else if (num == 90055 || num == 90056)
            {
                data = llParseStringKeepNulls(id, ["|"], []);
                SITTER_POSES = llListReplaceList(SITTER_POSES, [llList2String(data, 0)], one, one);
                POS_LIST = llListReplaceList(POS_LIST, [(vector)llList2String(data, 2)], one, one);
                ROT_LIST = llListReplaceList(ROT_LIST, [(vector)llList2String(data, 3)], one, one);
                if (helper_mode)
                {
                    llRegionSay(comm_channel, "POS|" + (string)one + "|" + convert_to_world_positions(one) + "|" + (string)OLD_HELPER_METHOD + "|" + llList2String(SITTERS, one));
                }
            }
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (OLD_HELPER_METHOD)
            {
                if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())))
                {
                    end_helper_mode();
                }
            }
            else if (llGetListLength(SITTERS) == 1 && llAvatarOnSitTarget() == NULL_KEY || llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
            {
                end_helper_mode();
            }
        }
        if (change & CHANGED_INVENTORY)
        {
            unsit_all();
            end_helper_mode();
            llResetScript();
        }
    }
    run_time_permissions(integer perm)
    {
        if (llGetPermissions() & PERMISSION_TRACK_CAMERA)
        {
            llPlaySound("3d09f582-3851-c0e0-f5ba-277ac5c73fb4", 1.);
            vector eye = (llGetCameraPos() - llGetPos()) / llGetRot();
            vector at = eye + llRot2Fwd(llGetCameraRot() / llGetRot());
            if (llGetInventoryType(camera_script) == INVENTORY_SCRIPT)
            {
                llMessageLinked(LINK_THIS, 90174, (string)active_sitter, (string)eye + "|" + (string)at);
            }
            else
            {
                llMessageLinked(LINK_THIS, 90011, (string)eye, (string)at);
                llSay(0, "Camera property saved for all sitters in prim (takes effect next sit).");
            }
            camera_menu();
        }
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (chan == chat_channel)
        {
            if (msg == "cleanup")
            {
                llRegionSay(comm_channel, "DONEA");
                Out("Cleaning \"" + llGetScriptName() + "\" and \"" + helper_name + "\" from prim " + (string)llGetLinkNumber());
                if (llGetInventoryType(helper_name) == INVENTORY_OBJECT)
                {
                    llRemoveInventory(helper_name);
                }
                llRemoveInventory(llGetScriptName());
            }
            else if (msg == "targets")
            {
                llMessageLinked(LINK_THIS, 90298, "", "");
            }
            else if (msg == "helper")
            {
                if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) != ZERO_VECTOR)
                {
                    llMessageLinked(LINK_SET, 90100, "0|[HELPER]||" + (string)OLD_HELPER_METHOD, llList2Key(SITTERS, 0));
                }
            }
        }
        else if (id == controller)
        {
            if (msg == "[>>]")
            {
                menu_page++;
                if (menu_page >= menu_pages)
                {
                    menu_page = 0;
                }
                choice_menu(get_choices(), last_text);
            }
            else if (msg == "[<<]")
            {
                menu_page--;
                if (menu_page < 0)
                {
                    menu_page = menu_pages - 1;
                }
                choice_menu(get_choices(), last_text);
            }
            else if (msg == "[BACK]")
            {
                llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([controller, llList2String(SITTERS, active_sitter)], "|"));
            }
            else if (msg == "[POSE]" || msg == "[SYNC]")
            {
                adding = msg;
                chosen_animations = [];
                sitter_count = active_sitter;
                end_count = sitter_count;
                if (msg == "[SYNC]")
                {
                    sitter_count = 0;
                    end_count = llGetListLength(SITTERS) - 1;
                }
                ask_anim();
            }
            else if (msg == "[SUBMENU]")
            {
                adding = msg;
                llTextBox(controller, "\n\nName your submenu:", comm_channel);
            }
            else if (msg == "[PROP]")
            {
                if (llGetInventoryType(prop_script) == INVENTORY_SCRIPT)
                {
                    adding = msg;
                    choice_menu(get_choices(), "Choose your prop:");
                }
                else
                {
                    llSay(0, "For this you need the " + prop_script + " plugin script.");
                    llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([controller, llList2String(SITTERS, active_sitter)], "|"));
                }
            }
            else if (msg == "[FACE]")
            {
                if (llGetInventoryType(expression_script) == INVENTORY_SCRIPT)
                {
                    adding = msg;
                    choice_menu(get_choices(), "Choose your facial anim:");
                }
                else
                {
                    llSay(0, "For this you need the " + expression_script + " plugin script.");
                    llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([controller, llList2String(SITTERS, active_sitter)], "|"));
                }
            }
            else if (msg == "[CAMERA]")
            {
                camera_menu();
            }
            else if (msg == "[CLEAR]")
            {
                integer i;
                for (i = 0; i < llGetNumberOfPrims(); i++)
                {
                    llSetLinkCamera(i, ZERO_VECTOR, ZERO_VECTOR);
                }
                if (llGetInventoryType(camera_script) == INVENTORY_SCRIPT)
                {
                    llMessageLinked(LINK_THIS, 90174, (string)active_sitter, "none");
                }
                else
                {
                    llSay(0, "Camera property cleared from all prims (takes effect next sit).");
                }
                camera_menu();
            }
            else if (msg == "[SAVE]")
            {
                llRequestPermissions(id, PERMISSION_TRACK_CAMERA);
            }
            else if ((~llListFindList(["[DONE]", "1", "2", "3", "4", "5", "6", "7", "8", "9"], [msg])) && (~llListFindList(["[POSE]", "[SYNC]", "[SYNC]2", "[PROP]", "[FACE]"], [adding])))
            {
                string choice = llList2String(get_choices(), (integer)msg - 1);
                if (adding == "[PROP]")
                {
                    integer perms = llGetInventoryPermMask(choice, MASK_NEXT);
                    if (!(perms & PERM_COPY))
                    {
                        llSay(0, "Could not add prop '" + choice + "'. Props and their content must be COPY-OK for NEXT owner.");
                    }
                    else
                    {
                        llMessageLinked(LINK_THIS, 90171, (string)active_sitter, choice);
                    }
                    llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([controller, llList2String(SITTERS, active_sitter)], "|"));
                }
                else if (adding == "[FACE]")
                {
                    llMessageLinked(LINK_THIS, 90172, (string)active_sitter, choice);
                    llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([controller, llList2String(SITTERS, active_sitter)], "|"));
                }
                else if (msg == "[DONE]")
                {
                    done_choosing_anims();
                }
                else if (adding == "[SYNC]" || adding == "[POSE]")
                {
                    chosen_animations += choice;
                    preview_anim(choice, llList2Key(SITTERS, sitter_count));
                    sitter_count++;
                    if (sitter_count > end_count)
                    {
                        done_choosing_anims();
                    }
                    else
                    {
                        ask_anim();
                    }
                }
            }
            else
            {
                msg = strReplace(msg, "\n", "");
                msg = strReplace(msg, "|", "");
                msg = llGetSubString(msg, 0, 22);
                if (msg == "")
                {
                    llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([controller, llList2String(SITTERS, active_sitter)], "|"));
                }
                else if (adding == "[SUBMENU]")
                {
                    llMessageLinked(LINK_THIS, 90300, (string)active_sitter, "T:" + msg + "*" + "||");
                    llMessageLinked(LINK_THIS, 90300, (string)active_sitter, "M:" + msg + "*" + "||");
                    llSay(0, "MENU Added: '" + msg + "'" + sitter_text(active_sitter));
                    llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([controller, llList2String(SITTERS, active_sitter)], "|"));
                }
                else if (adding == "[POSE]2" || adding == "[SYNC]2")
                {
                    integer start = 0;
                    integer end = llGetListLength(chosen_animations);
                    string type = "SYNC";
                    string prefix;
                    if (adding == "[POSE]2")
                    {
                        prefix = "P:";
                        type = "POSE";
                        start = active_sitter;
                        end = active_sitter + 1;
                    }
                    integer x;
                    integer i;
                    for (i = start; i < end; i++)
                    {
                        llSay(0, type + " Added: '" + msg + "' using anim '" + llList2String(chosen_animations, x) + "' to SITTER " + (string)i);
                        llMessageLinked(LINK_THIS, 90300, (string)i, prefix + msg + "|" + llList2String(chosen_animations, x) + "|" + llList2String(POS_LIST, i) + "|" + llList2String(ROT_LIST, i));
                        x++;
                    }
                }
                if (msg != "" && (adding == "[POSE]2" || adding == "[SYNC]2"))
                {
                    llMessageLinked(LINK_THIS, 90005, "", llDumpList2String([controller, llList2String(SITTERS, active_sitter)], "|"));
                }
            }
        }
        else if (llGetOwnerKey(id) == llGetOwner())
        {
            list data = llParseString2List(msg, ["|"], []);
            integer num = (integer)llList2String(data, 1);
            if (llList2String(data, 0) == "REG")
            {
                HELPER_KEY_LIST = llListReplaceList(HELPER_KEY_LIST, [id], num, num);
                llRegionSay(comm_channel, "POS|" + (string)num + "|" + convert_to_world_positions(num) + "|" + (string)OLD_HELPER_METHOD + "|" + llList2String(SITTERS, num));
            }
            else if (llList2String(data, 0) == "MENU")
            {
                if (llList2String(data, 1) == controller)
                {
                    llMessageLinked(LINK_SET, 90005, "", llDumpList2String([controller, llList2String(SITTERS, num)], "|"));
                }
            }
            else if (llList2String(data, 0) == "MOVED")
            {
                list myprim = llGetObjectDetails(llGetLinkKey(llGetLinkNumber()), [OBJECT_POS, OBJECT_ROT]);
                rotation f = llList2Rot(myprim, 1);
                vector target_rot = llRot2Euler((rotation)llList2String(data, 3) / f) * RAD_TO_DEG;
                vector target_pos = ((vector)llList2String(data, 2) - llList2Vector(myprim, 0)) / f;
                if ((string)target_pos != (string)llList2Vector(POS_LIST, num) || (string)target_rot != (string)llList2Vector(ROT_LIST, num))
                {
                    POS_LIST = llListReplaceList(POS_LIST, [target_pos], num, num);
                    ROT_LIST = llListReplaceList(ROT_LIST, [target_rot], num, num);
                    llMessageLinked(LINK_THIS, 90057, (string)num, (string)target_pos + "|" + (string)target_rot);
                }
            }
            else if (OLD_HELPER_METHOD)
            {
                integer sitter = (integer)llGetSubString(name, llSubStringIndex(name, " ") + 1, -1);
                if (llList2String(data, 0) == "ANIMA")
                {
                    llMessageLinked(LINK_THIS, 90075, (string)sitter, llList2Key(data, 1));
                }
                else if (llList2String(data, 0) == "GETUP")
                {
                    llMessageLinked(LINK_THIS, 90076, (string)sitter, llList2Key(data, 1));
                }
            }
        }
    }
    on_rez(integer x)
    {
        llResetScript();
    }
}
