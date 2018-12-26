/*
 * [AV]dummy - Reference animesh dummy implementation
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

integer SITTERS_MAY_CONTROL = TRUE;
integer GENDER = 0;

// offset that's needed to make the dummy face forward, might be different for different models?
vector FWD = <0, 1, 0>;
vector LEFT = <-1, 0, 0>;
vector UP = <0, 0, 1>;
rotation NEUTRAL_ROT;

// anims that are internal to the dummy, and shouldn't be removed, stopped or counted by the anim hashing
// (deformers, etc.)
list INTERNAL_ANIMS = [];

integer AV2_ANIMESH_CHANNEL = -1252168;
integer DIALOG_CHANNEL = -6246233;

integer CONN_STATE_DISCONNECTED = 0;
integer CONN_STATE_DISCOVERY = 1;
integer CONN_STATE_CHOOSING = 2;
integer CONN_STATE_WAITING = 3;
integer CONN_STATE_CONNECTED = 4;
integer gConnState;

key gTargetFurniture = NULL_KEY;

string gAnimsHash;
integer gInventoryDirtied;

list gReceivedNames = [];
list gReceivedKeys = [];
list gReceivedHashes = [];

string truncateDialogButton(string text) {
    return llBase64ToString(llGetSubString(llStringToBase64(text), 0, 31));
}

integer mayControlMenu(key id) {
    if (id == llGetOwner())
        return TRUE;
    if (gTargetFurniture != NULL_KEY && SITTERS_MAY_CONTROL)
        // TODO: get SITTERS from anim broadcast and use that?
        return llList2Key(llGetObjectDetails(id, [OBJECT_ROOT]), 0) == gTargetFurniture;
    return FALSE;
}

setStatusText(string text) {
    llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_TEXT, text, <1,1,1>, 1]);
}

clearOldAnims() {
    integer i = llGetInventoryNumber(INVENTORY_ANIMATION);
    while(i-- > 0) {
        string name = llGetInventoryName(INVENTORY_ANIMATION, i);
        if (llListFindList(INTERNAL_ANIMS, [name]) == -1)
            llRemoveInventory(name);
    }
}

recalcAnimsHash() {
    integer num = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    gAnimsHash = "";
    for(i=0; i<num; ++i) {
        string name = llGetInventoryName(INVENTORY_ANIMATION, i);
        if (llListFindList(INTERNAL_ANIMS, [name]) == -1)
            gAnimsHash = llSHA1String(name + gAnimsHash);
    }
}

stopAllAnims(integer internal_anims) {
    integer i;
    list anims = llGetObjectAnimationNames();
    integer len = llGetListLength(anims);
    for(i=0; i<len; ++i) {
        string name = llList2String(anims, i);
        if (!internal_anims)
            if (llListFindList(INTERNAL_ANIMS, [name]) != -1)
                jump next;
        llStopObjectAnimation(llList2String(anims, i));
        @next;
    }
}

setConnState(integer state_) {
    // clear any queued up timer events
    llSetTimerEvent(0.0);

    if (state_ != CONN_STATE_CHOOSING) {
        gReceivedKeys = [];
        gReceivedNames = [];
        gReceivedHashes = [];
    }

    if (state_ != CONN_STATE_WAITING && state_ != CONN_STATE_CONNECTED) {
        // Tell the connected furniture that we're disconnecting, if we have one
        sendCmd("DISCONNECT");
        gTargetFurniture = NULL_KEY;
    }

    if (state_ == CONN_STATE_DISCONNECTED) {
        llSetTimerEvent(10.0);
        setStatusText("Disconnected");
        stopAllAnims(FALSE);
        llStartObjectAnimation("stand");
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_ROTATION, NEUTRAL_ROT]);
    } else if (state_ == CONN_STATE_DISCOVERY) {
        setStatusText("Scanning for furniture...");
        llSetTimerEvent(2.0);
    } else if (state_ == CONN_STATE_CHOOSING) {
        setStatusText("Waiting for selection...");
        llSetTimerEvent(20.0);
    } else if (state_ == CONN_STATE_WAITING) {
        setStatusText("Waiting for furniture to accept");
        llSetTimerEvent(10.0);
    } else if (state_ == CONN_STATE_CONNECTED) {
        setStatusText("");
        llStopObjectAnimation("stand");
        llSetTimerEvent(5.0);
    } else {
        llOwnerSay("Asked to change to unknown state????");
        setConnState(CONN_STATE_DISCONNECTED);
    }

    // Set this here so we can compare old state to new state above
    // if needed
    gConnState = state_;
}

handleFurnitureMsg(key id, string msg) {
    list params = llParseStringKeepNulls(msg, ["|"], []);
    string cmd = llList2String(params, 0);
    params = llList2List(params, 1, -1);

    if (gConnState == CONN_STATE_DISCONNECTED) {
        // Furniture asked us to connect
        if (cmd == "SOLICIT") {
            if (gTargetFurniture == NULL_KEY && llGetOwnerKey(id) == llGetOwner()) {
                connectToFurniture(id, llList2String(params, 0));
            }
        }
    // while we're looking for furniture to connect to
    } else if (gConnState == CONN_STATE_DISCOVERY) {
        if (cmd == "DISCOVERY_PONG") {
            // furniture told us it exists
            if (llGetOwnerKey(id) != llGetOwner())
                return;

            if (llGetListLength(gReceivedKeys) >= 9) {
                return;
            }

            if (llListFindList(gReceivedKeys, [id]) == -1) {
                gReceivedKeys += id;
                gReceivedNames += truncateDialogButton(llList2String(params, 0));
                gReceivedHashes += llList2String(params, 1);
            }
        }
    // while we're talking to specific furniture
    } else if (id == gTargetFurniture) {
        if (gConnState == CONN_STATE_CONNECTED) {
            if (cmd == "DISCONNECT") {
                setConnState(CONN_STATE_DISCONNECTED);
                return;
            } else if (cmd == "START_ANIM") {
                llStartObjectAnimation(llList2String(params, 0));
            } else if (cmd == "STOP_ANIM") {
                llStopObjectAnimation(llList2String(params, 0));
            } else if (cmd == "REPOSITION") {
                list root_params = llGetObjectDetails(gTargetFurniture, [OBJECT_POS, OBJECT_ROT]);
                vector root_pos = llList2Vector(root_params, 0);
                rotation root_rot = llList2Rot(root_params, 1);

                llSetLinkPrimitiveParamsFast(LINK_ROOT, [
                    PRIM_POSITION, root_pos + ((vector)llList2String(params, 0) * root_rot),
                    // TODO: is this right? Seems ok.
                    PRIM_ROTATION, NEUTRAL_ROT * (rotation)llList2String(params, 1) * root_rot
                ]);
            }
        } else {
            if (cmd == "CONNECT_RESP") {
                string msg = llList2String(params, 0);
                if (msg) {
                    llOwnerSay("Couldn't connect due to '" + msg + "'");
                    setConnState(CONN_STATE_DISCONNECTED);
                } else {
                    llOwnerSay("Furniture connected");
                    setConnState(CONN_STATE_CONNECTED);
                }
            }
        }
    }
}

sendCmd(string msg) {
    if (gTargetFurniture != NULL_KEY) {
        llRegionSayTo(gTargetFurniture, AV2_ANIMESH_CHANNEL, msg);
    }
}

connectToFurniture(key id, string anims_hash) {
    // recalc our anim hash if we need to
    if (gInventoryDirtied) {
        gInventoryDirtied = FALSE;
        recalcAnimsHash();
    }
    integer need_anims = gAnimsHash != anims_hash;
    llOwnerSay(gAnimsHash + " : " + anims_hash);
    if (need_anims) {
        setStatusText("Removing old animations");
        clearOldAnims();
    }

    gTargetFurniture = id;

    setConnState(CONN_STATE_WAITING);
    sendCmd("CONNECT|" + (string)GENDER + "|" + (string)need_anims);
}

default {
    state_entry() {
        NEUTRAL_ROT = llAxes2Rot(FWD, LEFT, UP);
        setConnState(CONN_STATE_DISCONNECTED);
        llListen(AV2_ANIMESH_CHANNEL, "", "", "");
        llListen(DIALOG_CHANNEL, "", "", "");
        // Let any dangling doodads know we disconnected
        llWhisper(AV2_ANIMESH_CHANNEL, "DISCONNECT");
        recalcAnimsHash();
    }

    on_rez(integer start_param) {
        setConnState(CONN_STATE_DISCONNECTED);
    }

    touch_start(integer total_number) {
        integer i;
        for (i = 0; i < total_number; ++i) {
            key id = llDetectedKey(i);
            if(gConnState == CONN_STATE_DISCONNECTED) {
                if (id == llGetOwner()) {
                    llWhisper(AV2_ANIMESH_CHANNEL, "DISCOVERY_PING");
                    setConnState(CONN_STATE_DISCOVERY);
                }
            } else if (gConnState == CONN_STATE_CONNECTED) {
                if (mayControlMenu(id))
                    sendCmd("SHOW_MENU|" + (string)id);
            }
        }
    }

    listen (integer channel, string name, key id, string msg) {
        key owner_key = llGetOwnerKey(id);
        if (channel == DIALOG_CHANNEL) {
            if (gConnState == CONN_STATE_CHOOSING) {
                if (owner_key != llGetOwner()) {
                    return;
                }
                integer key_idx = llListFindList(gReceivedNames, [msg]);
                if (key_idx == -1) {
                    llOwnerSay("I don't know what " + msg + " is");
                    setConnState(CONN_STATE_DISCONNECTED);
                    return;
                }

                connectToFurniture(
                    llList2Key(gReceivedKeys, key_idx),
                    llList2String(gReceivedHashes, key_idx)
                );
            }
        } else if (channel == AV2_ANIMESH_CHANNEL) {
            handleFurnitureMsg(id, msg);
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            gInventoryDirtied = llGetUnixTime();
        }
    }

    timer() {
        if (gConnState == CONN_STATE_DISCOVERY) {
            if(llGetListLength(gReceivedNames)) {
                llDialog(
                    llGetOwner(),
                    "Which furniture would you like to pair with?",
                    gReceivedNames,
                    DIALOG_CHANNEL
                );
                setConnState(CONN_STATE_CHOOSING);
            } else {
                llOwnerSay("Didn't detect any furniture nearby");
                setConnState(CONN_STATE_DISCONNECTED);
            }
        } else if (gConnState == CONN_STATE_CHOOSING) {
            llOwnerSay("Timed out while choosing a furniture to control");
            setConnState(CONN_STATE_DISCONNECTED);
        } else if (gConnState == CONN_STATE_WAITING) {
            llOwnerSay("Timed out waiting for approval");
            setConnState(CONN_STATE_DISCONNECTED);
        } else if(gConnState == CONN_STATE_CONNECTED) {
            if (llGetBoundingBox(gTargetFurniture) == []) {
                llOwnerSay("Furniture went away!");
                setConnState(CONN_STATE_DISCONNECTED);
            }
        }

        if (gInventoryDirtied && gInventoryDirtied + 5 < llGetUnixTime()) {
            gInventoryDirtied = FALSE;
            recalcAnimsHash();
        }
    }
}