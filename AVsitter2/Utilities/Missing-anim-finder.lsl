/*
 * Missing-anim-finder - Finds missing or unused animations
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright © the AVsitter Contributors (http://avsitter.github.io)
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
list ALL_USED_ANIMS = [notecard_query]; //OSS::list ALL_USED_ANIMS; // Force error in LSO
list UNUSED_ANIMS;
integer NOT_FOUND_COUNT;
integer IS_VARIABLE_SPEED_SUBMENU;
list VARIABLE_SPEED_ANIMS;

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
        ALL_USED_ANIMS = [];
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
                if(!NOT_FOUND_COUNT){
                    Owner_Say("All anims referenced in the notecard were accounted for.");
                }
                else{
                    Owner_Say("Anims were used in the notecard but not found in inventory!");
                }
                integer i;
                for (i = 0; i < llGetInventoryNumber(INVENTORY_ANIMATION); i++)
                {
                    integer index;
                    integer isVariableSpeed;
                    string anim_basename = llGetInventoryName(INVENTORY_ANIMATION, i);

                    if(llListFindList(["+","-"], [llGetSubString(anim_basename, -1, -1)]) != -1)
                    {
                        index = llListFindList(ALL_USED_ANIMS, [llDeleteSubString(anim_basename,-1,-1)]);
                        // only consider anims as variable-speed if their base name was used in a variable-speed submenu:
                        if(index!=-1 && llList2Integer(VARIABLE_SPEED_ANIMS,index) == TRUE)
                        {
                            anim_basename = llDeleteSubString(anim_basename,-1,-1);
                            isVariableSpeed=TRUE;
                        }
                    }

                    index = llListFindList(ALL_USED_ANIMS, [anim_basename]);

                    if (index == -1 && llGetInventoryName(INVENTORY_ANIMATION, i) != "AVhipfix")
                    {
                        Owner_Say("Animation '" + llGetInventoryName(INVENTORY_ANIMATION, i) + "' found in inventory but not used in notecard!");
                        UNUSED_ANIMS += llGetInventoryName(INVENTORY_ANIMATION, i);
                    }
                }
                if (llGetListLength(UNUSED_ANIMS))
                {
                    llDialog(llGetOwner(), "\n" + (string)llGetListLength(UNUSED_ANIMS) + " unused (surplus) anims were found. Do you want to delete them?\n\nMake sure you take a backup of your work first!", ["YES", "NO"], -268534);
                    llListen(-268534, "", llGetOwner(), "");
                    llSetTimerEvent(60);
                }
                else
                {
                    Owner_Say("No unused anims were found!");
                    finish();
                }
            }
            else
            {
                data = llGetSubString(data, llSubStringIndex(data, "◆") + 1, 99999);
                data = llStringTrim(data, STRING_TRIM);
                string command = llGetSubString(data, 0, llSubStringIndex(data, " ") - 1);
                list parts = llParseString2List(llGetSubString(data, llSubStringIndex(data, " ") + 1, 99999), [" | ", " |", "| ", "|"], []);
                if (command == "POSE" || command == "SYNC")
                {
                    list anims = llList2ListStrided(llDeleteSubList(parts, 0, 0), 0, -1, 2);
                    integer i;
                    for (i = 0; i < llGetListLength(anims); i++)
                    {
                        if (llGetInventoryType(llList2String(anims, i)) != INVENTORY_ANIMATION)
                        {
                            NOT_FOUND_COUNT += 1;
                            Owner_Say("Animation '" + llList2String(anims, i) + "' not found in inventory!");
                        }
                        if(IS_VARIABLE_SPEED_SUBMENU)
                        {
                            if (llGetInventoryType(llList2String(anims, i)+"+") != INVENTORY_ANIMATION)
                            {
                                Owner_Say("Variable-Speed Animation '" + llList2String(anims, i) + "+' not found in inventory!");
                            }
                            if (llGetInventoryType(llList2String(anims, i)+"-") != INVENTORY_ANIMATION)
                            {
                                Owner_Say("Variable-Speed Animation '" + llList2String(anims, i) + "-' not found in inventory!");
                            }
                        }

                        integer index = llListFindList(ALL_USED_ANIMS,[llList2String(anims, i)]);
                        if(index == -1){ //only add to the list if the anim has not appeared before
                            ALL_USED_ANIMS += llList2String(anims, i);
                            VARIABLE_SPEED_ANIMS += IS_VARIABLE_SPEED_SUBMENU;
                        }
                        else if(IS_VARIABLE_SPEED_SUBMENU == TRUE){
                            // prevent variable-Speed anims from being incorrectly tagged as surplus in cases where: they are included in multiple submenus/sitters and where only in some places the submenus aren't set as Variable-Speed submenus.
                            // ensure it stays TRUE if ANY of the submenus that the anim is used in are set as Variable-Speed submenus.
                            VARIABLE_SPEED_ANIMS=llListReplaceList(VARIABLE_SPEED_ANIMS,[TRUE],index,index);
                        }
                    }
                }
                else if (command == "MENU" || command == "SITTER")
                {
                    IS_VARIABLE_SPEED_SUBMENU=FALSE;
                    if(command == "MENU" && llList2String(parts,-1) == "V")
                    {
                        IS_VARIABLE_SPEED_SUBMENU=TRUE;
                    }
                }
                notecard_query = llGetNotecardLine(notecard_basename, ++variable1);
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
