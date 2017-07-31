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
 
list sittarget_scripts;
default
{
    state_entry()
    {
        if (llGetInventoryType("AVsit") != INVENTORY_SCRIPT)
        {
            llSitTarget(<0,0,0.01>, ZERO_ROTATION);
            llMessageLinked(LINK_SET, 90190, "starget", "");
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90190 && msg == "starget" && llGetInventoryType("AVsit") != INVENTORY_SCRIPT)
        {
            if (llListFindList(sittarget_scripts, [sender]) == -1)
            {
                sittarget_scripts += sender;
                sittarget_scripts = llListSort(sittarget_scripts, 1, TRUE);
            }
        }
        if (num == 90180 && sender != llGetLinkNumber() && llGetInventoryType("AVsit") != INVENTORY_SCRIPT)
        {
            integer sender_channel = (integer)msg;
            list data = llParseString2List(id, ["|"], []);
            if (sender_channel - 1 == llListFindList(sittarget_scripts, [llGetLinkNumber()]))
            {
            	// this code attempts to set the orientation of the sittarget of the child prim to match the orientation of the first pose in that sitter's menu 
                list details = [OBJECT_POS, OBJECT_ROT];
                vector original_local_target_pos;
                rotation original_local_target_rot;
                original_local_target_pos = (vector)llList2String(data, 0) - <0,0,0.35>;
                original_local_target_rot = llEuler2Rot((vector)llList2String(data, 1) * DEG_TO_RAD);
                vector world_avsit_prim_pos = llList2Vector(llGetObjectDetails(llGetLinkKey(sender), [OBJECT_POS]), 0);
                vector local_avsit_prim_pos = (world_avsit_prim_pos - llGetRootPosition()) / llGetRootRotation();
                rotation local_avsit_prim_rot = original_local_target_rot;
                rotation localrot = ZERO_ROTATION;
                vector localpos = ZERO_VECTOR;
                if (llGetLinkNumber() > 1)
                {
                    localrot = llGetLocalRot();
                    localpos = llGetLocalPos();
                }
                vector final_local_target_pos = local_avsit_prim_pos + original_local_target_pos + <0,0,0.35>;
                rotation final_local_target_rot = original_local_target_rot / llGetRootRotation();
                vector my_target_pos = (final_local_target_pos - localpos) / localrot - <0,0,0.4>;
                rotation my_target_rot = original_local_target_rot / localrot;
                llSitTarget(my_target_pos, my_target_rot);
            }
        }
    }
}
