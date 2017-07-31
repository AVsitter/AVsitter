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
 
//  For use attaching particle chains to LockGuard V2 compatible cuffs such as Open Collar
//  This script should be placed inside the prim that contains your poses and props.
//  Inspiration and function (not code) from the Bright CISS system by Shan Bright & Innula Zenovka.

//  SITTER:
//      The AVsitter SITTER # the cuff settings are for.

integer SITTER = 0;

//  USES_PROPS:
//      - TRUE for ring prims within props
//      - FALSE for ring prims linked to furniture
//      - If you're using props, you must include the "[AV]LockGuard-object" script in your props
//        and ring prim names must contain the substring "ring". Each pose can only have 1 prop
//        for all the rings (e.g. the ring prop for each pose should be 1 linked object, not
//        separate props of individual rings).
//  NOTE:
//      - Most builds should use USES_PROPS = FALSE;
//      - USES_PROPS should only be used for specific cases. e.g. if the prop completely changes the
//        surrounding scene which the chains attach to. If you want the LockGuard rings rezzed all the
//        time then they should be permanently linked to the furniture and not approached with props.

integer USES_PROPS = FALSE;

//  POSES list
//      - specifies which cuffs to chain to which prims for each POSE or SYNC (these correspond to
//        menu names of your poses, not animation file names!).
//        e.g: "Pose2", "leftwrist, ring1, rightwrist, ring2"
//      - When the POSE "Pose2" is played, this will chain the "leftwrist" cuff to the prim hook named
//        "ring1" and the "rightwrist" cuff to the prim hook named "ring2". The hook prims in the
//        furniture should be named (e.g. "ring1" and "ring2").
//      - See http://www.lslwiki.net/lslwiki/wakka.php?wakka=exchangeLockGuardItem
//        for a list of LockGuard V2 Standard ID Tags and more information. The LockGuard package
//        (with full instructions for the protocol) can be obtained in-world from Lillani Lowell's
//        inworld location.

list POSES = [
        "Pose1", "leftwrist,ring1,rightwrist,ring2,leftankle,ring3,rightankle,ring4",
        "Pose2", "leftwrist,ring1,rightwrist,ring2",
        "Pose3", "leftwrist,ring5,rightwrist,ring6,leftankle,ring7,rightankle,ring8",
        "Pose4", "leftwrist,ring5,rightwrist,ring6"
];

//  CHAIN_PARAMETERS:
//      - For information on parameters see http://www.lslwiki.net/lslwiki/wakka.php?wakka=exchangeLockGuard
//      - Specifies any special LockGuard commands. If you do not specify any then the particle will
//        use the cuff default. Common used parameters are "gravity g", "life secs",
//        "color red green blue", "size x y", "texture uuid".
//        e.g. "color 1 0 0 texture 6808199d-e4c8-22f9-cf8a-2d9992ab630d" will bind with red ropes.

string  CHAIN_PARAMETERS = "size 0.12 0.12 life 1 gravity 0.3 texture d7277e78-06f4-58ae-9f7c-7499e50de18a";
//                         "size 0.12 0.12 life 1 gravity 0.3 texture 245ea72d-bc79-fee3-a802-8e73c0f09473"
//                         "size 0.12 0.12 life 1.2 gravity 0 texture d7277e78-06f4-58ae-9f7c-7499e50de18a"

integer LOCKGUARD_CHANNEL = -9119;
integer COMM_CHANNEL = -57841689;
integer comm_handle;
key avatar;
list links;
list ring_prims;

goChain(list new_links)
{
    integer index;

//  unlink unused links
    for (; index < llGetListLength(links); index += 2)
    {
        integer found = llListFindList(new_links, [llList2String(links, index)]);
        if (~found)
        {
            llWhisper(LOCKGUARD_CHANNEL, "lockguard " + (string)avatar + " " + llList2String(links, index) + " unlink");
        }
    }

    index = 0;

//  link new links
    for (; index < llGetListLength(new_links); index += 2)
    {
        integer found = llListFindList(ring_prims, [llList2String(new_links, index + 1)]);
        if (~found)
        {
            llWhisper(LOCKGUARD_CHANNEL, "lockguard " + (string)avatar + " " + llList2String(new_links, index) + " link " + llList2String(ring_prims, found + 1) + " " + CHAIN_PARAMETERS);
        }
    }

    links = new_links;
}

list findPrimsWithSubstring(string name)
{
    list found;

    integer index = llGetLinkNumber() != 0;
    integer number = llGetNumberOfPrims() + index;
    for (; index <= number; index++)
    {
        if (~llSubStringIndex(llToLower(llGetLinkName(index)), name))
        {
            found += [llGetLinkName(index), llGetLinkKey(index)];
        }
    }

    return found;
}

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        if (sender != llGetLinkNumber()) return;

        if (num == 90500 && USES_PROPS)
        {
            list data = llParseStringKeepNulls(msg, ["|"], []);
            integer SITTER_NUMBER = (integer)llList2String(data, 1);
            if (SITTER_NUMBER == SITTER)
            {
                avatar = id;
                string EVENT = llList2String(data, 0);
//              string PROP_NAME = llList2String(data, 2);
                string PROP_OBJECT = llList2String(data, 3);
//              string PROP_GROUP = llList2String(data, 4);
                string PROP_UUID = llList2String(data,5);
//              llOwnerSay(llList2CSV([EVENT, SITTER_NUMBER, PROP_NAME, PROP_OBJECT, PROP_GROUP, PROP_UUID, AVATAR_UUID]));
                if (EVENT == "REZ")
                {
                    llListenRemove(comm_handle);
                    comm_handle = llListen(COMM_CHANNEL, PROP_OBJECT, PROP_UUID, "");
                    llRegionSayTo((key)PROP_UUID, COMM_CHANNEL, "INFORM");
                }
            }
        }
        else if (num == 90065)
        {//stands up
            if (id == avatar)
            {
                goChain([]);
                avatar = NULL_KEY;
            }
        }
        else if (num == 90045)
        {//animation played
            list data = llParseString2List(msg, ["|"], []);
            string SITTER_NUMBER = llList2String(data, 0);
            if ((integer)SITTER_NUMBER == SITTER)
            {
                if (id != avatar)
                {
                    goChain([]);
                }

                avatar = id;
                string POSE_NAME = llList2String(data, 1);
                list new_links;

                integer pose_index = llListFindList(POSES, [POSE_NAME]);
                if (~pose_index)
                {
                    new_links = llCSV2List(llList2String(POSES, pose_index + 1));
                }

                if (USES_PROPS)
                {
                    goChain(new_links);
                }
                else
                {
                    ring_prims = findPrimsWithSubstring("ring");
                }

                goChain(new_links);
            }
            else if (id == avatar)
            {
                goChain([]);
                avatar = NULL_KEY;
            }
        }
    }

    listen(integer listen_channel, string name, key id, string msg)
    {
        list data = llParseString2List(msg, ["|"], []);

        if (llList2String(data, 0) != "ATTACHPOINTS") return;

        ring_prims = llDeleteSubList(data, 0, 0);
        goChain(links);
    }
}
