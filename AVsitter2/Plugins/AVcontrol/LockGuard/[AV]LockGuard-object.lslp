
// Placed in prop objects, this script sends the uuid of any Lockguard rings to the script in furniture.
// Ring prims in the prop should be named with "ring" in their prim name. e.g. "ring1", "ring2"

integer COMM_CHANNEL = -57841689;

integer comm_handle;

default{
	
	on_rez(integer start){
		if(llGetStartParameter()){ 
			comm_handle = llListen(COMM_CHANNEL,"","","INFORM");
		}
	}
	
	listen(integer listen_channel, string name, key id, string msg){
		list ring_prims;
		integer i;
		for(i=0;i<=llGetNumberOfPrims();i++){
			if (llSubStringIndex(llToLower(llGetLinkName(i)),"ring")!=-1){
				ring_prims += [llGetLinkName(i),llGetLinkKey(i)];	
			}				
		}
		llSay(COMM_CHANNEL,llDumpList2String(["ATTACHPOINTS"]+ring_prims,"|"));
		llListenRemove(comm_handle);
	}
}
