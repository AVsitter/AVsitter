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
integer variable1;
key notecard_query;
list ALL_USED_ANIMATIONS;
list UNUSED_ANIMS;
Owner_Say(string say)
{
    llOwnerSay(llGetScriptName() + ": " + say);
}
finish()
{
    Owner_Say("Check complete, removing script.");
    Owner_Say("================================");
    Owner_Say(" ");
    if (llSubStringIndex(llGetObjectName(), "Utilities") == -1) // remove it except from Utilities box
    {
        llRemoveInventory(llGetScriptName());
    }
}
default
{
    state_entry()
    {
        if (llGetInventoryType(notecard_basename) == INVENTORY_NOTECARD)
        {
            Owner_Say(" ");
            Owner_Say("================================");
            Owner_Say("Checking for missing or unused anims.");
            notecard_query = llGetNotecardLine(notecard_basename, variable1);
        }
        else
        {
            Owner_Say(notecard_basename + " notecard not found. Removing '" + llGetScriptName() + "' from inventory.");
            if (llSubStringIndex(llGetObjectName(), "Utilities") == -1)
            {
                llRemoveInventory(llGetScriptName());
            }
        }
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_query)
        {
            if (data == EOF)
            {
                integer i;
                for (i = 0; i < llGetInventoryNumber(INVENTORY_ANIMATION); i++)
                {
                    if (llListFindList(ALL_USED_ANIMATIONS, [llGetInventoryName(INVENTORY_ANIMATION, i)]) == -1 && llListFindList(["AVhipfix"], [llGetInventoryName(INVENTORY_ANIMATION, i)]) == -1)
                    {
                        Owner_Say("Animation '" + llGetInventoryName(INVENTORY_ANIMATION, i) + "' found in inventory but not used in notecard!");
                        UNUSED_ANIMS += llGetInventoryName(INVENTORY_ANIMATION, i);
                    }
                }
                if (llGetListLength(UNUSED_ANIMS))
                {
                    llDialog(llGetOwner(), "\n" + (string)llGetListLength(UNUSED_ANIMS) + " unused anims were found. Do you want to delete them?\n\nMake sure you take a backup of your work first!", ["YES", "NO"], -268534);
                    llListen(-268534, "", llGetOwner(), "");
                    llSetTimerEvent(60);
                }
                else
                {
                    finish();
                }
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, -1);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseString2List(llGetSubString(data, llSubStringIndex(data, " ") + 1, -1), [" | ", " |", "| ", "|"], []);
                if (command == "POSE" || command == "SYNC")
                {
                    list anims = llList2ListStrided(llDeleteSubList(parts, 0, 0), 0, -1, 2);
                    integer i;
                    for (i = 0; i < llGetListLength(anims); i++)
                    {
                        if (llGetInventoryType(llList2String(anims, i)) != INVENTORY_ANIMATION)
                        {
                            Owner_Say("Animation '" + llList2String(anims, i) + "' not found in inventory!");
                        }
                        ALL_USED_ANIMATIONS += llList2String(anims, i);
                    }
                }
                notecard_query = llGetNotecardLine(notecard_basename, variable1 += 1);
            }
        }
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (msg == "YES")
        {
            integer i;
            for (i = 0; i < llGetListLength(UNUSED_ANIMS); i++)
            {
                if (llGetInventoryType(llList2String(UNUSED_ANIMS, i)) == INVENTORY_ANIMATION)
                {
                    llRemoveInventory(llList2String(UNUSED_ANIMS, i));
                    Owner_Say("Deleted unused anim: '" + llList2String(UNUSED_ANIMS, i) + "'");
                }
            }
        }
        finish();
    }
    timer()
    {
        Owner_Say("timeout");
        finish();
    }
}
