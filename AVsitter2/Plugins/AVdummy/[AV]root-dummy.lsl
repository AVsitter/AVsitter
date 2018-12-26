/*
 * [AV]root-dummy - Handles communication with animesh dummies
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

// Only allow dummies owned by the furniture owner to "sit"
integer OWNER_ONLY = TRUE;

integer AV2_ANIMESH_CHANNEL = -1252168;
integer PENDING_TTL = 5;
integer MAX_PENDING = 10;

string gAnimsHash;
integer gAnimsTransferrable;
integer gAnimsCopyable;
integer gInventoryDirtied;

list gSittingDummies;
list gPendingDummies;
list gPendingDummiesTimes;
list gPendingDummiesNeedAnims;

sendDummyAnims(key receiver) {
    integer num = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    for(i=0; i<num; ++i) {
        llGiveInventory(receiver, llGetInventoryName(INVENTORY_ANIMATION, i));
    }
}

recalcAnims() {
    integer num = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    gAnimsHash = "";
    gAnimsTransferrable = TRUE;
    gAnimsCopyable = TRUE;
    for(i=0; i<num; ++i) {
        string name = llGetInventoryName(INVENTORY_ANIMATION, i);
        if (gAnimsTransferrable)
            gAnimsTransferrable = (llGetInventoryPermMask(name, MASK_NEXT) & PERM_TRANSFER) == PERM_TRANSFER;
        if (gAnimsCopyable)
            gAnimsCopyable = (llGetInventoryPermMask(name, MASK_OWNER) & PERM_COPY) == PERM_COPY;
        gAnimsHash = llSHA1String(name + gAnimsHash);
    }
}

disconnectDummy(key id) {
    integer sit_idx = llListFindList(gSittingDummies, [id]);
    if (sit_idx == -1)
        return;
    sendDirect(id, "DISCONNECT");
    gSittingDummies = llDeleteSubList(gSittingDummies, sit_idx, sit_idx);
    llMessageLinked(LINK_SET, 90401, "", id); // 90400=non-avatar wants to disconnect
}

pruneDeadDummies() {
    integer i;
    integer len = llGetListLength(gSittingDummies);
    for(i=len-1; i>0; --i) {
        key id = llList2Key(gSittingDummies, i);
        if (llGetBoundingBox(id) == []) {
            disconnectDummy(id);
        }
    }
}

sendDirect(key id, string msg) {
    llRegionSayTo(id, AV2_ANIMESH_CHANNEL, msg);
}

sendBroadcast(string msg) {
    llRegionSay(AV2_ANIMESH_CHANNEL, msg);
}

default {
    state_entry() {
        llListen(AV2_ANIMESH_CHANNEL, "", "", "");
        // Let any existing objects know we restarted so they're off in the void now
        sendBroadcast("DISCONNECT");
        // Let sitA scripts know that any non-avatar sitters are now dead if we restarted
        llMessageLinked(LINK_SET, 90402, "", ""); // 90402=disconnect all non-avatar sitters
        recalcAnims();
        llSetTimerEvent(2.0);
    }

    listen(integer channel, string name, key id, string msg) {
        if (OWNER_ONLY && llGetOwnerKey(id) != llGetOwner())
            return;

        list msg_parsed = llParseString2List(msg, ["|"], []);
        integer sit_idx = llListFindList(gSittingDummies, [id]);
        if (sit_idx != -1) {
            if (llList2String(msg_parsed, 0) == "DISCONNECT") {
                disconnectDummy(id);
                return;
            } else if (llList2String(msg_parsed, 0) == "SHOW_MENU") {
                llMessageLinked(LINK_ROOT, 90004, "", llList2String(msg_parsed, 1) + "|" + (string)id); // 90004=show top menu
            }
        } else {
            if (llList2String(msg_parsed, 0) == "DISCOVERY_PING") {
                pruneDeadDummies();
                sendDirect(id, "DISCOVERY_PONG|" + llGetObjectName() + "|" + gAnimsHash);
            } else if (llList2String(msg_parsed, 0) == "CONNECT") {
                pruneDeadDummies();
                if (llGetListLength(gPendingDummies) > MAX_PENDING) {
                    sendDirect(id, "CONNECT_RESP|no_seats");
                    return;
                }

                integer need_anims = llList2Integer(msg_parsed, 2);
                if (need_anims) {
                    if (!gAnimsCopyable) {
                        sendDirect(id, "CONNECT_RESP|no_copy_anims");
                        return;
                    }
                    if (!gAnimsTransferrable && llGetOwnerKey(id) != llGetOwner()) {
                        sendDirect(id, "CONNECT_RESP|no_transfer_anims");
                        return;
                    }
                }
                gPendingDummies += [id];
                gPendingDummiesTimes += [llGetUnixTime()];
                gPendingDummiesNeedAnims += [need_anims];
                llMessageLinked(LINK_SET, 90400, llList2String(msg_parsed, 1), id); // 90400=non-avatar wants to sit
            }
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            // Don't lock up the script if we get a ton of anims dropped in at once
            gInventoryDirtied = llGetUnixTime();
        }
    }

    link_message(integer sender_num, integer num, string msg, key id) {
        integer one = (integer)msg;
        integer two = (integer)((string)id);

        if (num == 90299) { // 90299=send Reset to AVsitB
            // If a sitA script reset then its SITTERS will now be out of sync with
            // everyone else. Reset ourselves and disconnect any non-avatar sitters.
            llResetScript();
        }

        integer sit_idx = llListFindList(gSittingDummies, [id]);
        if (sit_idx == -1) {
            if (num == 90060) { // 90060=welcome new sitter
                integer pending_idx = llListFindList(gPendingDummies, [id]);
                // a sitA script picked up a pending sitter!
                if (pending_idx != -1) {
                    gSittingDummies += [id];
                    sendDirect(id, "CONNECT_RESP|");
                    if (llList2Integer(gPendingDummiesNeedAnims, pending_idx)) {
                        sendDummyAnims(id);
                    }

                    gPendingDummies = llDeleteSubList(gPendingDummies, pending_idx, pending_idx);
                    gPendingDummiesTimes = llDeleteSubList(gPendingDummiesTimes, pending_idx, pending_idx);
                    gPendingDummiesNeedAnims = llDeleteSubList(gPendingDummiesNeedAnims, pending_idx, pending_idx);
                }
            }
        } else {
            if (num == 90080) { // 90080=play animation
                sendDirect(id, "START_ANIM|" + msg);
            } else if (num == 90081) { // 90080=stop animation
                sendDirect(id, "STOP_ANIM|" + msg);
            } else if (num == 90085) { // 90085=reposition avatar
                sendDirect(id, "REPOSITION|" + msg);
            }
        }
    }

    timer() {
        pruneDeadDummies();

        integer i;
        integer len = llGetListLength(gPendingDummies);
        for(i=len-1; i>0; --i) {
            // Timed out, no sitA scripts were willing to take 'em
            if(llList2Integer(gPendingDummiesTimes, i) + PENDING_TTL < llGetUnixTime()) {
                key id = llList2Key(gPendingDummies, i);
                gPendingDummies = llDeleteSubList(gPendingDummies, i, i);
                gPendingDummiesTimes = llDeleteSubList(gPendingDummiesTimes, i, i);
                gPendingDummiesNeedAnims = llDeleteSubList(gPendingDummiesNeedAnims, i, i);
                sendDirect(id, "CONNECT_RESP|no_seats");
            }
        }

        if (gInventoryDirtied && gInventoryDirtied + 5 < llGetUnixTime()) {
            gInventoryDirtied = FALSE;
            recalcAnims();
        }
    }
}