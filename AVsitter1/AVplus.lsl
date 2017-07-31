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
 
string product_and_version = "AVsitter™ AVplus 1.4";
list facial_anim_list = ["express_afraid_emote", "express_anger_emote", "express_laugh_emote", "express_bored_emote", "express_cry_emote", "express_embarrassed_emote", "express_sad_emote", "express_toothsmile", "express_smile", "express_surprise_emote", "express_worry_emote", "express_repulsed_emote", "express_shrug_emote", "express_wink_emote", "express_disdain", "express_frown", "express_kiss", "express_open_mouth", "express_tongue_out"];
integer IsInteger(string data)
{
    return llParseString2List((string)llParseString2List(data, ["8", "9"], []), ["0", "1", "2", "3", "4", "5", "6", "7"], []) == [] && data != "";
}
list SITTERS;
integer sticky_rez;
integer expressions_toggle_off;
vector camera_position;
vector camera_focus;
integer script_channel;
key playing_sound_for;
key playing_prop_for;
string anim_name;
string pose_name;
string raw_pose_name;
integer page;
integer pages;
integer loop;
float volume = 1;
string sound;
string notecard_name = "AVpos";
string script_basename = "AVplus";
string mainscript_basename = "AVsit";
list prop_triggers;
list props;
list sound_triggers;
list sounds;
list item_triggers;
list items;
list anim_triggers;
list anims;
integer comm_channel;
integer menu_channel;
integer comm_listen_handle;
integer menu_listen_handle;
string menu_type;
key notecard_key;
key notecard_query;
integer notecard_line;
list running_sequences_keys;
list running_sequences_trigger_index;
list running_sequences_pointers;
Owner_Say(string say)
{
    llOwnerSay(llGetScriptName() + ":" + say);
}
Readout_Say(string say)
{
    llOwnerSay("◆" + say);
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
check_sitters()
{
    integer i;
    for (i = 0; i < llGetListLength(SITTERS); i++)
    {
        if (llList2Key(SITTERS, i) != NULL_KEY)
        {
            jump skip;
        }
    }
    remove_props();
    running_sequences_keys = [];
    running_sequences_trigger_index = [];
    running_sequences_pointers = [];
    pose_name = "";
    @skip;
}
integer get_number_of_scripts(string basename)
{
    integer i = 1;
    while (llGetInventoryType(basename + " " + (string)i) == INVENTORY_SCRIPT)
    {
        i++;
    }
    return i;
}
remove_props()
{
    llRegionSay(comm_channel, "REMPROPS");
}
rez_prop(integer index)
{
    list data = llParseStringKeepNulls(llList2String(props, index), ["|"], []);
    string object = llList2String(data, 0);
    vector pos = (vector)llList2String(data, 1);
    rotation rot = llEuler2Rot((vector)llList2String(data, 2));
    rot = llEuler2Rot((vector)llList2String(data, 2) * DEG_TO_RAD) * llGetRot();
    pos = (vector)llList2String(data, 1) * llGetRot() + llGetPos();
    llRezAtRoot(object, pos, ZERO_VECTOR, rot, comm_channel);
}
play_sound(integer index)
{
    list data = llParseStringKeepNulls(llList2String(sounds, index), ["|"], []);
    string sound = llList2String(data, 0);
    integer loop = (integer)llList2String(data, 1);
    float volume = (float)llList2String(data, 2);
    if (loop)
    {
        llLoopSound(sound, volume);
    }
    else
    {
        llPlaySound(sound, volume);
    }
}
give_item(integer index, string anim_name, key id)
{
    list data = llParseStringKeepNulls(llList2String(items, index), ["|"], []);
    string item = llList2String(data, 0);
    string anim = llList2String(data, 1);
    if (anim == "" || anim == anim_name)
    {
        llSleep(1);
        llGiveInventory(id, item);
    }
}
start_sequence(integer index, string anim_name, key id)
{
    list data = llParseStringKeepNulls(llList2String(anims, index), ["|"], []);
    string anim = llList2String(data, 1);
    if (anim == "" || anim == anim_name)
    {
        integer index2 = llListFindList(running_sequences_trigger_index, [index]);
        if (index2 != -1)
        {
            if (llList2Key(running_sequences_keys, index2) == id)
            {
                running_sequences_keys = llListReplaceList(running_sequences_keys, [], index2, index2);
                running_sequences_trigger_index = llListReplaceList(running_sequences_trigger_index, [], index2, index2);
                running_sequences_pointers = llListReplaceList(running_sequences_pointers, [], index2, index2);
            }
        }
        running_sequences_keys += id;
        running_sequences_trigger_index += index;
        running_sequences_pointers += 0;
    }
    if (llGetListLength(running_sequences_keys) > 0)
    {
        llSetTimerEvent(0.01);
    }
}
sequence()
{
    list seq_anims;
    list seq_ids;
    integer i;
    while (i < llGetListLength(running_sequences_pointers))
    {
        integer anim_index = llList2Integer(running_sequences_trigger_index, i);
        integer sequence_pointer = llList2Integer(running_sequences_pointers, i);
        list data = llParseStringKeepNulls(llList2String(anims, anim_index), ["|"], []);
        list sequence = llParseStringKeepNulls(llList2String(data, 0), [":"], []);
        list sequence_animations = llList2ListStrided(sequence, 0, -1, 2);
        list sequence_times = llList2ListStrided(llDeleteSubList(sequence, 0, 0), 0, -1, 2);
        integer sequence_length;
        integer j;
        while (j <= llGetListLength(sequence_times))
        {
            if (sequence_length == sequence_pointer)
            {
                string anim = llList2String(sequence_animations, j);
                if (IsInteger(anim))
                {
                    anim = llList2String(facial_anim_list, (integer)anim);
                }
                seq_anims += anim;
                seq_ids += llList2Key(running_sequences_keys, i);
            }
            if (llList2String(sequence_times, j) == "-")
            {
                sequence_pointer++;
                jump go;
            }
            sequence_length += (integer)llList2String(sequence_times, j);
            j++;
        }
        sequence_pointer++;
        if (sequence_pointer == sequence_length)
        {
            sequence_pointer = 0;
        }
        @go;
        running_sequences_pointers = llListReplaceList(running_sequences_pointers, [sequence_pointer], i, i);
        i++;
    }
    if (!expressions_toggle_off)
    {
        for (i = 0; i < llGetListLength(seq_anims); i++)
        {
            llMessageLinked(LINK_SET, 90001, llList2String(seq_anims, i), llList2Key(seq_ids, i));
        }
    }
}
remove_sequences(key id)
{
    integer index;
    while (llListFindList(running_sequences_keys, [id]) != -1)
    {
        index = llListFindList(running_sequences_keys, [id]);
        running_sequences_keys = llDeleteSubList(running_sequences_keys, index, index);
        running_sequences_trigger_index = llDeleteSubList(running_sequences_trigger_index, index, index);
        running_sequences_pointers = llDeleteSubList(running_sequences_pointers, index, index);
    }
    if (llGetListLength(running_sequences_keys) == 0)
    {
        llSetTimerEvent(0);
    }
}
main_menu()
{
    page = 0;
    string text = "N/A";
    if (camera_position != ZERO_VECTOR)
    {
        text = "YES";
    }
    string menu_text = "\n" + product_and_version + "\nEXTRAS for Pose:" + pose_name + "\n\nCamera:" + text + "\nProp:";
    integer i;
    text = "N/A";
    for (i = 0; i < llGetListLength(prop_triggers); i++)
    {
        if (llList2String(prop_triggers, i) == pose_name)
        {
            text = llList2String(llParseStringKeepNulls(llList2String(props, i), ["|"], []), 0);
        }
    }
    menu_text += text + "\nSound:";
    text = "N/A";
    for (i = 0; i < llGetListLength(sound_triggers); i++)
    {
        if (llList2String(sound_triggers, i) == pose_name)
        {
            text = llList2String(llParseStringKeepNulls(llList2String(sounds, i), ["|"], []), 0);
        }
    }
    menu_text += text + "\nItem:";
    text = "N/A";
    for (i = 0; i < llGetListLength(item_triggers); i++)
    {
        if (llList2String(item_triggers, i) == pose_name)
        {
            text = llList2String(llParseStringKeepNulls(llList2String(items, i), ["|"], []), 0);
        }
    }
    menu_text += text + "\nFace:";
    text = "N/A";
    for (i = 0; i < llGetListLength(anim_triggers); i++)
    {
        if (llList2String(anim_triggers, i) == pose_name)
        {
            text = llList2String(llParseStringKeepNulls(llList2String(anims, i), ["|", ":"], []), 0);
        }
    }
    menu_text += text + "\n";
    list menu_items = ["[TOP]", "[CAMERA]", "[PROPS]", "[SOUNDS]", "[ITEMS]", "[FACES]"];
    llDialog(llGetOwner(), menu_text, order_buttons(menu_items), menu_channel);
}
choice_menu(list options)
{
    string menu_text = "\nPlease choose your item:\n\n";
    list menu_items;
    integer i;
    if (llGetListLength(options) == 0)
    {
        menu_text = "\nNo items of that type in the prim inventory.";
        menu_items = ["[BACK]"];
    }
    else
    {
        for (i = 0; i < llGetListLength(options); i++)
        {
            menu_items += (string)(i + 1);
            menu_text += (string)(i + 1) + "." + llList2String(options, i) + "\n";
        }
        while (llGetListLength(menu_items) < 8)
        {
            menu_items += "~";
        }
        menu_items += ["[CLEAR]", "[BACK]", "[PAGE-]", "[PAGE+]"];
    }
    llDialog(llGetOwner(), menu_text, order_buttons(menu_items), menu_channel);
}
list facial_anims(integer newpage)
{
    page = newpage;
    pages = llGetListLength(facial_anim_list) / 8;
    integer start = 8 * page;
    return llList2List(facial_anim_list, start, start + 8 - 1);
}
list get_contents(integer type, integer newpage)
{
    page = newpage;
    list contents;
    integer i;
    integer start = 8 * page;
    integer end = start + 8;
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
    pages = i / 8;
    return contents;
}
menu_determine(string mtype)
{
    if (mtype == "[PROPS]")
    {
        choice_menu(get_contents(INVENTORY_OBJECT, page));
    }
    else if (mtype == "[SOUNDS]")
    {
        choice_menu(get_contents(INVENTORY_SOUND, page));
    }
    else if (mtype == "[FACES]")
    {
        choice_menu(facial_anims(page));
    }
    else if (mtype == "[ITEMS]")
    {
        choice_menu(get_contents(INVENTORY_OBJECT, page));
    }
    else if (mtype == "[CAMERA]")
    {
        if (llGetPermissionsKey() == llGetOwner() && llGetPermissions() & PERMISSION_TRACK_CAMERA)
        {
            camera_menu();
        }
        else
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
        }
    }
    menu_type = mtype;
}
camera_menu()
{
    list menu_items = ["[BACK]", "[SET]", "[RELEASE]"];
    llDialog(llGetOwner(), "\nChoose a camera angle and click [SET], or use [RELEASE] to clear it.", order_buttons(menu_items), menu_channel);
}
sound_menu()
{
    llPlaySound("ed124764-705d-d497-167a-182cd9fa2e6c", 0);
    if (loop)
    {
        llLoopSound(sound, volume);
    }
    else
    {
        llPlaySound(sound, volume);
    }
    playing_sound_for = llGetOwner();
    list menu_items = ["[SOUNDS]", "~"];
    if (loop)
    {
        menu_items += ["[NO LOOP]"];
    }
    else
    {
        menu_items += ["[LOOP]"];
    }
    menu_items += ["[VOLUME-]", "[VOLUME+]", "[OK]"];
    llDialog(llGetOwner(), "\nConfigure your sound:\n\nSound:" + sound + "\nVolume:" + (string)((integer)(volume / 1 * 100)) + "%", order_buttons(menu_items), menu_channel);
}
default
{
    timer()
    {
        sequence();
        llSetTimerEvent(1);
    }
    state_entry()
    {
        script_channel = (integer)llGetSubString(llGetScriptName(), llSubStringIndex(llGetScriptName(), " "), -1);
        if (script_channel != 0)
        {
            state nothing;
        }
        integer i;
        for (i = 0; i < get_number_of_scripts(mainscript_basename); i++)
        {
            SITTERS += NULL_KEY;
        }
        llPlaySound("ed124764-705d-d497-167a-182cd9fa2e6c", 0);
        comm_channel = ((integer)llFrand(2147483646) + 1) * -1;
        menu_channel = ((integer)llFrand(2147483646) + 1) * -1;
        comm_listen_handle = llListen(comm_channel, "", "", "SAVEPROP");
        menu_listen_handle = llListen(menu_channel, "", llGetOwner(), "");
        llListenControl(comm_listen_handle, FALSE);
        llListenControl(menu_listen_handle, FALSE);
        notecard_key = llGetInventoryKey(notecard_name);
        if (llGetInventoryType(notecard_name) == INVENTORY_NOTECARD)
        {
            Owner_Say("Reading " + notecard_name);
            notecard_query = llGetNotecardLine(notecard_name, 0);
        }
    }
    on_rez(integer start)
    {
        comm_channel = ((integer)llFrand(2147483646) + 1) * -1;
        menu_channel = ((integer)llFrand(2147483646) + 1) * -1;
    }
    listen(integer channel, string name, key id, string message)
    {
        if (channel == menu_channel)
        {
            if (id == llGetOwner())
            {
                if (message == "[TOP]")
                {
                    llMessageLinked(LINK_SET, 90005, "", id);
                }
                else if (message == "[CLEAR]")
                {
                    if (menu_type == "[PROPS]")
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(prop_triggers); i++)
                        {
                            if (llList2String(prop_triggers, i) == pose_name)
                            {
                                prop_triggers = llDeleteSubList(prop_triggers, i, i);
                                props = llDeleteSubList(props, i, i);
                            }
                        }
                    }
                    else if (menu_type == "[SOUNDS]")
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(sound_triggers); i++)
                        {
                            if (llList2String(sound_triggers, i) == pose_name)
                            {
                                sound_triggers = llDeleteSubList(sound_triggers, i, i);
                                sounds = llDeleteSubList(sounds, i, i);
                                llPlaySound("ed124764-705d-d497-167a-182cd9fa2e6c", 0);
                            }
                        }
                    }
                    else if (menu_type == "[ITEMS]")
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(item_triggers); i++)
                        {
                            if (llList2String(item_triggers, i) == pose_name)
                            {
                                item_triggers = llDeleteSubList(item_triggers, i, i);
                                items = llDeleteSubList(items, i, i);
                            }
                        }
                    }
                    else if (menu_type == "[FACES]")
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(anim_triggers); i++)
                        {
                            if (llList2String(anim_triggers, i) == pose_name)
                            {
                                anim_triggers = llDeleteSubList(anim_triggers, i, i);
                                anims = llDeleteSubList(anims, i, i);
                                remove_sequences(llGetOwner());
                            }
                        }
                    }
                    main_menu();
                }
                else if (message == "[BACK]")
                {
                    main_menu();
                }
                else if (message == "[PAGE+]" || message == "[PAGE-]")
                {
                    if (message == "[PAGE-]")
                    {
                        page--;
                        if (page < 0)
                        {
                            page = pages;
                        }
                    }
                    else
                    {
                        page++;
                        if (page > pages)
                        {
                            page = 0;
                        }
                    }
                    menu_determine(menu_type);
                }
                else if (message == "[SET]")
                {
                    if (llGetPermissions() & PERMISSION_TRACK_CAMERA)
                    {
                        llPlaySound("3d09f582-3851-c0e0-f5ba-277ac5c73fb4", 1.);
                        list details = [OBJECT_POS, OBJECT_ROT];
                        rotation f = llList2Rot(details = llGetObjectDetails(llGetKey(), details) + llGetCameraPos() + llGetCameraRot(), 1);
                        rotation camera_rotation = llList2Rot(details, 3) / f;
                        camera_position = (llList2Vector(details, 2) - llList2Vector(details, 0)) / f;
                        camera_focus = camera_position + 1 * llRot2Fwd(camera_rotation);
                        main_menu();
                    }
                }
                else if (message == "[RELEASE]")
                {
                    camera_position = ZERO_VECTOR;
                    main_menu();
                }
                else if (message == "[VOLUME+]" || message == "[VOLUME-]")
                {
                    if (message == "[VOLUME-]")
                    {
                        volume -= 0.2;
                    }
                    else
                    {
                        volume += 0.2;
                    }
                    if (volume < 0)
                    {
                        volume = 0;
                    }
                    else if (volume > 1)
                    {
                        volume = 1;
                    }
                    sound_menu();
                }
                else if (message == "[OK]")
                {
                    integer i;
                    for (i = 0; i < llGetListLength(sound_triggers); i++)
                    {
                        if (llList2String(sound_triggers, i) == pose_name)
                        {
                            sound_triggers = llDeleteSubList(sound_triggers, i, i);
                            sounds = llDeleteSubList(sounds, i, i);
                        }
                    }
                    sound_triggers += pose_name;
                    sounds += sound + "|" + (string)loop + "|1";
                    main_menu();
                }
                else if (message == "[LOOP]" || message == "[NO LOOP]")
                {
                    loop = 0;
                    if (message == "[LOOP]")
                    {
                        loop = 1;
                    }
                    sound_menu();
                }
                else if (llListFindList(["1", "2", "3", "4", "5", "6", "7", "8", "9"], [message]) != -1)
                {
                    if (menu_type == "[PROPS]")
                    {
                        remove_props();
                        string object = llList2String(get_contents(INVENTORY_OBJECT, page), (integer)message - 1);
                        llRezObject(object, llGetPos() + <0,0,2>, ZERO_VECTOR, llGetRootRotation(), comm_channel);
                        playing_prop_for = id;
                        llSay(0, "Please position your prop and click [SAVE] when done.");
                        llMessageLinked(LINK_SET, 90005, "", id);
                    }
                    else if (menu_type == "[SOUNDS]")
                    {
                        sound = llList2String(get_contents(INVENTORY_SOUND, page), (integer)message - 1);
                        sound_menu();
                    }
                    else if (menu_type == "[FACES]")
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(anim_triggers); i++)
                        {
                            if (llList2String(anim_triggers, i) == pose_name)
                            {
                                anim_triggers = llDeleteSubList(anim_triggers, i, i);
                                anims = llDeleteSubList(anims, i, i);
                            }
                        }
                        string anim = llList2String(facial_anims(page), (integer)message - 1);
                        anim_triggers += pose_name;
                        anims += anim + ":1|";
                        integer index = llListFindList(anim_triggers, [pose_name]);
                        if (index != -1)
                        {
                            start_sequence(index, anim_name, llGetOwner());
                        }
                        main_menu();
                    }
                    else if (menu_type == "[ITEMS]")
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(item_triggers); i++)
                        {
                            if (llList2String(item_triggers, i) == pose_name)
                            {
                                item_triggers = llDeleteSubList(item_triggers, i, i);
                                items = llDeleteSubList(items, i, i);
                            }
                        }
                        string item = llList2String(get_contents(INVENTORY_OBJECT, page), (integer)message - 1);
                        item_triggers += pose_name;
                        items += item + "|";
                        main_menu();
                    }
                }
                else
                {
                    menu_determine(message);
                }
            }
        }
        else if (channel == comm_channel)
        {
            if (llGetOwnerKey(id) == llGetOwner())
            {
                if (message == "SAVEPROP")
                {
                    if (llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0) != ZERO_VECTOR)
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(prop_triggers); i++)
                        {
                            if (llList2String(prop_triggers, i) == pose_name)
                            {
                                prop_triggers = llDeleteSubList(prop_triggers, i, i);
                                props = llDeleteSubList(props, i, i);
                            }
                        }
                        list details = [OBJECT_POS, OBJECT_ROT];
                        rotation f = llList2Rot(details = llGetObjectDetails(llGetKey(), details) + llGetObjectDetails(id, details), 1);
                        rotation target_rot = llList2Rot(details, 3) / f;
                        vector target_pos = (llList2Vector(details, 2) - llList2Vector(details, 0)) / f;
                        prop_triggers += pose_name;
                        props += name + "|" + (string)target_pos + "|" + (string)(llRot2Euler(target_rot) * RAD_TO_DEG);
                        llSay(0, "PROP for pose '" + pose_name + "' saved to memory.");
                    }
                }
            }
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90075)
        {
            llPlaySound("ed124764-705d-d497-167a-182cd9fa2e6c", 0);
            playing_sound_for = NULL_KEY;
            SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
            check_sitters();
        }
        else if (sender == llGetLinkNumber())
        {
            if (num == 1125)
            {
                expressions_toggle_off = (!expressions_toggle_off);
                string expressions_text = "ON";
                if (expressions_toggle_off)
                {
                    expressions_text = "OFF";
                }
                llInstantMessage(id, "Facial Expressions " + expressions_text);
            }
            else if (num == 90045)
            {
                list data = llParseStringKeepNulls(msg, ["|"], []);
                anim_name = llList2String(data, 1);
                string given_posename = llList2String(data, 0);
                if (llSubStringIndex(given_posename, "S:") == 0)
                {
                    given_posename = llGetSubString(given_posename, 2, -1);
                }
                if (given_posename != pose_name || llSubStringIndex(llList2String(data, 0), "S:") == -1)
                {
                    integer old_is_sync;
                    if (llSubStringIndex(raw_pose_name, "S:") == 0)
                    {
                        old_is_sync = TRUE;
                    }
                    raw_pose_name = llList2String(data, 0);
                    pose_name = given_posename;
                    integer index = llListFindList(prop_triggers, [pose_name]);
                    llPlaySound("ed124764-705d-d497-167a-182cd9fa2e6c", 0);
                    if ((!sticky_rez) && (id == playing_prop_for || old_is_sync || llSubStringIndex(raw_pose_name, "S:") == 0) || index != -1)
                    {
                        sticky_rez = FALSE;
                        remove_props();
                    }
                    if (index != -1)
                    {
                        playing_prop_for = id;
                        rez_prop(index);
                    }
                    index = llListFindList(sound_triggers, [pose_name]);
                    if (index != -1)
                    {
                        playing_sound_for = id;
                        play_sound(index);
                    }
                }
                remove_sequences(id);
                integer i;
                while (i < llGetListLength(anim_triggers))
                {
                    if (llList2String(anim_triggers, i) == pose_name)
                    {
                        start_sequence(i, anim_name, id);
                    }
                    i++;
                }
                i = 0;
                while (i < llGetListLength(item_triggers))
                {
                    if (llList2String(item_triggers, i) == pose_name)
                    {
                        give_item(i, anim_name, id);
                    }
                    i++;
                }
            }
            else if (num == 90010)
            {
                llListenControl(comm_listen_handle, TRUE);
                llRegionSay(comm_channel, "PROPSEARCH");
            }
            else if (num == 90060)
            {
                llListenControl(comm_listen_handle, FALSE);
                llListenControl(menu_listen_handle, FALSE);
                integer index = llListFindList(SITTERS, [NULL_KEY]);
                if (index != -1)
                {
                    SITTERS = llListReplaceList(SITTERS, [id], index, index);
                    if (camera_position != ZERO_VECTOR)
                    {
                        if (index == 0)
                        {
                            llRequestPermissions(id, PERMISSION_CONTROL_CAMERA);
                        }
                        else
                        {
                            llMessageLinked(LINK_THIS, 90150, (string)id + "|" + (string)camera_position + "|" + (string)camera_focus, (string)index);
                        }
                    }
                }
            }
            else if (num == 90065)
            {
                if (id == playing_sound_for)
                {
                    llPlaySound("ed124764-705d-d497-167a-182cd9fa2e6c", 0);
                    playing_sound_for = NULL_KEY;
                }
                integer index = llListFindList(SITTERS, [id]);
                remove_sequences(id);
                if (index != -1)
                {
                    SITTERS = llListReplaceList(SITTERS, [NULL_KEY], index, index);
                    check_sitters();
                }
            }
            else if (num == 90030)
            {
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)msg, (integer)msg);
                SITTERS = llListReplaceList(SITTERS, [NULL_KEY], (integer)((string)id), (integer)((string)id));
            }
            else if (num == 90070)
            {
                SITTERS = llListReplaceList(SITTERS, [id], (integer)msg, (integer)msg);
            }
            else if (num == 90140)
            {
                if (id == llGetOwner())
                {
                    if (pose_name == "")
                    {
                        llMessageLinked(LINK_SET, 90005, "", id);
                        Owner_Say("Please select an animation first.");
                    }
                    else
                    {
                        llListenControl(menu_listen_handle, TRUE);
                        main_menu();
                    }
                }
                else
                {
                    llInstantMessage(id, "Sorry, the [EXTRAS] menu is for Owner only.");
                    llMessageLinked(LINK_SET, 90005, "", id);
                }
            }
            else if (num == 90020 && (integer)msg == get_number_of_scripts(mainscript_basename))
            {
                Readout_Say("-----EXTRAS------------");
                integer i;
                for (i = 0; i < llGetListLength(prop_triggers); i++)
                {
                    Readout_Say("PROP " + llList2String(prop_triggers, i) + "|" + llList2String(props, i));
                }
                for (i = 0; i < llGetListLength(sound_triggers); i++)
                {
                    Readout_Say("SOUND " + llList2String(sound_triggers, i) + "|" + llList2String(sounds, i));
                }
                for (i = 0; i < llGetListLength(item_triggers); i++)
                {
                    Readout_Say("ITEM " + llList2String(item_triggers, i) + "|" + llList2String(items, i));
                }
                for (i = 0; i < llGetListLength(anim_triggers); i++)
                {
                    integer x;
                    list sequence = llParseStringKeepNulls(llList2String(anims, i), [":"], []);
                    for (x = 0; x < llGetListLength(sequence); x = x + 2)
                    {
                        if (IsInteger(llList2String(sequence, x)))
                        {
                            sequence = llListReplaceList(sequence, [llList2String(facial_anim_list, (integer)llList2String(sequence, x))], x, x);
                        }
                    }
                    Readout_Say("ANIM " + llList2String(anim_triggers, i) + "|" + llDumpList2String(sequence, ":"));
                }
                if (camera_position != ZERO_VECTOR)
                {
                    Readout_Say("CAMERA " + (string)camera_position + "|" + (string)camera_focus);
                }
            }
            else if (num == 90200)
            {
                remove_props();
                integer index = llListFindList(prop_triggers, [msg]);
                if (index != -1)
                {
                    llSleep(1);
                    sticky_rez = TRUE;
                    rez_prop(index);
                }
                llMessageLinked(LINK_SET, 90005, "", id);
            }
        }
    }
    run_time_permissions(integer perm)
    {
        if (llGetPermissions() & PERMISSION_CONTROL_CAMERA)
        {
            vector pos = camera_position * llGetRot() + llGetPos();
            vector focus = camera_focus * llGetRot() + llGetPos();
            llSetCameraParams([CAMERA_ACTIVE, 1, CAMERA_FOCUS, focus, CAMERA_FOCUS_LOCKED, TRUE, CAMERA_POSITION, pos, CAMERA_POSITION_LOCKED, TRUE, CAMERA_FOCUS_OFFSET, <0,0,0>]);
        }
        else if (llGetPermissions() & PERMISSION_TRACK_CAMERA)
        {
            camera_menu();
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(notecard_name) != notecard_key || get_number_of_scripts(mainscript_basename) != llGetListLength(SITTERS))
            {
                remove_props();
                llResetScript();
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                Owner_Say("Ready, Memory: " + (string)llGetFreeMemory());
                llPlaySound("ed124764-705d-d497-167a-182cd9fa2e6c", 1);
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseStringKeepNulls(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                data = llDumpList2String(llList2List(parts, 1, -1), "|");
                string pose = llList2String(parts, 0);
                if (llSubStringIndex(pose, "S:") == 0)
                {
                    pose = llGetSubString(pose, 2, -1);
                }
                if (command == "PROP")
                {
                    prop_triggers += pose;
                    props += data;
                    Owner_Say("Read settings for Prop '" + llList2String(parts, 1) + "'");
                }
                else if (command == "SOUND")
                {
                    sound_triggers += pose;
                    sounds += data;
                    Owner_Say("Read settings for Sound '" + llList2String(parts, 1) + "'");
                }
                else if (command == "ITEM")
                {
                    item_triggers += pose;
                    items += data;
                    Owner_Say("Read settings for Item '" + llList2String(parts, 1) + "'");
                }
                else if (command == "ANIM")
                {
                    anim_triggers += pose;
                    list anim_data = llParseStringKeepNulls(data, ["|"], []);
                    list sequence = llParseStringKeepNulls(llList2String(anim_data, 0), [":"], []);
                    integer i;
                    for (i = 0; i < llGetListLength(sequence); i = i + 2)
                    {
                        integer index = llListFindList(facial_anim_list, [llList2String(sequence, i)]);
                        if (index != -1)
                        {
                            sequence = llListReplaceList(sequence, [index], i, i);
                        }
                    }
                    anim_data = llListReplaceList(anim_data, [llDumpList2String(sequence, ":")], 0, 0);
                    anims += llDumpList2String(anim_data, "|");
                    Owner_Say("Read settings for Expressions for '" + pose + "'");
                }
                else if (command == "CAMERA")
                {
                    camera_position = (vector)pose;
                    camera_focus = (vector)llList2String(parts, 1);
                    Owner_Say("Read settings for Camera");
                }
                notecard_query = llGetNotecardLine(notecard_name, notecard_line += 1);
            }
        }
    }
}
state nothing
{
    state_entry()
    {
    	// do nothing
    }
}
