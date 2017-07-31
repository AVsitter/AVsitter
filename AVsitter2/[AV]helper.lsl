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
 
string registration_product = "AVsitter2";
string product = "AVhelper";
string version = "2.2";
integer OLD_HELPER_METHOD;
list colors = [<1,0.5,1>, <0.5,0.5,1>, <1,0.5,0.5>, <0.5,1,0.5>, <1,1,0.5>, <0.5,1,1>];
integer helper_index;
float alpha;
integer sitter_number;
key CURRENT_AV;
integer comm_channel;
string base_object_name = "[AV]helper";
vector ball_size = <0.2,0.2,0.2>;
vector default_size = <0.12,0.12,3.5>;
key key_request;
vector my_pos;
rotation my_rot;
stop_all_anims()
{
    if (llAvatarOnSitTarget())
    {
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
        {
            if (llGetAgentSize(llGetPermissionsKey()))
            {
                list anims = llGetAnimationList(llGetPermissionsKey());
                integer n;
                for (n = 0; n < llGetListLength(anims); n++)
                {
                    llStopAnimation(llList2String(anims, n));
                }
            }
        }
    }
}
set_text()
{
    string text = "▽";
    integer i;
    string t = "SITTER";
    if (llGetStartParameter() < -1000000000)
    {
        t = "PRIM";
    }
    for (i = 0; i < sitter_number % 5; i++)
    {
        text += "\n \n ";
    }
    text = t + " " + (string)helper_index + "\n" + text;
    llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_TEXT, text, llList2Vector(colors, helper_index % llGetListLength(colors)), 1]);
}
setup()
{
    alpha = llList2Float(llGetPrimitiveParams([PRIM_COLOR, 0]), 1);
    CURRENT_AV = "";
    vector size = default_size;
    if (llGetCreator() != llGetInventoryCreator(llGetScriptName()))
    {
        size = llGetScale();
    }
    integer i;
    for (i = 0; i < sitter_number; i++)
    {
        size -= <0.001,0.001,0.>;
    }
    set_text();
    llSetObjectName(base_object_name + " " + (string)helper_index);
    if (llGetCreator() == llGetInventoryCreator(llGetScriptName()))
    {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_DEFAULT, <0,1,0>, 0, ZERO_VECTOR, <1,1,0>, ZERO_VECTOR, PRIM_TEXTURE, ALL_SIDES, "5748decc-f629-461c-9a36-a35a221fe21f", <1,1,0>, ZERO_VECTOR, 0, PRIM_COLOR, ALL_SIDES, llList2Vector(colors, helper_index % llGetListLength(colors)), alpha, PRIM_COLOR, 1, <1,1,1>, alpha, PRIM_COLOR, 3, <1,1,1>, alpha, PRIM_SIZE, size]);
    }
    else
    {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_COLOR, ALL_SIDES, llList2Vector(colors, helper_index % llGetListLength(colors)), alpha, PRIM_SIZE, size]);
    }
    llRegionSay(comm_channel, "REG|" + (string)sitter_number);
}
default
{
    state_entry()
    {
        llSetText("", <1,1,1>, 1);
        llSetObjectName(base_object_name);
        if (llGetCreator() == llGetInventoryCreator(llGetScriptName()))
        {
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE, ALL_SIDES, "5748decc-f629-461c-9a36-a35a221fe21f", <1,1,0>, <0,0,0>, 0, PRIM_FULLBRIGHT, ALL_SIDES, TRUE, PRIM_COLOR, ALL_SIDES, llList2Vector(colors, 0), 0.7, PRIM_GLOW, ALL_SIDES, 0.]);
        }
        else
        {
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE, ALL_SIDES, "5748decc-f629-461c-9a36-a35a221fe21f", <1,1,0>, <0,0,0>, 0, PRIM_FULLBRIGHT, ALL_SIDES, TRUE]);
        }
        integer everyonePerms = llGetObjectPermMask(MASK_EVERYONE);
        if ((!(everyonePerms & PERM_MOVE)) && llGetOwner() == llGetInventoryCreator(llGetScriptName()))
        {
            llOwnerSay("WARNING! AVhelper should be set to 'Anyone Can Move'");
        }
        llSitTarget(-<0,0,0.35>, ZERO_ROTATION);
        llSetStatus(STATUS_PHANTOM, TRUE);
    }
    on_rez(integer start)
    {
        llResetTime();
        llSetClickAction(CLICK_ACTION_TOUCH);
        if (start == 0)
        {
            llSetTimerEvent(0);
            llSetText("", <1,1,1>, 1);
            if (llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_CREATOR]), 0) == llGetInventoryCreator(llGetScriptName()))
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_SIZE, ball_size]);
            }
        }
        else
        {
            helper_index = start % 1000 * -1;
            sitter_number = helper_index;
            if (start < -1000000000)
            {
                helper_index = (sitter_number = 0);
            }
            comm_channel = llFloor(start / 1000) * 1000;
            llListen(5, "", "", "");
            llListen(comm_channel, "", "", "");
            setup();
        }
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (chan == 5 && id == CURRENT_AV)
        {
            key av = (key)msg;
            if (av)
            {
                if (llGetAgentSize(av))
                {
                    list avatar_location = llGetObjectDetails(av, [OBJECT_POS, OBJECT_ROT]);
                    if (llVecMag(llGetPos() - llList2Vector(avatar_location, 0)) < 10)
                    {
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POSITION, llList2Vector(avatar_location, 0), PRIM_ROTATION, llList2Rot(avatar_location, 1)]);
                    }
                    else
                    {
                        llRegionSayTo(id, 0, "Avatar too far away.");
                    }
                }
                else
                {
                    llRegionSayTo(id, 0, "Avatar not found nearby.");
                }
            }
        }
        if (llGetOwnerKey(id) == llGetOwner())
        {
            list data = llParseString2List(msg, ["|"], []);
            if (llList2String(data, 0) == "DONE" && llList2Integer(data, 1) == sitter_number || llList2String(data, 0) == "DONEA")
            {
                if (OLD_HELPER_METHOD)
                {
                    if (llAvatarOnSitTarget())
                    {
                        stop_all_anims();
                        llRegionSay(comm_channel, "GETUP");
                    }
                }
                llDie();
            }
            else if (llList2String(data, 0) == "SWAP")
            {
                integer one = (integer)llList2String(data, 1);
                integer two = (integer)llList2String(data, 2);
                if (sitter_number == one)
                {
                    sitter_number = (helper_index = two);
                    setup();
                }
                else if (sitter_number == two)
                {
                    sitter_number = (helper_index = one);
                    setup();
                }
            }
            else if (llList2Integer(data, 1) == sitter_number)
            {
                if (llList2String(data, 0) == "POS")
                {
                    vector pos = (vector)llList2String(data, 2);
                    rotation rot = (rotation)llList2String(data, 3);
                    OLD_HELPER_METHOD = (integer)llList2String(data, 4);
                    CURRENT_AV = (key)llList2String(data, 5);
                    if (OLD_HELPER_METHOD)
                    {
                        llSetClickAction(CLICK_ACTION_SIT);
                    }
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POSITION, pos, PRIM_ROTATION, rot]);
                    if (llGetPos() != pos)
                    {
                        llSetRegionPos(pos);
                    }
                    my_pos = llGetPos();
                    my_rot = llGetRot();
                    llSetTimerEvent(0.01);
                }
            }
        }
    }
    timer()
    {
        if (my_pos != llGetPos() || my_rot != llGetRot())
        {
            my_pos = llGetPos();
            my_rot = llGetRot();
            llRegionSay(comm_channel, "MOVED|" + (string)sitter_number + "|" + (string)my_pos + "|" + (string)my_rot);
        }
        else if (llGetTime() > 86400) // auto-remove helper after 1 day
        {
            llDie();
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key av = llAvatarOnSitTarget();
            if (OLD_HELPER_METHOD)
            {
                if (av)
                {
                    llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
                    llRegionSay(comm_channel, "ANIMA|" + (string)av);
                }
                else
                {
                    stop_all_anims();
                    llRegionSay(comm_channel, "GETUP");
                    CURRENT_AV = "";
                }
            }
            else if (av)
            {
                llUnSit(av);
                llDialog(av, product + " " + version + "\n\nDo not sit on the helper with AVsitter2 unless you have enabled the old helper mode. Move the helper while sitting on the furniture. Please see instructions at http://avsitter.com", ["OK"], -68154283);
            }
        }
    }
    touch_start(integer total_number)
    {
        if (llGetStartParameter() != 0)
        {
            llRegionSay(comm_channel, "MENU|" + (string)llDetectedKey(0));
        }
    }
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStopAnimation("sit");
        }
    }
}
