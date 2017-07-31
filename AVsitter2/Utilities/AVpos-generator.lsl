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
 
string notecard_basename = "AVpos";
string name = "Anim";
Readout_Say(string say)
{
    llSleep(0.2);
    string objectname = llGetObjectName();
    llSetObjectName("");
    llRegionSayTo(llGetOwner(), 0, "◆" + say);
    llSetObjectName(objectname);
}
default
{
    state_entry()
    {
        if (llGetInventoryNumber(INVENTORY_ANIMATION) > 0)
        {
            Readout_Say("");
            Readout_Say("--✄--COPY BELOW INTO " + notecard_basename + " NOTECARD--✄--");
            Readout_Say("");
            integer i;
            for (i = 0; i < llGetInventoryNumber(INVENTORY_ANIMATION); i++)
            {
                Readout_Say("POSE " + name + (string)(i + 1) + "|" + llGetInventoryName(INVENTORY_ANIMATION, i));
            }
            Readout_Say("");
            Readout_Say("--✄--COPY ABOVE INTO " + notecard_basename + " NOTECARD--✄--");
            Readout_Say("");
            if (llSubStringIndex(llGetObjectName(), "Utilities") == -1) // remove it except from Utilities box
            {
                llOwnerSay("Removing " + llGetScriptName() + " script");
                llRemoveInventory(llGetScriptName());
            }
        }
    }
}
