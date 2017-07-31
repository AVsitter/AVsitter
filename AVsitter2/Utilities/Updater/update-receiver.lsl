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
 * This script goes in each furniture prim that expects an update from the sender
 * will auto-delete if a non-admin avatar rezzes the furniture 
 */
 
integer pin = -29752;
list admin_avatars = ["b30c9262-9abf-4cd1-9476-adcf5723c029", "f2e0ed5e-6592-4199-901d-a659c324ca94"];
default
{
    state_entry()
    {
        llSetTimerEvent(0.1);
        if (llGetStartParameter() == -1)
        {
            integer i;
            while (llGetInventoryNumber(INVENTORY_OBJECT))
            {
                string item = llGetInventoryName(INVENTORY_OBJECT, llGetInventoryNumber(INVENTORY_OBJECT) - 1);
                llRegionSayTo(llGetOwner(), 0, "Removing :" + item);
                llRemoveInventory(item);
            }
        }
        llSetRemoteScriptAccessPin(pin);
        llListen(pin, "", "", "");
    }
    timer()
    {
        if (llGetLinkNumber() == 0 || llGetLinkNumber() == 1 && llGetInventoryType("[AV]object") != INVENTORY_SCRIPT)
        {
            if (llGetAgentSize(llGetLinkKey(llGetNumberOfPrims())) == ZERO_VECTOR)
            {
                llSetText(llGetObjectName(), <1,1,0>, 1);
            }
        }
        llSetTimerEvent(10);
    }
    on_rez(integer start)
    {
        if (start)
        {
            if (~llListFindList(admin_avatars, [llGetOwner()]))
            {
                llRegionSayTo(llGetOwner(), 0, "Removing :" + llGetScriptName());
            }
            llRemoveInventory(llGetScriptName());
        }
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (llGetOwnerKey(id) == llGetOwner())
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            if (llList2String(data, 0) == "OBJECT_SEARCH")
            {
                list reply;
                integer i;
                for (i = 1; i < llGetListLength(data); i++)
                {
                    if (llGetInventoryType(llList2String(data, i)) != INVENTORY_NONE)
                    {
                        reply += [llList2String(data, i), (string)llGetInventoryKey(llList2String(data, i))];
                    }
                }
                if (llGetListLength(reply) > 0)
                {
                    llRegionSay(pin, "OBJECT_HERE|" + llDumpList2String(reply, "|"));
                }
            }
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            if (!llListFindList(admin_avatars, [llGetOwner()]))
            {
                llRemoveInventory(llGetScriptName());
            }
        }
    }
}
