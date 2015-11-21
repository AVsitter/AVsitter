/******************************************************************
* Shared prop script (alpha) v0.04a
* Allows props to be "shared" i.e. props will rez while any one of a number of POSE/SYNC are playing for any avatar.
* Also replaces the need for the "Rez Same Prop for Several Poses" script.
* Requires [AV]prop script from AVsitter2 box 2.1-09 or later.
* Shared props should use PROP3 in the AVpos notecard (a special prop type specifically for shared props).
* Shared props can be set up in SITTER 0 section of the AVpos notecard in a regular setup prim, or in a dedicated rezzer prim.
* Props for a specific sitter can use PROP, PROP1 or PROP2.
* All props referenced by this script should be named different from pose names (unlike basic props, which do have names that match poses).
******************************************************************/

/******************************************************************
SITTER_SITTER_PROPS_N_POSES is your list of SITTER#, PROP names, and POSE/SYNC names the props are for.
e.g: 0,"weights", "stand1,stand2"

-1 for SITTER indicates the prop is for all sitters (i.e. shared prop, that should use PROP3 in the AVpos notecard).
e.g: -1,"prop1", "sit1,sit2,sit3"

"*" for POSE name indicates the prop should rez for all poses.  
******************************************************************/

list SITTER_PROPS_N_POSES = [
		-1,"prop1", "sit1,sit2,sit3",
		-1,"prop2", "sit4,sync2",
		-1,"prop3", "sync1,sync2",
		0,"hat", "*",
		0,"weights", "weights1,weights2",
		1,"weights", "weights1,weights2"
		];

/******************************************************************
* DON'T EDIT BELOW THIS UNLESS YOU KNOW WHAT YOU'RE DOING!
******************************************************************/

list SITTER_PRIMS; // which prims have AVsitter setups
list SITTER_POSES_BY_PRIM; // which poses are playing for each sitter in each prim
list SITTERS_BY_PRIM; // which sitters are occupied in each setup prim

list REZZED; // which props are rezzed, for which avatars

integer ANY_SITTERS; // if avatars are sitting

rez_derez(){
	integer i;
	for (i=0;i<llGetListLength(SITTER_PROPS_N_POSES);i+=3){
		integer wasRezzed=llList2Integer(REZZED,i);
		integer forSitter = llList2Integer(SITTER_PROPS_N_POSES,i);
		list poses = llParseString2List(llList2String(SITTER_PROPS_N_POSES,i+2),[","],[]);
		integer j;
		for (j=0;j<llGetListLength(poses);j++){
			integer k;
			for (k=0;k<llGetListLength(SITTER_PRIMS);k++){
				list SITTER_POSES_IN_PRIM=llParseStringKeepNulls(llList2String(SITTER_POSES_BY_PRIM,k),["|"],[]);
				integer index = llListFindList(SITTER_POSES_IN_PRIM,[llList2String(poses,j)]);
				if(~index || llList2String(poses,j)=="*"){
					list SITTERS_IN_PRIM=llParseStringKeepNulls(llList2String(SITTERS_BY_PRIM,k),["|"],[]);
					integer l;
					for (l=index;l<llGetListLength(SITTERS_IN_PRIM);l++){
						if(forSitter==-1 || forSitter==l){
							if((llList2String(SITTER_POSES_IN_PRIM,l)==llList2String(poses,j) || llList2String(poses,j)=="*") && llList2String(SITTERS_IN_PRIM,l)!=""){
								if(!llList2Integer(REZZED,i)){
									string uuid;
									if(forSitter==l){
										uuid = llList2String(SITTERS_IN_PRIM,l);
									}
									//llOwnerSay("===REZ===="+llList2String(SITTER_PROPS_N_POSES,i+1)+"for uuid:"+uuid);
									llMessageLinked(LINK_THIS,90220,llList2String(SITTER_PROPS_N_POSES,i+1),uuid); // rez our prop.
									REZZED=llListReplaceList(REZZED,[TRUE,uuid],i,i+1);
								}
								jump done;
							}
						}
					}
				}
			}
		}
		if(wasRezzed){
			string uuid;
			if(~llList2Integer(SITTER_PROPS_N_POSES,i)){
				uuid=llList2String(SITTER_PROPS_N_POSES,i);
			}
			//llOwnerSay("===DEREZ===="+llList2String(SITTER_PROPS_N_POSES,i+1)+"for uuid:"+uuid);
			llMessageLinked(LINK_THIS,90220,"remprop_"+llList2String(SITTER_PROPS_N_POSES,i+1),uuid); // remove our prop.
			REZZED=llListReplaceList(REZZED,[FALSE],i,i);
		}
		@done;
	}
}

list fill_array(integer x){
	list array;
	integer i;
	for (i=0;i<x;i++){
		array+="";
	}
	return array;	
}

default{
	
	state_entry(){
		REZZED=fill_array(llGetListLength(SITTER_PROPS_N_POSES));
	}
	
	link_message(integer sender, integer num, string msg, key id){
		if(msg=="[CLEAR]"){ // if props were cleared with a BUTTON
			REZZED=fill_array(llGetListLength(SITTER_PROPS_N_POSES));
		}
		else if(num==90045){ // pose played
			list data = llParseStringKeepNulls(msg,["|"],[]);
			integer SITTER_NUMBER = (integer)llList2String(data,0);
			string POSE_NAME = llList2String(data,1);
			list SITTERS_IN_PRIM = llParseStringKeepNulls(llList2String(data,4),["@"],[]);
			list LAST_SITTERS_IN_PRIM;
			list SITTER_POSES_IN_PRIM;
			integer index = llListFindList(SITTER_PRIMS,[sender]);
			if(~index){
				SITTER_POSES_IN_PRIM=llParseStringKeepNulls(llList2String(SITTER_POSES_BY_PRIM,index),["|"],[]);
				SITTER_PRIMS=llDeleteSubList(SITTER_PRIMS,index,index);
				SITTER_POSES_BY_PRIM=llDeleteSubList(SITTER_POSES_BY_PRIM,index,index);
				LAST_SITTERS_IN_PRIM=llParseStringKeepNulls(llList2String(SITTERS_BY_PRIM,index),["|"],[]);
				SITTERS_BY_PRIM=llDeleteSubList(SITTERS_BY_PRIM,index,index);
				
				// if the sitters have swapped, consider any props for the changed sitters derezzed
				integer i;
				for (i=0;i<llGetListLength(LAST_SITTERS_IN_PRIM);i++){
					if(llList2String(SITTERS_IN_PRIM,i)!=llList2String(LAST_SITTERS_IN_PRIM,i)){
						integer j;
						for (j=0;j<llGetListLength(SITTER_PROPS_N_POSES);j+=3){
							if (llList2Integer(SITTER_PROPS_N_POSES,j)==i){
								REZZED=llListReplaceList(REZZED,[FALSE,""],j,j+1);
								//llOwnerSay("rezzed:"+llDumpList2String(REZZED,","));
							}
						}
					}
				}
			}
			else{
				SITTER_POSES_IN_PRIM=fill_array(llGetListLength(SITTERS_IN_PRIM));
			}
			SITTER_POSES_IN_PRIM=llListReplaceList(SITTER_POSES_IN_PRIM,[POSE_NAME],SITTER_NUMBER,SITTER_NUMBER);
			SITTER_PRIMS+=sender;
			SITTER_POSES_BY_PRIM+=llDumpList2String(SITTER_POSES_IN_PRIM,"|");
			SITTERS_BY_PRIM+=llDumpList2String(SITTERS_IN_PRIM,"|");
			
			rez_derez();
		}
		else if(num==90065){ // sitter stands
			integer index = llListFindList(SITTER_PRIMS,[sender]);
			if(~index){
				list SITTER_POSES_IN_PRIM=llParseStringKeepNulls(llList2String(SITTER_POSES_BY_PRIM,index),["|"],[]);
				SITTER_POSES_IN_PRIM=llListReplaceList(SITTER_POSES_IN_PRIM,[""],(integer)msg,(integer)msg);
				SITTER_POSES_BY_PRIM=llListReplaceList(SITTER_POSES_BY_PRIM,[llDumpList2String(SITTER_POSES_IN_PRIM,"|")],index,index);
				list SITTERS_IN_PRIM=llParseStringKeepNulls(llList2String(SITTERS_BY_PRIM,index),["|"],[]);
				SITTERS_IN_PRIM = llListReplaceList(SITTERS_IN_PRIM,[""],(integer)msg,(integer)msg);
				SITTERS_BY_PRIM = llListReplaceList(SITTERS_BY_PRIM,[llDumpList2String(SITTERS_IN_PRIM,"|")],index,index);
				rez_derez();
			}
		}
	}
	
	changed(integer change){
		if(change & CHANGED_LINK){
			integer IS_SITTER;
			if(llGetAgentSize(llGetLinkKey(llGetNumberOfPrims()))){ // someone is sitting
				IS_SITTER=TRUE;
			}
			else{
				SITTER_PRIMS=[];
				SITTER_POSES_BY_PRIM=[];
				SITTERS_BY_PRIM=[];
			}
			if(IS_SITTER!=ANY_SITTERS){
				ANY_SITTERS=IS_SITTER;
				rez_derez();
			}
		}
	}	
}