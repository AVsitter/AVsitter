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
 
string base_object_name = "AVhelper";
string instructions = "Please see instructions for using the AVhelper.";
list colors = [<1,0.5,1>, <0.5,1,1>, <1,1,0.5>, <1,0.5,0.5>, <0.5,0.5,1>, <0.5,1,0.5>];
integer start_param;
integer click_registered = FALSE;
integer comm_channel;
key av = NULL_KEY;
vector ball_size = <0.2,0.2,0.2>;
vector default_size = <0.2,0.2,3.5>;
stop_all_anims()
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
set_text()
{
    string text = "▽";
    integer i;
    for (i = 0; i < start_param; i++)
    {
        text += "\n ";
    }
    text = "SITTER " + (string)start_param + "\n" + text;
    integer hovertext_prim = 0;
    if (llGetNumberOfPrims() > 1)
    {
        if (llGetAgentSize(llGetLinkKey(2)) == ZERO_VECTOR)
        {
            hovertext_prim = 2;
            text += "\n \n \n \n \n \n \n \n \n ";
        }
    }
    llSetLinkPrimitiveParamsFast(hovertext_prim, [PRIM_TEXT, text, llList2Vector(colors, start_param % llGetListLength(colors)), 1]);
}
setup()
{
    vector size = default_size;
    if (llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_CREATOR]), 0) != llGetInventoryCreator(llGetScriptName()))
    {
        size = llGetScale();
    }
    integer i;
    for (i = 0; i < start_param; i++)
    {
        size -= <0.01,0.01,0.01>;
    }
    set_text();
    llSetObjectName(base_object_name + " " + (string)start_param);
    llSetPrimitiveParams([PRIM_COLOR, ALL_SIDES, llList2Vector(colors, start_param % llGetListLength(colors)), 0.4, PRIM_SIZE, size]);
    llRegionSay(comm_channel, "REG|" + (string)start_param);
}
warp(vector pos)
{
    list rules;
    integer num = llCeil(llVecDist(llGetPos(), pos) / 10);
    while (num--)
        rules = (rules = []) + rules + [PRIM_POSITION, pos];
    llSetPrimitiveParams(rules);
}
default
{
    state_entry()
    {
        llSetText("", <1,1,1>, 1);
        llSetObjectName(base_object_name);
        llSetPrimitiveParams([PRIM_TEXTURE, ALL_SIDES, "5748decc-f629-461c-9a36-a35a221fe21f", <1,1,0>, <0,0,0>, 0, PRIM_FULLBRIGHT, ALL_SIDES, TRUE, PRIM_COLOR, ALL_SIDES, llList2Vector(colors, 0), 0.4, PRIM_GLOW, ALL_SIDES, 0.03]);
        integer everyonePerms = llGetObjectPermMask(MASK_EVERYONE);
        if ((!(everyonePerms & PERM_MOVE)) && llGetOwner() == llGetInventoryCreator(llGetScriptName()))
        {
            llOwnerSay("WARNING! AVhelper should se set to 'Anyone Can Move'");
        }
        llSetTimerEvent(604800);
        llSitTarget(-<0,0,0.35>, ZERO_ROTATION);
        llSetStatus(STATUS_PHANTOM, TRUE);
    }
    on_rez(integer x)
    {
        if (x != 0)
        {
            llSetClickAction(CLICK_ACTION_SIT);
            start_param = x % 1000 * -1;
            comm_channel = x + start_param;
            llListen(comm_channel, "", "", "");
            setup();
        }
        else
        {
            llSetClickAction(CLICK_ACTION_TOUCH);
            llSetText("", <1,1,1>, 1);
            if (llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_CREATOR]), 0) == llGetInventoryCreator(llGetScriptName()))
            {
                llSetPrimitiveParams([PRIM_SIZE, ball_size]);
            }
        }
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (llGetOwnerKey(id) == llGetOwner())
        {
            list data = llParseString2List(msg, ["|"], []);
            if (llList2String(data, 0) == "DONE" && llList2Integer(data, 1) == start_param || llList2String(data, 0) == "DONEA")
            {
                if (av)
                {
                    stop_all_anims();
                    llRegionSay(comm_channel, "GETUP|" + (string)start_param + "|" + (string)av);
                }
                llDie();
            }
            else if (llList2String(data, 0) == "SWAP")
            {
                if (llList2Integer(data, 1) == start_param)
                {
                    start_param = llList2Integer(data, 2);
                    setup();
                }
                else if (llList2Integer(data, 2) == start_param)
                {
                    start_param = llList2Integer(data, 1);
                    setup();
                }
            }
            else if (llList2Integer(data, 1) == start_param)
            {
                if (llList2String(data, 0) == "POS")
                {
                    vector pos = (vector)llList2String(data, 2);
                    rotation rot = (rotation)llList2String(data, 3);
                    llSetPrimitiveParams([PRIM_POSITION, pos, PRIM_ROTATION, rot]);
                    if (llGetPos() != pos)
                    {
                        warp(pos);
                    }
                    set_text();
                }
            }
            else if (llList2String(data, 0) == "ANIMA" && llList2Key(data, 2) == llAvatarOnSitTarget())
            {
                llUnSit(llAvatarOnSitTarget());
            }
        }
    }
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStopAnimation("sit");
        }
    }
    timer()
    {
        llDie();
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (comm_channel != 0)
            {
                if (llAvatarOnSitTarget())
                {
                    llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
                    av = llAvatarOnSitTarget();
                    llRegionSay(comm_channel, "ANIMA|" + (string)start_param + "|" + (string)llAvatarOnSitTarget());
                }
                else
                {
                    stop_all_anims();
                    av = NULL_KEY;
                    llRegionSay(comm_channel, "GETUP|" + (string)start_param + "|" + (string)av);
                }
            }
            else
            {
                if (llAvatarOnSitTarget())
                {
                    llInstantMessage(llAvatarOnSitTarget(), instructions);
                    llUnSit(llAvatarOnSitTarget());
                }
            }
        }
    }
    touch_start(integer total_number)
    {
        if (llGetStartParameter() != 0)
        {
            if (llAvatarOnSitTarget() == NULL_KEY)
            {
                llRegionSay(comm_channel, "ANIMA|" + (string)start_param + "|" + (string)llDetectedKey(0));
            }
            else if (llAvatarOnSitTarget() == llDetectedKey(0))
            {
                llRegionSay(comm_channel, "MENU|" + (string)start_param + "|" + (string)llDetectedKey(0));
            }
        }
        else
        {
            llInstantMessage(llDetectedKey(0), instructions);
        }
    }
}
