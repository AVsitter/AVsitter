/*
 * [AV]root - Activate setups in child prims by touching the root
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
//string #version = "2.2p04";
string script_basename = "[AV]sitA";
string menu_script = "[AV]menu";
key A;
list B = [A]; //OSS::list B; // Force error in LSO

default
{
    touch_end(integer touched)
    {
        if (llGetInventoryType(script_basename) != INVENTORY_SCRIPT && llGetInventoryType(menu_script) != INVENTORY_SCRIPT)
        {
            llMessageLinked(LINK_ALL_OTHERS, 90005, llList2String(B, 0), llDetectedKey(0));
            B = [];
        }
    }
}
