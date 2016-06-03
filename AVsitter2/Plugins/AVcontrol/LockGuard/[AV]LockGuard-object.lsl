// Placed in prop objects, this script sends the uuid of any Lockguard rings to the script in furniture.
// Ring prims in the prop should be named with "ring" in their prim name. e.g. "ring1", "ring2"

integer COMM_CHANNEL = -57841689;
integer comm_handle;

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
    on_rez(integer start)
    {
        if (!llGetStartParameter()) return;

        comm_handle = llListen(COMM_CHANNEL, "", NULL_KEY, "INFORM");
    }

    listen(integer listen_channel, string name, key id, string msg)
    {
        list ring_prims = findPrimsWithSubstring("ring");

        llSay(COMM_CHANNEL, llDumpList2String(["ATTACHPOINTS"] + ring_prims, "|"));
        llListenRemove(comm_handle);
    }
}
