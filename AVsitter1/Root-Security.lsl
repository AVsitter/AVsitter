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
 
list SECURITY_TYPES = ["ALL", "OWNER ONLY", "GROUP ONLY"];
integer security_index;
integer pass_security(key id)
{
    integer access_allowed = FALSE;
    string SECURITY_TYPE = llList2String(SECURITY_TYPES, security_index);
    if (SECURITY_TYPE == "ALL")
    {
        access_allowed = TRUE;
    }
    else if (SECURITY_TYPE == "GROUP ONLY" && llSameGroup(id) == TRUE)
    {
        access_allowed = TRUE;
    }
    else if (id == llGetOwner())
    {
        access_allowed = TRUE;
    }
    return access_allowed;
}
default
{
    touch_end(integer touched)
    {
        if (pass_security(llDetectedKey(0)) == TRUE)
        {
            llMessageLinked(LINK_SET, 90005, "", llDetectedKey(0));
        }
        else
        {
            llInstantMessage(llDetectedKey(0), "Sorry, the owner of this object has set the menu to: " + llList2String(SECURITY_TYPES, security_index));
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (msg == "[SECURITY]")
        {
            if (id == llGetOwner())
            {
                security_index++;
                if (security_index == llGetListLength(SECURITY_TYPES))
                {
                    security_index = 0;
                }
                llMessageLinked(LINK_SET, 0, llList2String(SECURITY_TYPES, security_index), "");
                llInstantMessage(id, "Security set to: " + llList2String(SECURITY_TYPES, security_index));
            }
            else
            {
                llInstantMessage(id, "Sorry, only the owner can change this.");
            }
            llMessageLinked(LINK_SET, 90005, "", id);
        }
        else if (num == 90060 && pass_security(id) == TRUE)
        {
            llMessageLinked(LINK_SET, 90005, "", id);
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            integer i = llGetNumberOfPrims();
            while (llGetAgentSize(llGetLinkKey(i)) != ZERO_VECTOR)
            {
                key av = llGetLinkKey(i);
                if (pass_security(av) == FALSE)
                {
                    llSleep(2);
                    llUnSit(av);
                    llInstantMessage(av, "Sorry, the owner of this object has set the menu to: " + llList2String(SECURITY_TYPES, security_index));
                }
                i--;
            }
        }
    }
}
