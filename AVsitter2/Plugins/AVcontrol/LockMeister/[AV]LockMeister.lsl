/*
 * [AV]LockMeister - Creates LockMeister V1/V2 chains
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

//  For use attaching particle chains to LockMeister V1/V2 compatible cuffs such as Open Collar & KDC
//  This script should be placed inside the prim that contains your poses and props.
//  Based on  http://wiki.secondlife.com/wiki/LSL_Protocol/LockMeister_System#Advanced_Furniture_Script

//  SITTER:
//      The AVsitter SITTER # the chain settings are for.

integer SITTER = 0;

/*
POSES list
      - specifies which cuffs to chain to which prims for each POSE or SYNC (these correspond to
        menu names of your poses, not animation file names!).
        e.g: "Pose2", "lcuff, ring1, rcuff, ring2"
      - When the POSE "Pose2" is played, this will draw a chain from the prim named "ring1" to the
        "left wrist cuff" (lcuff) and the prim named "ring2" to the right wrist cuff (rcuff).
        The chain emitter prims in the furniture should be named (e.g. "ring1" and "ring2").
      - See http://wiki.secondlife.com/wiki/LSL_Protocol/LockMeister_System#Complete_List_of_Mooring_Points
        for a list of standard LockMeister targets and more information.
      - A pose name of "*" provides a default for all poses, should that be necessary.
*/
list POSES = [
        "cross",    "rcuff,ring1,lcuff,ring2,rlcuff,ring3,llcuff,ring4",
        "reverse",  "rcuff,ring2,lcuff,ring1,rlcuff,ring4,llcuff,ring3",
        "arms",     "rcuff,ring1,lcuff,ring2",
        "upside",   "llcuff,ring1,rlcuff,ring2"
];

SetChain(key target, integer link_id)
{
    llLinkParticleSystem(link_id,[
        //This is where you can customize your chain appearance.
        PSYS_PART_FLAGS,PSYS_PART_FOLLOW_SRC_MASK|PSYS_PART_FOLLOW_VELOCITY_MASK|PSYS_PART_TARGET_POS_MASK,
        PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_DROP,
        PSYS_PART_START_SCALE, < 0.1, 0.1, 0 >,
        PSYS_PART_MAX_AGE, 3.0,
        PSYS_SRC_BURST_RATE, 0.02,
        PSYS_SRC_TEXTURE, "d7277e78-06f4-58ae-9f7c-7499e50de18a",
        PSYS_SRC_BURST_SPEED_MIN,0,
        PSYS_SRC_BURST_SPEED_MAX,0,
        PSYS_SRC_TARGET_KEY, target,
        PSYS_SRC_BURST_PART_COUNT, 1,
        PSYS_SRC_ACCEL, <0,0,-0.3>
        ]);
}

list    emitter_links;
list    emitter_states;
list    emitter_lmcodes;
integer emitter_v2_count;

ClearChains()
{
    llSetTimerEvent(0);
    llListenRemove(lm_handle);
    lm_handle = 0;

    integer chain = llGetListLength(emitter_links);
    while (chain--)
        llLinkParticleSystem(llList2Integer(emitter_links,chain),[]);

    avatar = NULL_KEY;
    emitter_links=[];
    emitter_states=emitter_links;
    emitter_lmcodes=emitter_links;
    emitter_v2_count=0;
}

integer lm_channel = -8888;
integer lm_handle;
key avatar;

list ring_prims = [avatar]; //OSS::list ring_prims; // Force error if not compiled in Mono

integer TIMEOUT = 10;       //How long do we wait for a reply before closing communications.

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        if (sender != llGetLinkNumber()) return;

        if (num == 90030)
        {
            //If sitting positions have been swapped and it involve
            //SITTER and our user.
            //we clear all drawn chains.

            if (SITTER == (integer)msg || SITTER == (integer)((string)id))
            {
                if (avatar)
                    ClearChains();
            }
        }
        else if (num == 90065)
        {
            //If OUR user stood up, we clear all drawn chains.

            if (id != avatar) return;
            ClearChains();
        }
        else if (num == 90045)
        {
            //If a new animation is being played, we have to clear existing chains (if needed),
            //and draw new ones if the animation is registered in POSES.

            if (SITTER != (integer)msg) return; //payload:0 == (integer)payload -> which sitter is this for.

            msg = llList2String(llParseString2List(msg, (list)"|", []), 1); //msg is now payload:1 -> the pose being played.

            if (avatar)
                ClearChains();

            avatar = id;

            integer pose_index = llListFindList(POSES, (list)msg);

            if (!~pose_index) //If we haven't found a named pose, try to find the wildcard (*) pose.
            {
                pose_index = llListFindList(POSES, (list)"*");
                if (!~pose_index) return;
            }

            if (!lm_handle)
                lm_handle = llListen(lm_channel,"","","");

            llSetTimerEvent(TIMEOUT);

            list data = llCSV2List(llList2String(POSES,pose_index+1));
            integer i;
            for (; i<llGetListLength(data); i+=2)
            {
                string lm_target = llList2String(data,i);
                string prim_name = llList2String(data,i+1);

                //lookup the prim linknumber of this anchor point.
                integer j = llGetObjectPrimCount(llGetKey());
                while (j--)
                {
                    integer link_id = j+1;
                    if (~llSubStringIndex(llGetLinkName(link_id), prim_name))
                    {
                        emitter_links += link_id;
                        emitter_lmcodes += lm_target;
                        emitter_states += 0;
                        llRegionSayTo(avatar,lm_channel,(string)avatar+lm_target);
                        j=FALSE; //we got what we wanted, bail.
                    }
                }
            }
        }
    }

    listen(integer listen_channel, string name, key id, string msg)
    {
        if (avatar == NULL_KEY) return;                         //We must have a user.
        if (llGetOwnerKey(id) != avatar) return;                //Attachment must belong to user.
        if ((key)llGetSubString(msg,0,35) != avatar) return;    //Target key must be our user.

        if (llGetSubString(msg,-3,-1) == " ok")//lmv1 ' ok' received
        {
            //LMV1 Message structure:
            //Request -> AVATAR_UUIDlmcode
            //Reply   -> AVATAR_UUIDlmcode ok

            string  lm_target = llGetSubString(msg,36,-4); //strip the 'ok' and the 'target key'.
            integer emitter_index = llListFindList(emitter_lmcodes, (list)lm_target);

            if (!~emitter_index) return;                                //No emitter configured for this lm code.
            if (llList2Integer(emitter_states,emitter_index)) return;   //This point already has an lmv1 or lmv2 target.

            SetChain(id,llList2Integer(emitter_links,emitter_index));                                   //Draw the chain.
            emitter_states = llListReplaceList(emitter_states,(list)1, emitter_index, emitter_index);   //Set emitter state to 1 (lmv1 ok)

            llRegionSayTo(id,lm_channel,(string)avatar+"|LMV2|RequestPoint|"+lm_target);    //Request a (possible) LMV2 and extend
            llSetTimerEvent(TIMEOUT);                                                       //the time objects have to reply.
        }
        else
        {
            //LMV2 Message structure:
            //Request -> AVATAR_UUID|LMV2|RequestPoint|lmcode
            //Reply   -> AVATAR_UUID|LMV2|ReplyPoint|lmcode|TARGET_UUID

            list commands = llParseString2List(msg,(list)"|",[]);

            if ( llList2String(commands,0) != avatar) return;                                               //Message doesn't target our user.
            if ( (llList2String(commands,1)!="LMV2") || (llList2String(commands,2)!="ReplyPoint") ) return; //Message doesn't have the right header/command.

            integer emitter_index = llListFindList(emitter_lmcodes, (list)llList2String(commands,3) );

            if (!~emitter_index) return;                                    //No emitter configured for this lm code.
            if (llList2Integer(emitter_states,emitter_index) == 2) return;  //This point already has an lmv2 target.

            key target_id = llList2String(commands,4);
            integer target_is_key;
            if (target_id) target_is_key = TRUE;
            if (!target_is_key) return; //Bail out if the target key is invalid.

            SetChain(target_id, llList2Integer(emitter_links,emitter_index));                           //Update the chain.
            emitter_states = llListReplaceList(emitter_states, (list)2, emitter_index, emitter_index);  //Set emitter state to 2 (lmv2 ok)

            emitter_v2_count++;                                         //This is not entirely necessary but it allows us to close
            if (emitter_v2_count >= llGetListLength(emitter_links))      //the listener as soon as all anchors are LMV2 satisfied.
            {
                llListenRemove(lm_handle);
                lm_handle = 0;
                llSetTimerEvent(0);
                return;
            }
            
            llSetTimerEvent(TIMEOUT); //extend the time objects have to reply.
        }
    }
    timer()
    {
        //Good coders don't leave unused listeners running.
        //The lm channel can be pretty busy.
        llListenRemove(lm_handle);
        lm_handle = 0;
        llSetTimerEvent(0);
    }
}
