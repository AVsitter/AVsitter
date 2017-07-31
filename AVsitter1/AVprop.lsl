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

// script that goes inside AVsitter1 props

integer startparam;
default
{
    state_entry()
    {
    }
    on_rez(integer start)
    {
        if (start)
        {
            startparam = start;
            llListen(startparam, "", "", "REMPROPS");
            llListen(startparam, "", "", "PROPSEARCH");
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        if (message == "REMPROPS")
        {
            llDie();
        }
        else if (message == "PROPSEARCH")
        {
            llShout(startparam, "SAVEPROP");
        }
    }
}
