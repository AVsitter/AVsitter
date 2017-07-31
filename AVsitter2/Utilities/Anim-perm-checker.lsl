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
 
Owner_Say(string say)
{
    llOwnerSay(llGetScriptName() + ": " + say);
}
default
{
    state_entry()
    {
        integer copy_trans_count;
        integer copy_count;
        integer trans_count;
        Owner_Say(" ");
        Owner_Say("================================");
        integer total = llGetInventoryNumber(INVENTORY_ANIMATION);
        Owner_Say("Checking NEXT_OWNER permissions of ANIMATIONS.");
        integer i;
        for (i = 0; i < total; i++)
        {
            string item = llGetInventoryName(INVENTORY_ANIMATION, i);
            integer perms = llGetInventoryPermMask(item, MASK_NEXT);
            if (perms & PERM_COPY)
            {
                if (perms & PERM_TRANSFER)
                {
                    Owner_Say(item + " is COPY-TRANSFER!");
                    copy_trans_count++;
                }
                else
                {
                    copy_count++;
                }
            }
            else if (perms & PERM_TRANSFER)
            {
                trans_count++;
            }
        }
        Owner_Say((string)total + " anims total");
        Owner_Say((string)trans_count + " anims are TRANSFER");
        Owner_Say((string)copy_count + " anims are COPY.");
        Owner_Say((string)copy_trans_count + " anims are COPY-TRANSFER!");
        Owner_Say("Check complete, removing script.");
        Owner_Say("================================");
        Owner_Say(" ");
        if (llSubStringIndex(llGetObjectName(), "Utilities") == -1) // remove it except from Utilities box
        {
            llRemoveInventory(llGetScriptName());
        }
    }
}
