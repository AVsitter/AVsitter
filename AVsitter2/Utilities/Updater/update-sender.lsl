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
 * Simple script used for updating a large number of furniture items at once
 * This script goes in a "sender" prim along with the latest copies of the 
 * (not running) scripts and inventory objects (e.g. prop objects) 
 * Touching the sender will shout in a radius and update all prims that respond.
 */
 
integer pin = -29752;
string receiver_script = "update receiver (auto removing)";
list objects_to_update;
list objects_files;
integer menu_handle;
key av;
particles_on(key target)
{
     llParticleSystem([
     PSYS_PART_FLAGS, 0 | PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_EMISSIVE_MASK | PSYS_PART_TARGET_POS_MASK,
     PSYS_SRC_PATTERN, 0 | PSYS_SRC_PATTERN_DROP,
     PSYS_PART_START_ALPHA, 1.00000,
     PSYS_PART_END_ALPHA, 1,
     PSYS_PART_START_COLOR, <1, 0, 0>,
     PSYS_PART_END_COLOR, <0, 0, 1>,
     PSYS_PART_START_SCALE, <0.08, 0.2, 0>,
     PSYS_PART_END_SCALE, <0.08, 0.2, 0>,
     PSYS_PART_MAX_AGE, 2.0,
     PSYS_SRC_MAX_AGE, 0,
     PSYS_SRC_ACCEL, <0, 0, 0>,
     PSYS_SRC_BURST_PART_COUNT, 250,
     PSYS_SRC_BURST_RADIUS, 0.00000,
     PSYS_SRC_BURST_RATE, 0.05766,
     PSYS_SRC_BURST_SPEED_MIN, 0.07813,
     PSYS_SRC_BURST_SPEED_MAX, 0.15625,
     PSYS_SRC_INNERANGLE, 0.09375,
     PSYS_SRC_OUTERANGLE, 0.00000,
     PSYS_SRC_OMEGA, <0, 0, 0>,
     PSYS_SRC_TEXTURE, (key)"",
     PSYS_SRC_TARGET_KEY, target
     ]);
}
default
{
    state_entry()
    {
        llParticleSystem([]);
        llListen(pin, "", "", "");
    }
    on_rez(integer x)
    {
        llResetScript();
    }
    timer()
    {
        llRegionSayTo(av, 0, "Found " + (string)llGetListLength(objects_to_update) + " objects...");
        integer i;
        for (i = 0; i < llGetListLength(objects_to_update); i++)
        {
            key object = llList2Key(objects_to_update, i);
            list items = llParseStringKeepNulls(llList2String(objects_files, i), ["|"], []);
            if (1 == 1)
            {
                list scripts_to_update;
                list other_to_update;
                list surplus_to_update;
                integer j;
                for (j = 0; j < llGetListLength(items); j = j + 2)
                {
                    string item = llList2String(items, j);
                    key item_key = (key)llList2String(items, j + 1);
                    if (item_key != llGetInventoryKey(item) || item_key == NULL_KEY)
                    {
                        if (llGetInventoryType(item) == INVENTORY_SCRIPT)
                        {
                            scripts_to_update += item;
                        }
                        else
                        {
                            other_to_update += item;
                        }
                    }
                    else if (llGetInventoryType(item) == INVENTORY_OBJECT)
                    {
                        surplus_to_update += item;
                    }
                }
                if (llGetListLength(scripts_to_update) == 0 && llGetListLength(other_to_update) == 0)
                {
                }
                else
                {
                    particles_on(object);
                    if (llGetListLength(other_to_update) > 0)
                    {
                        if (llListFindList(scripts_to_update, [receiver_script]) == -1)
                        {
                            scripts_to_update += receiver_script;
                        }
                    }
                    if (llListFindList(scripts_to_update, [receiver_script]) != -1)
                    {
                        other_to_update += surplus_to_update;
                    }
                    for (j = 0; j < llGetListLength(scripts_to_update); j++)
                    {
                        llRegionSayTo(av, 0, "Sending: " + llList2String(scripts_to_update, j) + " to " + llKey2Name(object));
                        integer running = TRUE;
                        if (llSubStringIndex(llKey2Name(object), "[BOX]") != -1 && llList2String(scripts_to_update, j) != receiver_script)
                        {
                            running = FALSE; // set scripts not running if the target name contains [BOX]
                        }
                        integer remove_objects = -1;
                        if (llGetListLength(surplus_to_update))
                        {
                            remove_objects = -1;
                        }
                        llRemoteLoadScriptPin(object, llList2String(scripts_to_update, j), pin, running, remove_objects);
                    }
                    for (j = 0; j < llGetListLength(other_to_update); j++)
                    {
                        llRegionSayTo(av, 0, "Sending: " + llList2String(other_to_update, j) + " to " + llKey2Name(object));
                        llGiveInventory(object, llList2String(other_to_update, j));
                    }
                }
            }
            else
            {
                llRemoteLoadScriptPin(object, receiver_script, pin, TRUE, -1);
            }
        }
        llRegionSayTo(av, 0, "Updating Complete!");
        llResetScript();
    }
    touch_start(integer touched)
    {
        if (llDetectedKey(0) == llGetOwner() || llSameGroup(llDetectedKey(0)))
        {
            av = llDetectedKey(0);
            objects_to_update = [];
            objects_files = [];
            llSetTimerEvent(10);
            list items;
            integer i;
            for (i = 0; i < llGetInventoryNumber(INVENTORY_ALL); i++)
            {
                if (llGetInventoryName(INVENTORY_ALL, i) != llGetScriptName())
                {
                    items += llGetInventoryName(INVENTORY_ALL, i);
                }
            }
            llRegionSayTo(av, 0, "listening...");
            llSay(pin, "OBJECT_SEARCH|" + llDumpList2String(items, "|"));
        }
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (llGetOwnerKey(id) == llGetOwner())
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            if (llList2String(data, 0) == "OBJECT_HERE")
            {
                vector mysize = llGetScale();
                float distance = llVecMag(llGetPos() - llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0));
                if (distance <= mysize.x / 2)
                {
                    objects_to_update += id;
                    objects_files += llDumpList2String(llList2List(data, 1, -1), "|");
                }
            }
        }
    }
}
