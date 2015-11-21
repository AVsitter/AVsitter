/*
LSL-AVSITTER-LockGuard-PLUGIN
Copyright (c) 2015
Permission given to modify and adapt this script

For use attaching particle chains to LockGuard V2 compatible cuffs such as Open Collar

This script should be placed inside the prim that contains your poses and props.

Inspiration and function (not code) from the Bright CISS system by Shan Bright & Innula Zenovka.
*/

// SITTER: The AVsitter SITTER # the cuff settings are for.
integer SITTER = 0; 

// USES_PROPS: Set to FALSE if your ring prims are linked to your furniture. Set TRUE if your prim rings are in props. If you're using props, you must include the "[AV]LockGuard-object" script in your props and ring prims must have the word "ring" in their name. Each pose can only have 1 prop for all the rings (e.g. the ring prop for each pose should be 1 linked object, not separate props of individual rings).

// NOTE: USES_PROPS should only be used for specific cases. e.g. if the prop completely changes the surrounding scene which the chains attach to. If you want the LockGuard rings rezzed all the time then they should be permanently linked to the furniture and not approached with props. Most builds should use USES_PROPS = FALSE;

integer USES_PROPS = FALSE; 

/*
In the POSES list below, specify which cuffs to chain to which prims for each POSE or SYNC (these correspond to menu names of your poses, not animation file names!).

e.g: "Pose2", "leftwrist,ring1,rightwrist,ring2"

When the POSE "Pose2" is played, this will chain the "leftwrist" cuff to the prim hook named "ring1" and the "rightwrist" cuff to the prim hook named "ring2". The hook prims in the furniture should be named (e.g. "ring1" and "ring2").

See http://www.lslwiki.net/lslwiki/wakka.php?wakka=exchangeLockGuardItem for a list of LockGuard V2 Standard ID Tags and more information.
The LockGuard package (with full instructions for the protocol) can be obtained in-world from Lillani Lowell's inworld location.
*/

list POSES = [
		"Pose1", "leftwrist,ring1,rightwrist,ring2,leftankle,ring3,rightankle,ring4",
		"Pose2", "leftwrist,ring1,rightwrist,ring2",
		"Pose3", "leftwrist,ring5,rightwrist,ring6,leftankle,ring7,rightankle,ring8",
		"Pose4", "leftwrist,ring5,rightwrist,ring6"
		];

// CHAIN_PARAMETERS: Specify any special LockGuard commands. If you do not specify any then the particle will use the cuff default. Common used parameters are "gravity g", "life secs", "color red green blue", "size x y", "texture uuid". e.g. "color 1 0 0 texture 6808199d-e4c8-22f9-cf8a-2d9992ab630d" will bind with red ropes. For information on parameters see http://www.lslwiki.net/lslwiki/wakka.php?wakka=exchangeLockGuard
string  CHAIN_PARAMETERS = "size 0.12 0.12 life 1 gravity 0.3 texture d7277e78-06f4-58ae-9f7c-7499e50de18a";
//string  CHAIN_PARAMETERS = "size 0.12 0.12 life 1 gravity 0.3 texture 245ea72d-bc79-fee3-a802-8e73c0f09473";
//string  CHAIN_PARAMETERS = "size 0.12 0.12 life 1.2 gravity 0 texture d7277e78-06f4-58ae-9f7c-7499e50de18a";

/*
CHANGES:
3.03a ~ altered to still uses pose name (rather than prop name) when USES_PROPS = TRUE
*/

/******************************************************************
 * DON'T EDIT BELOW THIS UNLESS YOU KNOW WHAT YOU'RE DOING!
******************************************************************/

integer LOCKGUARD_CHANNEL = -9119;
integer COMM_CHANNEL = -57841689;
integer comm_handle;
key avatar;
list links;
list ring_prims;
//string PROP_NAME;
string POSE_NAME;

go_chain(list new_links){
	integer link_index;
	// unlink unused links
	for(link_index=0;link_index<llGetListLength(links);link_index+=2){
		if(llListFindList(new_links,[llList2String(links,link_index)])==-1){
			llWhisper(LOCKGUARD_CHANNEL,"lockguard "+(string)avatar+" "+llList2String(links,link_index)+" unlink");
		}
	}
	
	// link new links
	for(link_index=0;link_index<llGetListLength(new_links);link_index+=2){
		integer index = llListFindList(ring_prims,[llList2String(new_links,link_index+1)]);
		if(index!=-1){
			llWhisper(LOCKGUARD_CHANNEL,"lockguard "+(string)avatar+" "+llList2String(new_links,link_index)+" link "+llList2String(ring_prims,index+1)+" "+CHAIN_PARAMETERS);
		}
	}
	links = new_links;
}

default{
	
	link_message(integer sender, integer num, string msg, key id){
		if(sender==llGetLinkNumber()){
			if(num==90500 && USES_PROPS){
				list data = llParseStringKeepNulls(msg,["|"],[]);
				integer SITTER_NUMBER = (integer)llList2String(data,1);
				if(SITTER_NUMBER==SITTER){
					avatar = id;
					string EVENT = llList2String(data,0);
					//PROP_NAME = llList2String(data,2);
					string PROP_OBJECT = llList2String(data,3);
					//string PROP_GROUP = llList2String(data,4);
					string PROP_UUID = llList2String(data,5);
					//llOwnerSay(llDumpList2String([EVENT, SITTER_NUMBER, PROP_NAME, PROP_OBJECT, PROP_GROUP, PROP_UUID, AVATAR_UUID],","));
					if(EVENT=="REZ"){
						llListenRemove(comm_handle);
						comm_handle = llListen(COMM_CHANNEL,PROP_OBJECT,PROP_UUID,"");
						llRegionSayTo((key)PROP_UUID,COMM_CHANNEL,"INFORM");
					}
				}
			}
			else if(num==90065){//stands up
				if(id==avatar){
					go_chain([]);
					avatar = NULL_KEY;
				}		
			}
			else if(num==90045){//animation played
				list data = llParseString2List(msg,["|"],[]);
				string SITTER_NUMBER = llList2String(data,0);
				if((integer)SITTER_NUMBER==SITTER){
					if(id!=avatar){
						go_chain([]);
					}
					avatar = id;			
					POSE_NAME = llList2String(data,1);
					list new_links;
					integer pose_index = llListFindList(POSES,[POSE_NAME]);
					if(pose_index!=-1){
						new_links = llCSV2List(llList2String(POSES,pose_index+1));
					}
					
					if(USES_PROPS){
					 	go_chain(new_links);
					}
					else{
						ring_prims = [];
						integer i;
						for(i=0;i<=llGetNumberOfPrims();i++){
							if (llSubStringIndex(llToLower(llGetLinkName(i)),"ring")!=-1){
								ring_prims += [llGetLinkName(i),llGetLinkKey(i)];	
							}				
						}
					}
					go_chain(new_links);
				}
				else if(id==avatar){
					go_chain([]);
					avatar = NULL_KEY;
				}
			}
		}
	}
	
	listen(integer listen_channel, string name, key id, string msg){
		list data = llParseString2List(msg,["|"],[]);
		if(llList2String(data,0)=="ATTACHPOINTS"){
			ring_prims = llDeleteSubList(data,0,0);		
			go_chain(links);
		}
	}
}
