// Placed in prop objects, this script sends the uuid of any Lockguard rings to the script in furniture.
// Ring prims in the prop should be named with "ring" in their prim name. e.g. "ring1", "ring2"

integer COMM_CHANNEL = -57841689;

integer comm_handle;

default
{
    on_rez(integer start)
    {
        if (!llGetStartParameter()) return;

        comm_handle = llListen(COMM_CHANNEL, "", NULL_KEY, "INFORM");
    }

    listen(integer listen_channel, string name, key id, string msg)
    {
        list ring_prims;

        integer index;
//      index already defaults to 0 here, no need for (re-)setting the start value to 0
        for(; index <= llGetNumberOfPrims(); index++)
        {
//          if link with name "ring" found / substring-index != -1
            if (~llSubStringIndex(llToLower(llGetLinkName(index)), "ring"))
            {
                ring_prims += [llGetLinkName(index),llGetLinkKey(index)];
            }
        }

        llSay(COMM_CHANNEL, llDumpList2String(["ATTACHPOINTS"] + ring_prims, "|"));
        llListenRemove(comm_handle);
    }
}
