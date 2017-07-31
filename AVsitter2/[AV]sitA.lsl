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
string notecard_name = "AVpos";
string main_script = "[AV]sitA";
string memoryscript = "[AV]sitB";
string expression_script = "[AV]faces";
string helper_object = "[AV]helper";
string adjust_script = "[AV]adjuster";
integer SCRIPT_CHANNEL;
list SITTERS;
integer SWAPPED;
key MY_SITTER;
key CONTROLLER;
list SITTER_INFO;
string CUSTOM_TEXT;
list ADJUST_MENU;
integer SET = -1;
integer MTYPE = 0;
integer ETYPE = 1;
integer SELECT;
integer SWAP = 2;
integer AMENU = 2;
integer DFLT = 1;
list GENDERS;
integer OLD_HELPER_METHOD;
integer WARN = 1;
string FIRST_POSENAME;
string FIRST_ANIMATION_SEQUENCE;
string OLD_POSE_NAME;
string CURRENT_POSE_NAME;
string OLD_ANIMATION_FILENAME;
string CURRENT_ANIMATION_SEQUENCE;
string MALE_POSENAME;
string FIRST_MALE_ANIMATION_SEQUENCE;
string FEMALE_POSENAME;
string FIRST_FEMALE_ANIMATION_SEQUENCE;
string CURRENT_ANIMATION_FILENAME;
integer SEQUENCE_POINTER;
vector FIRST_POSITION;
vector FIRST_ROTATION;
vector DEFAULT_POSITION;
vector DEFAULT_ROTATION;
vector CURRENT_POSITION;
vector CURRENT_ROTATION;
integer wrong_primcount;
integer prims;
list CUSTOMS;
integer HASKEYFRAME = FALSE;
integer REFERENCE;
key notecard_key;
key notecard_query;
integer reading_notecard_section;
integer notecard_lines;
key reused_key;
integer reused_variable;
integer my_sittarget;
integer original_my_sittarget;
list SITTERS_SITTARGETS;
list ORIGINAL_SITTERS_SITTARGETS;
integer has_security;
integer has_texture;
string RLVDesignations;
integer increment_pointer;
integer pos_rot_adjust_toggle;
integer menu_channel;
integer menu_handle;
string BRAND;
string onSit;
integer speed_index;
integer verbose = 0;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "] " + out);
    }
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
integer get_number_of_scripts()
{
    integer i;
    while (llGetInventoryType(main_script + " " + (string)(++i)) == INVENTORY_SCRIPT)
        ;
    return i;
}
dialog(string text, list menu_items)
{
    llListenRemove(menu_handle);
    menu_handle = llListen(menu_channel = ((integer)llFrand(2147483646) + 1) * -1, "", CONTROLLER, "");
    llDialog(CONTROLLER, product + " " + version + "\n\n" + text, order_buttons(menu_items), menu_channel);
}
options_menu()
{
    list menu_items;
    if (has_texture)
    {
        menu_items += "[TEXTURE]";
    }
    if (llGetInventoryType(expression_script) == INVENTORY_SCRIPT)
    {
        menu_items += "[FACES]";
    }
    if (has_security)
    {
        menu_items += "[SECURITY]";
    }
    integer i;
    while (i < llGetListLength(ADJUST_MENU))
    {
        menu_items += llList2String(ADJUST_MENU, i);
        i = i + 2;
    }
    if (llGetInventoryType(helper_object) == INVENTORY_OBJECT && llGetInventoryType(adjust_script) == INVENTORY_SCRIPT)
    {
        menu_items += "[HELPER]";
    }
    if (!llGetListLength(menu_items))
    {
        adjust_pose_menu();
        return;
    }
    menu_items += "[POSE]";
    dialog("Adjust:", ["[BACK]"] + menu_items);
}
adjust_pose_menu()
{
    string posrot_button = "Position";
    string value_button = llList2String(["0.05m", "0.25m", "0.01m"], increment_pointer);
    if (pos_rot_adjust_toggle)
    {
        posrot_button = "Rotation";
        value_button = llList2String(["5°", "25°", "1°"], increment_pointer);
    }
    dialog("Personal adjustment:", ["[BACK]", posrot_button, value_button, "[DEFAULT]", "[SAVE]", "[SAVE ALL]", "X+", "Y+", "Z+", "X-", "Y-", "Z-"]);
}
integer IsInteger(string data)
{
    return llParseString2List((string)llParseString2List(data, ["8", "9"], []), ["0", "1", "2", "3", "4", "5", "6", "7"], []) == [] && data != "";
}
wipe_sit_targets()
{
    integer i;
    for (i = 0; i <= llGetNumberOfPrims(); i++)
    {
        string desc = llList2String(llGetObjectDetails(llGetLinkKey(i), [OBJECT_DESC]), 0);
        if (desc != "-1")
        {
            llLinkSitTarget(i, ZERO_VECTOR, ZERO_ROTATION);
        }
    }
}
primcount_error()
{
    llDialog(llGetOwner(), "\nThere aren't enough prims for required SitTargets.\nYou must have one prim for each avatar to sit!", [], 23658);
}
sittargets()
{
    wrong_primcount = FALSE;
    prims = llGetObjectPrimCount(llGetKey());
    if (llGetListLength(SITTERS) > prims && WARN)
    {
        if (!SCRIPT_CHANNEL)
        {
            primcount_error();
        }
        wrong_primcount = TRUE;
    }
    integer i;
    SITTERS_SITTARGETS = [];
    list ASSIGNED_SITTARGETS = [];
    if (llGetListLength(SITTERS) == 1)
    {
        my_sittarget = llGetLinkNumber();
        SITTERS_SITTARGETS += my_sittarget;
    }
    else
    {
        for (i = 0; i < llGetListLength(SITTERS); i++)
        {
            SITTERS_SITTARGETS += 1000;
            ASSIGNED_SITTARGETS += FALSE;
        }
        for (i = 1; i <= prims; i++)
        {
            integer next = llListFindList(SITTERS_SITTARGETS, [1000]);
            string desc = llList2String(llGetObjectDetails(llGetLinkKey(i), [OBJECT_DESC]), 0);
            integer index = llSubStringIndex(desc, "#");
            if (index)
            {
                desc = llGetSubString(desc, index + 1, -1);
            }
            if (desc != "-1")
            {
                list data = llParseStringKeepNulls(desc, ["-"], []);
                if (llGetListLength(data) == 2 && IsInteger(llList2String(data, 0)) && IsInteger(llList2String(data, 1)))
                {
                    if ((integer)llList2String(data, 0) == SET)
                    {
                        SITTERS_SITTARGETS = llListReplaceList(SITTERS_SITTARGETS, [i], (integer)llList2String(data, 1), (integer)llList2String(data, 1));
                        ASSIGNED_SITTARGETS = llListReplaceList(ASSIGNED_SITTARGETS, [TRUE], (integer)llList2String(data, 1), (integer)llList2String(data, 1));
                        if (llListFindList(ASSIGNED_SITTARGETS, [FALSE]) == -1)
                        {
                            jump end;
                        }
                    }
                }
                else if (next != -1)
                {
                    SITTERS_SITTARGETS = llListReplaceList(SITTERS_SITTARGETS, [i], next, next);
                }
            }
        }
        @end;
        my_sittarget = llList2Integer(SITTERS_SITTARGETS, SCRIPT_CHANNEL);
    }
    original_my_sittarget = my_sittarget;
    ORIGINAL_SITTERS_SITTARGETS = SITTERS_SITTARGETS;
    prep();
    set_sittarget();
}
prep()
{
    has_security = (has_texture = FALSE);
    if (!SCRIPT_CHANNEL)
    {
        llMessageLinked(LINK_SET, 90201, "", "");
    }
}
release_sitter(integer i)
{
    SITTERS = llListReplaceList(SITTERS, [""], i, i);
    if (i == SCRIPT_CHANNEL)
    {
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
        {
            if (MY_SITTER)
            {
                llMessageLinked(LINK_SET, 90065, (string)SCRIPT_CHANNEL, MY_SITTER);
            }
            if (llGetAgentSize(MY_SITTER) != ZERO_VECTOR && CURRENT_ANIMATION_FILENAME != "")
            {
                llStopAnimation(CURRENT_ANIMATION_FILENAME);
            }
            MY_SITTER = "";
            llListenRemove(menu_handle);
        }
    }
}
set_sittarget()
{
    vector target_pos = DEFAULT_POSITION;
    rotation target_rot = llEuler2Rot(DEFAULT_ROTATION * DEG_TO_RAD);
    if (my_sittarget != llGetLinkNumber())
    {
        vector local_avsit_prim_pos;
        rotation local_avsit_prim_rot;
        if (llGetLinkNumber() > 1)
        {
            local_avsit_prim_pos = llGetLocalPos();
            local_avsit_prim_rot = llGetLocalRot();
        }
        target_pos = local_avsit_prim_pos + DEFAULT_POSITION * local_avsit_prim_rot;
        target_rot = target_rot * local_avsit_prim_rot;
        if (my_sittarget > 1)
        {
            rotation local_target_prim_rot = llList2Rot(llGetLinkPrimitiveParams(my_sittarget, [PRIM_ROT_LOCAL]), 0);
            target_pos = (local_avsit_prim_pos + DEFAULT_POSITION * local_avsit_prim_rot - llList2Vector(llGetLinkPrimitiveParams(my_sittarget, [PRIM_POS_LOCAL]), 0)) / local_target_prim_rot;
            target_rot = target_rot / local_target_prim_rot;
        }
    }
    integer target = my_sittarget;
    if (llGetNumberOfPrims() == 1 && target == 1)
    {
        target = 0;
    }
    if (llList2String(llGetObjectDetails(llGetLinkKey(target), [OBJECT_DESC]), 0) != "-1")
    {
        llLinkSitTarget(target, target_pos - <0.,0.,0.4> + llRot2Up(target_rot) * 0.05, target_rot);
    }
}
update_current_anim_name()
{
    list SEQUENCE = llParseStringKeepNulls(CURRENT_ANIMATION_SEQUENCE, ["�"], []);
    CURRENT_ANIMATION_FILENAME = llList2String(SEQUENCE, SEQUENCE_POINTER);
    string speed_text = llList2String(["", "+", "-"], speed_index);
    if (llGetInventoryType(CURRENT_ANIMATION_FILENAME + speed_text) == INVENTORY_ANIMATION)
    {
        CURRENT_ANIMATION_FILENAME += speed_text;
    }
    llSetTimerEvent((float)llList2String(SEQUENCE, SEQUENCE_POINTER + 1));
}
apply_current_anim(integer broadcast)
{
    SEQUENCE_POINTER = 0;
    update_current_anim_name();
    CURRENT_POSITION = DEFAULT_POSITION;
    CURRENT_ROTATION = DEFAULT_ROTATION;
    integer custom_index = llListFindList(CUSTOMS, [CURRENT_POSE_NAME, llGetSubString(MY_SITTER, 0, 7)]);
    if (custom_index == -1)
    {
        custom_index = llListFindList(CUSTOMS, ["M#T!", llGetSubString(MY_SITTER, 0, 7)]);
    }
    if (custom_index > -1)
    {
        CURRENT_POSITION += llList2Vector(CUSTOMS, custom_index + 2);
        CURRENT_ROTATION += llList2Vector(CUSTOMS, custom_index + 3);
        CUSTOMS = llListReplaceList(CUSTOMS, [], custom_index, custom_index + 3) + llList2List(CUSTOMS, custom_index, custom_index + 3);
    }
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
    {
        if (llGetAgentSize(MY_SITTER))
        {
            if (broadcast)
            {
                string POSENAME = CURRENT_POSE_NAME;
                integer IS_SYNC;
                if (llSubStringIndex(POSENAME, "P:"))
                {
                    IS_SYNC = TRUE;
                }
                else
                {
                    POSENAME = llGetSubString(POSENAME, 2, -1);
                }
                string OLD_SYNC;
                if (OLD_POSE_NAME != CURRENT_POSE_NAME)
                {
                    if (llSubStringIndex(OLD_POSE_NAME, "P:"))
                    {
                        OLD_SYNC = OLD_POSE_NAME;
                    }
                }
                llMessageLinked(LINK_SET, 90045, llDumpList2String([SCRIPT_CHANNEL, POSENAME, CURRENT_ANIMATION_SEQUENCE, SET, llDumpList2String(SITTERS, "@"), OLD_SYNC, IS_SYNC], "|"), MY_SITTER);
            }
            if (HASKEYFRAME)
            {
                sit_using_prim_params();
            }
            if (CURRENT_ANIMATION_FILENAME)
            {
                llStartAnimation(CURRENT_ANIMATION_FILENAME);
            }
            if (OLD_ANIMATION_FILENAME != "" && OLD_ANIMATION_FILENAME != CURRENT_ANIMATION_FILENAME)
            {
                llSleep(0.2);
                llStopAnimation(OLD_ANIMATION_FILENAME);
            }
            if (!HASKEYFRAME)
            {
                sit_using_prim_params();
            }
        }
    }
}
sit_using_prim_params()
{
    integer sitter_prim = llGetNumberOfPrims();
    while (llGetAgentSize(llGetLinkKey(sitter_prim)))
    {
        if (llGetLinkKey(sitter_prim) == MY_SITTER)
        {
            jump ok;
        }
        sitter_prim--;
    }
    return;
    @ok;
    rotation localrot = ZERO_ROTATION;
    vector localpos = ZERO_VECTOR;
    if (llGetLinkNumber() > 1)
    {
        localrot = llGetLocalRot();
        localpos = llGetLocalPos();
    }
    if (HASKEYFRAME == 2 && (!llGetStatus(STATUS_PHYSICS)))
    {
        llSleep(0.4);
    }
    if (HASKEYFRAME && (!llGetStatus(STATUS_PHYSICS)))
    {
        llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_PAUSE]);
        llSleep(0.15);
    }
    llSetLinkPrimitiveParamsFast(sitter_prim, [PRIM_ROT_LOCAL, llEuler2Rot((CURRENT_ROTATION + <0,0,0.002>) * DEG_TO_RAD) * localrot, PRIM_POS_LOCAL, CURRENT_POSITION * localrot + localpos]);
    if (HASKEYFRAME && (!llGetStatus(STATUS_PHYSICS)))
    {
        llSleep(0.15);
        llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_PLAY]);
    }
}
end_sitter()
{
    llSetTimerEvent(0);
    if (MY_SITTER)
    {
        if (CURRENT_ANIMATION_FILENAME)
        {
            llStopAnimation(CURRENT_ANIMATION_FILENAME);
        }
        if (OLD_HELPER_METHOD)
        {
            llStartAnimation("sit");
        }
    }
}
default
{
    state_entry()
    {
        SCRIPT_CHANNEL = (integer)llGetSubString(llGetScriptName(), llSubStringIndex(llGetScriptName(), " "), -1);
        while (llGetInventoryType(memoryscript) != INVENTORY_SCRIPT)
        {
        }
        integer i;
        while (i++ < get_number_of_scripts())
        {
            SITTERS += "";
        }
        if (SCRIPT_CHANNEL)
        {
            memoryscript += " " + (string)SCRIPT_CHANNEL;
        }
        else
        {
            wipe_sit_targets();
            reused_key = llGetNumberOfNotecardLines(notecard_name);
            reading_notecard_section = TRUE;
        }
        notecard_key = llGetInventoryKey(notecard_name);
        llMessageLinked(LINK_THIS, 90299, (string)SCRIPT_CHANNEL, "");
        if (llGetInventoryType(notecard_name) == INVENTORY_NOTECARD)
        {
            if (!SCRIPT_CHANNEL)
            {
                Out(0, "Loading " + notecard_name + "...");
            }
            notecard_query = llGetNotecardLine(notecard_name, reused_variable);
        }
    }
    timer()
    {
        SEQUENCE_POINTER += 2;
        list SEQUENCE = llParseStringKeepNulls(CURRENT_ANIMATION_SEQUENCE, ["�"], []);
        if (SEQUENCE_POINTER >= llGetListLength(SEQUENCE) || (~llListFindList(["M", "F"], llList2List(SEQUENCE, SEQUENCE_POINTER, SEQUENCE_POINTER))))
        {
            SEQUENCE_POINTER = 0;
        }
        OLD_ANIMATION_FILENAME = CURRENT_ANIMATION_FILENAME;
        update_current_anim_name();
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
        {
            if (llGetAgentSize(MY_SITTER))
            {
                if (CURRENT_ANIMATION_FILENAME)
                {
                    llStartAnimation(CURRENT_ANIMATION_FILENAME);
                }
                if (OLD_ANIMATION_FILENAME != "" && OLD_ANIMATION_FILENAME != CURRENT_ANIMATION_FILENAME)
                {
                    llSleep(1.);
                    llStopAnimation(OLD_ANIMATION_FILENAME);
                }
            }
        }
    }
    touch_end(integer touched)
    {
        if ((!SCRIPT_CHANNEL) && (!has_security) && MTYPE < 3)
        {
            llMessageLinked(LINK_SET, 90005, "", llDetectedKey(0));
        }
    }
    listen(integer listen_channel, string name, key id, string msg)
    {
        integer index = llListFindList(ADJUST_MENU, [msg]);
        if (index != -1)
        {
            if (id != MY_SITTER)
            {
                id = llDumpList2String([id, MY_SITTER], "|");
            }
            llMessageLinked(LINK_SET, (integer)llList2String(ADJUST_MENU, index + 1), msg, id);
        }
        else
        {
            index = llListFindList(["Position", "Rotation", "X+", "Y+", "Z+", "X-", "Y-", "Z-", "0.05m", "0.25m", "0.01m", "5°", "25°", "1°"], [msg]);
            if (msg == "[BACK]")
            {
                llMessageLinked(LINK_SET, 90005, "", llDumpList2String([CONTROLLER, MY_SITTER], "|"));
            }
            else if (msg == "[POSE]")
            {
                adjust_pose_menu();
            }
            else if (msg == "[DEFAULT]")
            {
                CURRENT_POSITION = DEFAULT_POSITION;
                CURRENT_ROTATION = DEFAULT_ROTATION;
                sit_using_prim_params();
                adjust_pose_menu();
            }
            else if (msg == "[SAVE ALL]")
            {
                dialog("Save personal position offset for all poses?", ["[BACK]", "[ALL POSES]"]);
            }
            else if (msg == "[ALL POSES]")
            {
                integer i = llGetListLength(CUSTOMS) - 3;
                while (i > 0)
                {
                    if (llList2String(CUSTOMS, i) == llGetSubString(MY_SITTER, 0, 7))
                    {
                        CUSTOMS = llDeleteSubList(CUSTOMS, i - 1, i + 3);
                    }
                    i -= 4;
                }
                CUSTOMS += ["M#T!", llGetSubString(MY_SITTER, 0, 7), CURRENT_POSITION - DEFAULT_POSITION, CURRENT_ROTATION - DEFAULT_ROTATION];
                adjust_pose_menu();
                llRegionSayTo(id, 0, "Personal position saved for all poses.");
            }
            else if (msg == "[SAVE]")
            {
                integer custom_index = llListFindList(CUSTOMS, [CURRENT_POSE_NAME, llGetSubString(MY_SITTER, 0, 7)]);
                if (custom_index >= 0)
                {
                    CUSTOMS = llDeleteSubList(CUSTOMS, custom_index, custom_index + 3);
                }
                if (llGetListLength(CUSTOMS) / 4 >= reused_variable)
                {
                    CUSTOMS = llDeleteSubList(CUSTOMS, 0, 3);
                }
                CUSTOMS += [CURRENT_POSE_NAME, llGetSubString(MY_SITTER, 0, 7), CURRENT_POSITION - DEFAULT_POSITION, CURRENT_ROTATION - DEFAULT_ROTATION];
                adjust_pose_menu();
                llRegionSayTo(id, 0, "Personal position saved for this pose.");
            }
            else if (index != -1)
            {
                if (index < 2)
                {
                    pos_rot_adjust_toggle = (!pos_rot_adjust_toggle);
                }
                else if (index < 8)
                {
                    float change = llList2Float([0.05, 0.25, 0.01], increment_pointer);
                    if (llGetSubString(msg, 1, 1) == "-")
                    {
                        change = -1 * change;
                    }
                    vector direction = <1,0,0>;
                    if (llGetSubString(msg, 0, 0) == "Y")
                    {
                        direction = <0,1,0>;
                    }
                    else if (llGetSubString(msg, 0, 0) == "Z")
                    {
                        direction = <0,0,1>;
                    }
                    if (pos_rot_adjust_toggle)
                    {
                        CURRENT_ROTATION += direction * change * 100;
                    }
                    else
                    {
                        vector c = direction * change;
                        if (REFERENCE)
                        {
                            if (llGetLinkNumber() > 1)
                            {
                                c /= llGetLocalRot();
                            }
                        }
                        else
                        {
                            c /= llGetRot();
                        }
                        CURRENT_POSITION += c;
                    }
                    sit_using_prim_params();
                }
                else
                {
                    increment_pointer = (increment_pointer + 1) % 3;
                }
                adjust_pose_menu();
            }
            else if (msg == "[HELPER]" && id != llGetOwner() && (!~llSubStringIndex(llGetLinkName(!!llGetLinkNumber()), "HELPER")))
            {
                dialog("Only the owner can rez the helpers. If the owner is nearby they can type '/5 helper' in chat.", ["[BACK]"]);
            }
            else
            {
                llMessageLinked(LINK_SET, 90100, (string)SCRIPT_CHANNEL + "|" + msg + "|" + (string)MY_SITTER + "|" + (string)OLD_HELPER_METHOD, id);
            }
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        integer one = (integer)msg;
        integer two = (integer)((string)id);
        if (num == 90075)
        {
            if (one == SCRIPT_CHANNEL)
            {
                llRequestPermissions(id, PERMISSION_TRIGGER_ANIMATION);
            }
        }
        else if (num == 90076)
        {
            release_sitter(one);
        }
        else if (num == 90030)
        {
            if (one == SCRIPT_CHANNEL || two == SCRIPT_CHANNEL)
            {
                end_sitter();
                reused_key = llList2Key(SITTERS, one);
                if (one == SCRIPT_CHANNEL)
                {
                    reused_key = llList2Key(SITTERS, two);
                }
                if (reused_key)
                {
                    SWAPPED = TRUE;
                    llRequestPermissions(reused_key, PERMISSION_TRIGGER_ANIMATION);
                }
            }
            SITTERS_SITTARGETS = llListReplaceList(llListReplaceList(SITTERS_SITTARGETS, [llList2Integer(SITTERS_SITTARGETS, two)], one, one), [llList2Integer(SITTERS_SITTARGETS, one)], two, two);
            my_sittarget = llList2Integer(SITTERS_SITTARGETS, SCRIPT_CHANNEL);
            set_sittarget();
            SITTERS = llListReplaceList(llListReplaceList(SITTERS, [""], one, one), [""], two, two);
            MY_SITTER = llList2Key(SITTERS, SCRIPT_CHANNEL);
        }
        else if (num == 90070)
        {
            if (one != SCRIPT_CHANNEL)
            {
                SITTERS = llListReplaceList(SITTERS, [id], one, one);
            }
        }
        if (num == 90150)
        {
            sittargets();
        }
        else if (num == 90202)
        {
            has_security = TRUE;
            llPassTouches(has_security);
        }
        else if (num == 90203)
        {
            has_texture = TRUE;
        }
        else if (num == 90298)
        {
            integer target = my_sittarget;
            if (llGetNumberOfPrims() == 1 && target == 1)
            {
                target = 0;
            }
            llSetLinkPrimitiveParams(target, [PRIM_TEXT, (string)SET + "-" + (string)SCRIPT_CHANNEL, <1,1,0>, 1]);
            llSleep(5);
            llSetLinkPrimitiveParams(target, [PRIM_TEXT, "", <1,1,1>, 1]);
        }
        else if (num == 90011)
        {
            llSetLinkCamera(LINK_THIS, (vector)msg, (vector)((string)id));
        }
        else if (num == 90033)
        {
            llListenRemove(menu_handle);
        }
        else if (id == MY_SITTER)
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            if (num == 90001)
            {
                llStartAnimation(msg);
            }
            else if (num == 90002)
            {
                llStopAnimation(msg);
            }
            else if (num == 90101)
            {
                CONTROLLER = (key)llList2String(data, 2);
                if (llList2String(data, 1) == "[ADJUST]")
                {
                    options_menu();
                }
                else if (llList2String(data, 1) == "Harder >>" || llList2String(data, 1) == "<< Softer")
                {
                    llMessageLinked(LINK_SET, 90005, "", llDumpList2String([CONTROLLER, MY_SITTER], "|"));
                }
                else if (llList2String(data, 1) == "[SWAP]")
                {
                    integer target_script = SCRIPT_CHANNEL + 1;
                    list X = SITTERS + SITTERS;
                    if (llSubStringIndex(CURRENT_POSE_NAME, "P:"))
                    {
                        while (llList2Key(X, target_script) == "" && target_script + 1 < llGetListLength(X))
                        {
                            target_script++;
                        }
                        if (llList2Key(X, target_script) == MY_SITTER)
                        {
                            target_script++;
                        }
                    }
                    else
                    {
                        while (llList2Key(X, target_script) != "" && target_script < llGetListLength(SITTERS) + SCRIPT_CHANNEL + 1)
                        {
                            target_script++;
                        }
                    }
                    target_script = target_script % llGetListLength(SITTERS);
                    llMessageLinked(LINK_THIS, 90030, (string)SCRIPT_CHANNEL, (string)target_script);
                }
            }
        }
        if (one == SCRIPT_CHANNEL)
        {
            if (num == 90055)
            {
                list data = llParseStringKeepNulls(id, ["|"], []);
                OLD_POSE_NAME = CURRENT_POSE_NAME;
                CURRENT_POSE_NAME = llList2String(data, 0);
                OLD_ANIMATION_FILENAME = CURRENT_ANIMATION_FILENAME;
                CURRENT_ANIMATION_SEQUENCE = llList2String(data, 1);
                DEFAULT_POSITION = (CURRENT_POSITION = (vector)llList2String(data, 2));
                DEFAULT_ROTATION = (CURRENT_ROTATION = (vector)llList2String(data, 3));
                if (FIRST_POSENAME == "" || CURRENT_POSE_NAME == FIRST_POSENAME)
                {
                    FIRST_POSENAME = CURRENT_POSE_NAME;
                    FIRST_POSITION = DEFAULT_POSITION;
                    FIRST_ROTATION = DEFAULT_ROTATION;
                    FIRST_ANIMATION_SEQUENCE = CURRENT_ANIMATION_SEQUENCE;
                }
                speed_index = (integer)llList2String(data, 5);
                apply_current_anim((integer)llList2String(data, 4));
                set_sittarget();
            }
            else if (num == 90057)
            {
                list data = llParseStringKeepNulls(id, ["|"], []);
                CURRENT_POSITION = (vector)llList2String(data, 0);
                CURRENT_ROTATION = (vector)llList2String(data, 1);
                sit_using_prim_params();
            }
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            SWAPPED = FALSE;
            integer i;
            integer stood;
            if (SET == -1 && llGetListLength(SITTERS) > 1)
            {
                list AVPRIMS;
                i = llGetNumberOfPrims();
                while (llGetAgentSize(llGetLinkKey(i)) != ZERO_VECTOR)
                {
                    if (llListFindList(SITTERS, [llGetLinkKey(i)]) == -1)
                    {
                        integer sitterGender = llList2Integer(llGetObjectDetails(llGetLinkKey(i), [OBJECT_BODY_SHAPE_TYPE]), 0);
                        integer first_available = llListFindList(SITTERS, [""]);
                        integer first_unassigned = -1;
                        integer j;
                        while (j < llGetListLength(SITTERS))
                        {
                            if (llList2String(SITTERS, j) == "")
                            {
                                if (llList2Integer(GENDERS, j) == sitterGender)
                                {
                                    first_available = j;
                                    jump foundavailable;
                                }
                                else if (llList2Integer(GENDERS, j) == -1 && first_unassigned == -1)
                                {
                                    first_unassigned = j;
                                }
                            }
                            j++;
                        }
                        if (first_unassigned > first_available)
                        {
                            first_available = first_unassigned;
                        }
                        @foundavailable;
                        if (first_available == SCRIPT_CHANNEL)
                        {
                            if (sitterGender)
                            {
                                if (MALE_POSENAME)
                                {
                                    if (CURRENT_POSE_NAME == FIRST_POSENAME)
                                    {
                                        CURRENT_POSE_NAME = MALE_POSENAME;
                                        CURRENT_ANIMATION_SEQUENCE = FIRST_MALE_ANIMATION_SEQUENCE;
                                    }
                                }
                            }
                            else
                            {
                                if (FEMALE_POSENAME)
                                {
                                    if (CURRENT_POSE_NAME == FIRST_POSENAME)
                                    {
                                        CURRENT_POSE_NAME = FEMALE_POSENAME;
                                        CURRENT_ANIMATION_SEQUENCE = FIRST_FEMALE_ANIMATION_SEQUENCE;
                                    }
                                }
                            }
                            llRequestPermissions(llGetLinkKey(i), PERMISSION_TRIGGER_ANIMATION);
                            llMessageLinked(LINK_SET, 90060, (string)SCRIPT_CHANNEL, llGetLinkKey(i));
                        }
                        else
                        {
                            llMessageLinked(LINK_THIS, 90056, (string)SCRIPT_CHANNEL, llDumpList2String([CURRENT_POSE_NAME, CURRENT_ANIMATION_SEQUENCE, CURRENT_POSITION, CURRENT_ROTATION], "|"));
                        }
                    }
                    AVPRIMS += llGetLinkKey(i);
                    i--;
                }
                for (i = 0; i < llGetListLength(SITTERS); i++)
                {
                    if (llList2Key(SITTERS, i) != "" && llListFindList(AVPRIMS, [llList2Key(SITTERS, i)]) == -1)
                    {
                        llSetTimerEvent(0);
                        stood = TRUE;
                        SITTERS = llListReplaceList(SITTERS, [""], i, i);
                        if (i == SCRIPT_CHANNEL)
                        {
                            if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                            {
                                if (MY_SITTER)
                                {
                                    llMessageLinked(LINK_SET, 90065, (string)SCRIPT_CHANNEL, MY_SITTER);
                                }
                                if (llGetAgentSize(MY_SITTER) != ZERO_VECTOR && (integer)CURRENT_ANIMATION_FILENAME)
                                {
                                    llStopAnimation(CURRENT_ANIMATION_FILENAME);
                                }
                                MY_SITTER = "";
                                llListenRemove(menu_handle);
                            }
                        }
                    }
                }
            }
            else
            {
                for (i = 0; i < llGetListLength(SITTERS); i++)
                {
                    string existing_sitter = llList2String(SITTERS, i);
                    key actual_sitter = llAvatarOnLinkSitTarget(llList2Integer(SITTERS_SITTARGETS, i));
                    if (llGetListLength(SITTERS) == 1)
                    {
                        actual_sitter = llAvatarOnSitTarget();
                    }
                    if (existing_sitter)
                    {
                        if (actual_sitter == NULL_KEY)
                        {
                            llSetTimerEvent(0);
                            stood = TRUE;
                            release_sitter(i);
                        }
                    }
                    else if (actual_sitter)
                    {
                        if (i == SCRIPT_CHANNEL)
                        {
                            if (llList2Integer(llGetObjectDetails(actual_sitter, [OBJECT_BODY_SHAPE_TYPE]), 0))
                            {
                                if (MALE_POSENAME)
                                {
                                    if (CURRENT_POSE_NAME == FIRST_POSENAME)
                                    {
                                        CURRENT_POSE_NAME = MALE_POSENAME;
                                        CURRENT_ANIMATION_SEQUENCE = FIRST_MALE_ANIMATION_SEQUENCE;
                                    }
                                }
                            }
                            else
                            {
                                if (FEMALE_POSENAME)
                                {
                                    if (CURRENT_POSE_NAME == FIRST_POSENAME)
                                    {
                                        CURRENT_POSE_NAME = FEMALE_POSENAME;
                                        CURRENT_ANIMATION_SEQUENCE = FIRST_FEMALE_ANIMATION_SEQUENCE;
                                    }
                                }
                            }
                            llRequestPermissions(actual_sitter, PERMISSION_TRIGGER_ANIMATION);
                            llMessageLinked(LINK_SET, 90060, (string)SCRIPT_CHANNEL, actual_sitter);
                        }
                        else
                        {
                            llMessageLinked(LINK_THIS, 90056, (string)SCRIPT_CHANNEL, llDumpList2String([CURRENT_POSE_NAME, CURRENT_ANIMATION_SEQUENCE, CURRENT_POSITION, CURRENT_ROTATION], "|"));
                        }
                    }
                }
            }
            if (stood && (!llStringLength(llDumpList2String(SITTERS, ""))))
            {
                if (DFLT || (!~llSubStringIndex(CURRENT_POSE_NAME, "P:")))
                {
                    DEFAULT_POSITION = FIRST_POSITION;
                    DEFAULT_ROTATION = FIRST_ROTATION;
                    CURRENT_POSE_NAME = FIRST_POSENAME;
                    CURRENT_ANIMATION_SEQUENCE = FIRST_ANIMATION_SEQUENCE;
                    my_sittarget = original_my_sittarget;
                    SITTERS_SITTARGETS = ORIGINAL_SITTERS_SITTARGETS;
                    set_sittarget();
                }
                prep();
            }
            if (prims != llGetObjectPrimCount(llGetKey()))
            {
                if (!SCRIPT_CHANNEL)
                {
                    wipe_sit_targets();
                    llMessageLinked(LINK_SET, 90150, "", "");
                }
                prep();
            }
        }
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(notecard_name) != notecard_key || get_number_of_scripts() != llGetListLength(SITTERS) || llGetInventoryType(memoryscript) != INVENTORY_SCRIPT)
            {
                end_sitter();
                llResetScript();
            }
        }
    }
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStopAnimation("sit");
            if (llGetInventoryType("AVhipfix") == INVENTORY_ANIMATION)
            {
                llStartAnimation("AVhipfix");
            }
            integer animation_menu_function;
            if (llGetPermissionsKey() != reused_key)
            {
                animation_menu_function = -1;
            }
            reused_key = "";
            SITTERS = llListReplaceList(SITTERS, [CONTROLLER = (MY_SITTER = llGetPermissionsKey())], SCRIPT_CHANNEL, SCRIPT_CHANNEL);
            string channel_or_swap = (string)SCRIPT_CHANNEL;
            integer lnk = 90000;
            if (SWAPPED)
            {
                lnk = 90010;
                SWAPPED = FALSE;
            }
            else if (llGetSubString(CURRENT_POSE_NAME, 0, 1) != "P:")
            {
                channel_or_swap = "";
            }
            string posename = CURRENT_POSE_NAME;
            if (llGetSubString(CURRENT_POSE_NAME, 0, 1) == "P:")
            {
                posename = llGetSubString(CURRENT_POSE_NAME, 2, -1);
            }
            llMessageLinked(LINK_THIS, 90070, (string)SCRIPT_CHANNEL, MY_SITTER);
            llMessageLinked(LINK_THIS, lnk, posename, channel_or_swap);
            if (wrong_primcount && WARN)
            {
                primcount_error();
            }
            else if (!MTYPE)
            {
                if (has_security)
                {
                    llMessageLinked(LINK_SET, 90006, (string)animation_menu_function, MY_SITTER);
                }
                else
                {
                    llMessageLinked(LINK_SET, 90005, (string)animation_menu_function, llDumpList2String([CONTROLLER, MY_SITTER], "|"));
                }
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                if (SCRIPT_CHANNEL)
                {
                    sittargets();
                }
                else
                {
                    llSetText("", <1,1,1>, 1);
                    llMessageLinked(LINK_SET, 90150, "", "");
                }
                llMessageLinked(LINK_THIS, 90302, (string)SCRIPT_CHANNEL, llDumpList2String([llGetListLength(SITTERS), llDumpList2String(SITTER_INFO, "�"), SET, MTYPE, ETYPE, SWAP, FIRST_POSENAME, BRAND, CUSTOM_TEXT, llDumpList2String(ADJUST_MENU, "�"), SELECT, AMENU, OLD_HELPER_METHOD, RLVDesignations, onSit], "|"));
                reused_variable = (llGetFreeMemory() - 5000) / 100;
            }
            else
            {
                if (notecard_lines)
                {
                    llSetText("Loading " + (string)((integer)((float)reused_variable / notecard_lines * 100)) + "%", <1,1,0>, 1);
                }
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM_HEAD);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseStringKeepNulls(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                string part0 = llStringTrim(llList2String(parts, 0), STRING_TRIM);
                string part1;
                if (llGetListLength(parts) > 1)
                {
                    part1 = llStringTrim(llDumpList2String(llList2List(parts, 1, -1), "�"), STRING_TRIM);
                }
                if (command == "SITTER")
                {
                    reading_notecard_section = FALSE;
                    if (llList2String(parts, 2) == "M")
                    {
                        GENDERS += 1;
                    }
                    else if (llList2String(parts, 2) == "F")
                    {
                        GENDERS += 0;
                    }
                    else
                    {
                        GENDERS += -1;
                    }
                    if ((integer)part0 == SCRIPT_CHANNEL)
                    {
                        reading_notecard_section = TRUE;
                        if (llGetListLength(parts) > 1)
                        {
                            SITTER_INFO = llList2List(parts, 1, -1);
                        }
                    }
                }
                else if (command == "MTYPE")
                {
                    MTYPE = (integer)part0;
                    llPassTouches(FALSE);
                    if (MTYPE > 2)
                    {
                        llPassTouches(TRUE);
                    }
                }
                else if (command == "ROLES")
                {
                    RLVDesignations = (string)parts;
                }
                else if (command == "ETYPE")
                {
                    ETYPE = (integer)part0;
                }
                else if (command == "SELECT")
                {
                    SELECT = (integer)part0;
                }
                else if (command == "WARN")
                {
                    WARN = (integer)part0;
                }
                else if (command == "TEXT")
                {
                    CUSTOM_TEXT = llDumpList2String(llParseStringKeepNulls(part0, ["\\n"], []), "\n");
                }
                else if (command == "SWAP")
                {
                    SWAP = (integer)part0;
                }
                else if (command == "AMENU")
                {
                    AMENU = (integer)part0;
                }
                else if (command == "HELPER")
                {
                    OLD_HELPER_METHOD = (integer)part0;
                }
                else if (command == "SET")
                {
                    SET = (integer)part0;
                }
                else if (command == "KFM")
                {
                    HASKEYFRAME = (integer)part0;
                }
                else if (command == "LROT")
                {
                    REFERENCE = (integer)part0;
                }
                else if (command == "BRAND")
                {
                    BRAND = part0;
                }
                else if (command == "DFLT")
                {
                    DFLT = (integer)part0;
                }
                else if (command == "ONSIT")
                {
                    onSit = part0;
                }
                else if (command == "ADJUST")
                {
                    ADJUST_MENU = parts;
                }
                else if (reading_notecard_section)
                {
                    if (llGetSubString(data, 0, 0) == "{")
                    {
                        command = llStringTrim(llGetSubString(data, 1, llSubStringIndex(data, "}") - 1), STRING_TRIM);
                        parts = llParseStringKeepNulls(llDumpList2String(llParseString2List(llGetSubString(data, llSubStringIndex(data, "}") + 1, -1), [" "], [""]), ""), ["<"], []);
                        string pos = "<" + llList2String(parts, 1);
                        string rot = "<" + llList2String(parts, 2);
                        if (command == FIRST_POSENAME || "P:" + command == FIRST_POSENAME)
                        {
                            FIRST_POSITION = (DEFAULT_POSITION = (CURRENT_POSITION = (vector)pos));
                            FIRST_ROTATION = (DEFAULT_ROTATION = (CURRENT_ROTATION = (vector)rot));
                        }
                        llMessageLinked(LINK_THIS, 90301, (string)SCRIPT_CHANNEL, command + "|" + pos + "|" + rot);
                    }
                    else
                    {
                        part0 = llGetSubString(part0, 0, 22);
                        if (command == "SEQUENCE")
                        {
                            command = "BUTTON";
                            part1 = "90210";
                        }
                        if (command == "POSE" || command == "SYNC" || command == "MENU" || command == "TOMENU" || command == "BUTTON")
                        {
                            if (command != "SYNC")
                            {
                                part0 = llGetSubString(command, 0, 0) + ":" + part0;
                            }
                            if (command == "MENU" || command == "TOMENU")
                            {
                                part0 += "*";
                            }
                            else if (command == "POSE" || command == "SYNC")
                            {
                                if (FIRST_POSENAME == "")
                                {
                                    FIRST_POSENAME = (CURRENT_POSE_NAME = part0);
                                    FIRST_ANIMATION_SEQUENCE = (CURRENT_ANIMATION_SEQUENCE = part1);
                                }
                                if (llList2String(parts, -1) == "M")
                                {
                                    MALE_POSENAME = part0;
                                    FIRST_MALE_ANIMATION_SEQUENCE = part1;
                                }
                                else if (llList2String(parts, -1) == "F")
                                {
                                    FEMALE_POSENAME = part0;
                                    FIRST_FEMALE_ANIMATION_SEQUENCE = part1;
                                }
                            }
                            else if (command == "BUTTON" && part1 == "")
                            {
                                part1 = "90200";
                            }
                            llMessageLinked(LINK_THIS, 90300, (string)SCRIPT_CHANNEL, part0 + "|" + part1);
                        }
                    }
                }
                notecard_query = llGetNotecardLine(notecard_name, ++reused_variable);
            }
        }
        else if (query_id == reused_key)
        {
            notecard_lines = (integer)data;
        }
    }
}
