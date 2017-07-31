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
 
string script_basename = "[AV]sitA";
string menu_script = "[AV]menu";
default
{
    touch_end(integer touched)
    {
        if (llGetInventoryType(script_basename) != INVENTORY_SCRIPT && llGetInventoryType(menu_script) != INVENTORY_SCRIPT)
        {
            llMessageLinked(LINK_ALL_OTHERS, 90005, "", llDetectedKey(0));
        }
    }
}
