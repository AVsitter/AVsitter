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
 
string product;
string version = "2.2";
integer RELAY_CHANNEL = -1812221819;
integer RELAY_GETSTATUS_CHANNEL;
integer GETSTATUShandle;
integer menu_channel;
integer menu_handle;
key CONTROLLER = "";
string controllerName;
key SLAVE;
string menu;
integer menuPage;
list folderPath;
list folderOptions;
list folderNamesFullLength;
list CLOTHING_LAYERS = ["gloves", "jacket", "pants", "shirt", "shoes", "skirt", "socks", "underpants", "undershirt", "", "", "", "", "alpha", "tattoo"];
list ATTACHMENT_POINTS = ["", "chest", "skull", "left shoulder", "right shoulder", "left hand", "right hand", "left foot", "right foot", "spine", "pelvis", "mouth", "chin", "left ear", "right ear", "left eyeball", "right eyeball", "nose", "r upper arm", "r forearm", "l upper arm", "l forearm", "right hip", "r upper leg", "r lower leg", "left hip", "l upper leg", "l lower leg", "stomach", "left pec", "right pec", "", "", "", "", "", "", "", "", "neck", "root"];
list RLV_RESTRICTIONS = ["Chat", "sendchat", "sending chat", "IM", "sendim", "sending IM", "Touch", "touchall", "touching", "Names", "shownames", "seeing names", "Rez/Edit", "edit,rez", "editing and rezzing objects", "Inventory", "showinv", "accessing their inventory", "Map", "showworldmap,showminimap", "seeing their map", "Location", "showloc", "seeing their location"];
string iconActive = "✘ ";
string iconInactive = "✔ ";
string iconEmpty = "○";
string iconHalf = "◑";
string iconFull = "●";
string iconAdd = "[➕]";
string iconSubtract = "[➖]";
string pagedMenuText;
list pagedMenuButtons;
integer verbose = 0;
Out(integer level, string out)
{
    if (verbose >= level)
    {
        llOwnerSay(llGetScriptName() + "[" + version + "]:" + out);
    }
}
string strReplace(string str, string search, string replace)
{
    return llDumpList2String(llParseStringKeepNulls(str, [search], []), replace);
}
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
relay(key av, string msg)
{
    msg = "RLV," + (string)av + "," + msg;
    Out(1, "Sending RLV Command: " + msg);
    llSay(RELAY_CHANNEL, msg);
}
remove_menu(string worn, list slots)
{
    list menu_items;
    Out(1, "remove menu:" + worn + ":" + llDumpList2String(slots, ","));
    integer i;
    for (i = 0; i < llGetListLength(slots); i++)
    {
        if (llList2String(slots, i) != "" && llGetSubString(worn, i, i) == "1")
        {
            menu_items += llList2String(slots, i);
        }
    }
    Out(1, "remove menu2:" + llDumpList2String(menu_items, ","));
    string text = "'s RLV setup may prevent some items from being removed.\n\nSelect an item to remove:";
    if (!llGetListLength(menu_items))
    {
        text = " is not wearing any items to " + llToLower(menu) + ".";
    }
    new_paged_menu(menu + " menu for " + llKey2Name(SLAVE) + "\n\nThe captive" + text, menu_items);
}
new_paged_menu(string text, list menu_items)
{
    pagedMenuText = text;
    pagedMenuButtons = menu_items;
    menuPage = 0;
    paged_menu();
}
paged_menu()
{
    list MypagedMenuButtons = pagedMenuButtons;
    if (llGetListLength(pagedMenuButtons) > 11)
    {
        integer numberPages = llGetListLength(pagedMenuButtons) / 9;
        if (llGetListLength(pagedMenuButtons) % 9)
        {
            numberPages++;
        }
        if (menuPage >= numberPages)
        {
            menuPage = 0;
        }
        else if (menuPage < 0)
        {
            menuPage = numberPages - 1;
        }
        MypagedMenuButtons = llList2List(pagedMenuButtons, menuPage * 9, menuPage * 9 + 8);
        while (llGetListLength(MypagedMenuButtons) < 9)
        {
            MypagedMenuButtons += " ";
        }
        MypagedMenuButtons += ["[<<]", "[>>]"];
    }
    Out(1, "paged menu:" + llDumpList2String(MypagedMenuButtons, ","));
    dialog(pagedMenuText, ["[BACK]"] + MypagedMenuButtons);
}
dialog(string text, list buttons)
{
    while (llGetListLength(buttons) % 3)
        buttons += " ";
    llDialog(CONTROLLER, "AVsitter™ RLV " + product + " " + version + "\n\n" + text, order_buttons(buttons), menu_channel);
}
remove_script(string reason)
{
    string message = "\n" + llGetScriptName() + " ==Script Removed==\n\n" + reason;
    llDialog(llGetOwner(), message, ["OK"], -3675);
    llInstantMessage(llGetOwner(), message);
    llRemoveInventory(llGetScriptName());
}
main_menu()
{
    menu = "";
    dialog("Un/Dress menu for " + llKey2Name(SLAVE), ["[BACK]", "Browse #RLV", "Fast Strip", "Undress", "Detach"]);
}
default
{
    state_entry()
    {
        if (llSubStringIndex(llGetScriptName(), " ") != -1)
        {
            remove_script("Use only one copy of this script!");
        }
        else
        {
            state running;
        }
    }
}
state running
{
    state_entry()
    {
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == 90208 || num == 90209)
        {
            list data = llParseStringKeepNulls(id, ["|"], []);
            SLAVE = (key)llList2String(data, 0);
            CONTROLLER = (key)llList2String(data, 1);
            product = llList2String(data, 2);
            llListenRemove(menu_handle);
            llListenRemove(GETSTATUShandle);
            menu_handle = llListen(menu_channel = ((integer)llFrand(2147483646) + 1) * -1, "", CONTROLLER, "");
            GETSTATUShandle = llListen(RELAY_GETSTATUS_CHANNEL = (integer)llFrand(999999999), "", "", "");
            if (num == 90208)
            {
                main_menu();
            }
            else
            {
                menu = "Restrict";
                relay(SLAVE, "@getstatus=" + (string)RELAY_GETSTATUS_CHANNEL);
            }
        }
        else if (num == 90065)
        {
            if (id == SLAVE)
            {
                llListenRemove(menu_handle);
                llListenRemove(GETSTATUShandle);
                SLAVE = "";
            }
        }
    }
    listen(integer channel, string name, key id, string msg)
    {
        Out(1, "Listen Received: " + msg);
        string command;
        if (channel == menu_channel)
        {
            if (msg == "[>>]" || msg == "[<<]")
            {
                if (msg == "[<<]")
                {
                    menuPage--;
                }
                else
                {
                    menuPage++;
                }
                paged_menu();
            }
            else if (menu == "Browse #RLV")
            {
                integer index = llListFindList(folderOptions, [msg]);
                if (~index)
                {
                    msg = llList2String(folderNamesFullLength, index);
                    folderPath += msg;
                    relay(SLAVE, "@getinvworn:" + llDumpList2String(folderPath, "/") + "=" + (string)RELAY_GETSTATUS_CHANNEL);
                }
                else if (msg == "[BACK]")
                {
                    if (!llGetListLength(folderPath))
                    {
                        main_menu();
                    }
                    else
                    {
                        folderPath = llDeleteSubList(folderPath, -1, -1);
                        relay(SLAVE, "@getinvworn:" + llDumpList2String(folderPath, "/") + "=" + (string)RELAY_GETSTATUS_CHANNEL);
                    }
                }
                else if (msg == iconAdd || msg == iconSubtract)
                {
                    command = "attach";
                    if (msg == iconSubtract)
                    {
                        command = "detach";
                    }
                    relay(SLAVE, "@" + command + ":" + llDumpList2String(folderPath, "/") + "=force");
                    llSleep(4);
                    relay(SLAVE, "@getinvworn:" + llDumpList2String(folderPath, "/") + "=" + (string)RELAY_GETSTATUS_CHANNEL);
                }
            }
            else if (msg == "[BACK]")
            {
                if (menu == "Restrict" || menu == "")
                {
                    llMessageLinked(LINK_THIS, 90100, "0|Control...|" + (string)SLAVE, CONTROLLER);
                }
                else
                {
                    main_menu();
                }
            }
            else if (menu == "Detach" || menu == "Undress")
            {
                integer index = llListFindList(CLOTHING_LAYERS, [msg]);
                command = "outfit";
                if (!~index)
                {
                    index = llListFindList(ATTACHMENT_POINTS, [msg]);
                    command = "attach";
                }
                if (~index)
                {
                    relay(SLAVE, "@rem" + command + ":" + msg + "=force");
                    llSleep(2);
                    relay(SLAVE, "@get" + command + "=" + (string)RELAY_GETSTATUS_CHANNEL);
                }
            }
            else if (msg == "Detach" || msg == "Undress" || msg == "Browse #RLV")
            {
                menu = msg;
                folderPath = [];
                command = "getoutfit";
                if (msg == "Detach")
                    command = "getattach";
                if (msg == "Browse #RLV")
                    command = "getinvworn";
                relay(SLAVE, "@" + command + "=" + (string)RELAY_GETSTATUS_CHANNEL);
            }
            else if (msg == "Fast Strip")
            {
                menu = "fs";
                dialog("Are you really sure? This will try to remove almost everything the avatar is wearing.", ["[BACK]", "YES!"]);
            }
            else if (msg == "YES!")
            {
                integer i;
                for (i = 0; i < llGetListLength(CLOTHING_LAYERS); i++)
                {
                    if (llList2String(CLOTHING_LAYERS, i))
                    {
                        relay(SLAVE, "@remoutfit:" + llList2String(CLOTHING_LAYERS, i) + "=force");
                    }
                }
                for (i = 0; i < llGetListLength(ATTACHMENT_POINTS); i++)
                {
                    if (llList2String(ATTACHMENT_POINTS, i))
                    {
                        if (i != 2)
                        {
                            relay(SLAVE, "@remattach:" + llList2String(ATTACHMENT_POINTS, i) + "=force");
                        }
                    }
                }
                main_menu();
            }
            else
            {
                integer index = llListFindList(llList2ListStrided(RLV_RESTRICTIONS, 0, -1, 3), [llList2String(llParseString2List(msg, [" "], []), 1)]);
                if (~index)
                {
                    list subRestrictions = llParseString2List(llList2String(RLV_RESTRICTIONS, index * 3 + 1), [","], []);
                    string param = "n";
                    string chatText = strReplace(llKey2Name(SLAVE), " Resident", "") + " is ";
                    if (~llSubStringIndex(msg, iconActive))
                    {
                        param = "y";
                        chatText += "no longer ";
                    }
                    integer i;
                    while (i < llGetListLength(subRestrictions))
                    {
                        relay(SLAVE, "@" + llList2String(subRestrictions, i) + "=" + param);
                        i++;
                    }
                    llSay(0, chatText + "restricted from " + llList2String(RLV_RESTRICTIONS, index * 3 + 2) + ".");
                    relay(SLAVE, "@getstatus=" + (string)RELAY_GETSTATUS_CHANNEL);
                }
            }
        }
        else if (channel == RELAY_GETSTATUS_CHANNEL)
        {
            if (menu == "Browse #RLV")
            {
                folderOptions = [];
                folderNamesFullLength = [];
                list BUTTONS;
                list results = llParseStringKeepNulls(msg, [","], []);
                string folderInfo;
                string subInfo;
                integer i;
                for (i = 0; i < llGetListLength(results); i++)
                {
                    list item = llParseStringKeepNulls(llList2String(results, i), ["|"], []);
                    string folder = llList2String(item, 0);
                    integer worn = llList2Integer(item, 1);
                    integer wornThis = worn / 10;
                    integer wornSub = worn % 10;
                    string icon = "no items";
                    if (i)
                    {
                        if (wornThis || wornSub)
                        {
                            icon = iconEmpty;
                            if (wornThis > 1 || wornSub > 1)
                            {
                                icon = iconHalf;
                            }
                            if (wornThis == 3 && wornSub == 0 || (wornThis == 0 && wornSub == 3) || (wornThis == 3 && wornSub == 3))
                            {
                                icon = iconFull;
                            }
                            folderOptions += icon + " " + llGetSubString(folder, 0, 12);
                            folderNamesFullLength += folder;
                            subInfo = "\nSubfolders:\n" + iconEmpty + " = none worn\n" + iconHalf + " = some worn\n" + iconFull + " = all worn";
                        }
                    }
                    else
                    {
                        if (wornThis)
                        {
                            icon = "none worn";
                            if (wornThis == 2)
                            {
                                icon = "some worn";
                            }
                            if (wornThis == 3)
                            {
                                icon = "all worn";
                            }
                            BUTTONS += [iconAdd, iconSubtract];
                            folderInfo = "\n" + iconAdd + " = wear\n" + iconSubtract + " = remove\n";
                        }
                        msg = "Folder: /" + llDumpList2String(folderPath, "/") + "\n[" + icon + "]\n" + folderInfo;
                    }
                }
                if ((!llGetListLength(folderOptions)) && (!llGetListLength(BUTTONS)))
                {
                    msg = "#RLV folder empty";
                }
                new_paged_menu(msg + subInfo, BUTTONS + folderOptions);
            }
            else if (menu == "Detach")
            {
                remove_menu(msg, ATTACHMENT_POINTS);
            }
            else if (menu == "Undress")
            {
                remove_menu(msg, CLOTHING_LAYERS);
            }
            else if (menu == "Restrict")
            {
                list currentRestrictions = llParseString2List(msg, ["/"], []);
                list menu_items = ["[BACK]"];
                integer i;
                while (i < llGetListLength(RLV_RESTRICTIONS))
                {
                    list subRestrictions = llParseString2List(llList2String(RLV_RESTRICTIONS, i + 1), [","], []);
                    integer inActive;
                    integer j;
                    while (j < llGetListLength(subRestrictions))
                    {
                        if (!~llListFindList(currentRestrictions, [llList2String(subRestrictions, j)]))
                        {
                            inActive = TRUE;
                        }
                        j++;
                    }
                    string symbol = iconInactive;
                    if (!inActive)
                    {
                        symbol = iconActive;
                    }
                    string btntext = symbol + llList2String(RLV_RESTRICTIONS, i);
                    while (llStringLength(btntext) < 20)
                        btntext += " ";
                    btntext += ".";
                    menu_items += btntext;
                    i += 3;
                }
                dialog("RLV for " + llKey2Name(SLAVE) + "\n\n" + iconInactive + "= Allowed\n" + iconActive + "= Restricted", menu_items);
            }
        }
    }
}
