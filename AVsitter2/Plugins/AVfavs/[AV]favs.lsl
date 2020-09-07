/*
 * [AV]favs - Allow users to have favourite lists
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

// Sitter UUIDs list, 1 entry per sitter. To save memory, UUIDs are stored as strings.
list Sitters;

// Poses being played per sitter.
list Poses;

// List made of sublists
// Each sublist starts with the string "UUID+sitter#" and ends with the string "|".
// The data is between these markers, as a list of pose names.
list Favs;

// Dialog channel
integer CDialog;
// Dialog handle
integer HDialog;
// Page number (actually the index of the first entry)
integer Page;
// Sublist of the data for the current user
list List;

list dlg()
{
    list btns;
    if (llGetListLength(List) > 11)
    {
        btns = llList2List(List, Page, Page + 8)
            + "[BACK]" + "[<<]" + "[>>]";
    }
    else
    {
        btns = List + "[BACK]";
    }
    return llList2List(btns, -3, -1) + llList2List(btns, -6, -4)
        + llList2List(btns, -9, -7) + llList2List(btns, -12, -10);
}

default
{
    link_message(integer l, integer n, string s, key k)
    {
        if (n == 90060) // sit
        {
            n = (integer)s;
            while (n + 1 > llGetListLength(Sitters))
            {
                Sitters += "";
                Poses += "";
            }
            Sitters = llListReplaceList(Sitters, (list)((string)k), n, n);
            Poses = llListReplaceList(Poses, (list)"", n, n);
            return;
        }

        if (n == 90030) // swap
        {
            n = (integer)s;
            l = (integer)((string)k);
            while (1 + (l + (n - l) * (n > l)) > llGetListLength(Sitters))
            {
                Sitters += "";
                Poses += "";
            }
            // swap sitter uuids
            Sitters =
                llListReplaceList(
                llListReplaceList(Sitters,
                llList2List(Sitters, l, l), n, n),
                llList2List(Sitters, n, n), l, l);
            // clear poses
            Poses = llListReplaceList(llListReplaceList(Poses, (list)"", l, l), (list)"", n, n);
            return;
        }

        if (n == 90065) // unsit
        {
            n = (integer)s;
            // clear sitter and pose
            Sitters = llListReplaceList(Sitters, (list)"", n, n);
            Poses = llListReplaceList(Poses, (list)"", n, n);
            return;
        }

        if (n == 90045) // Pose playing
        {
            // Remember the pose that is playing for each sitter
            n = (integer)s;
            s = llList2String(llParseStringKeepNulls(s, (list)"|", []), 1);
            Poses = llListReplaceList(Poses, (list)s, n, n);
            return;
        }

        if (n == 90401) // add pose to favs
        {
            llMessageLinked(LINK_THIS, 90005, "", k);
            if (llGetUsedMemory() > 60000)
            {
                llRegionSayTo(k, 0, "Memory full");
                return;
            }
            n = llListFindList(Sitters, (list)((string)k));
            if (n != -1)
            {
                s = llList2String(Poses, n);
                if (s == "")
                    return; // something went wrong, we don't have info about the current pose
                // n is still the sitter.
                // Find the sublist corresponding to the current avi/sitter.
                l = llListFindList(Favs, (list)((string)k+(string)n));
                if (l != -1)
                {
                    // Start of sublist found, find end of it.
                    // Begin searching right after the list start.
                    n = l + 1;
                    // End position where the "|" is
                    l = llListFindList(llList2List(Favs, n, -1), (list)"|") + n;
                }
                else
                {
                    // Sublist not found, add empty one for this avi/sitter.
                    // Start position
                    l = 1 + llGetListLength(Favs);
                    Favs = Favs + ((string)k+(string)n) + "|";
                    n = l;
                }
                // Here, n is always the first element after the uuid+sitter,
                // l is always the closing "|"
            }
            if (n != -1)
            {
                if (llListFindList(llList2List(Favs, n, l), (list)s) != -1)
                {
                    llRegionSayTo(k, 0, "This pose is " + "already" + " in the favs for this seat");
                    return;
                }
                // Replace the "|" with the pose + "|"
                Favs = llListReplaceList(Favs, (list)s + "|", l, l);
                llRegionSayTo(k, 0, s + " added to favs");
            }
            return;
        }

        if (n == 90402) // remove pose from favs
        {
            llMessageLinked(LINK_THIS, 90005, "", k);
            n = llListFindList(Sitters, (list)((string)k));
            if (n != -1)
            {
                // n is the sitter number
                s = llList2String(Poses, n);
                n = llListFindList(Favs, (list)((string)k+(string)n));
                // now n is the position of the start marker of the sublist
                if (n != -1)
                {
                    ++n;
                    // Find the end of the sublist (guaranteed to exist)
                    l = llListFindList(llList2List(Favs, n, -1), (list)"|") + n;
                    // Find the pose within the sublist
                    l = llListFindList(llList2List(Favs, n, l), (list)s) + n;
                }
                else
                    l = n - 1; // force error

                if (l < n) // means llListFindList returned -1, or the start of the list was not found
                {
                    llRegionSayTo(k, 0, "This pose is " + "not" + " in the favs for this seat");
                    return;
                }
                Favs = llDeleteSubList(Favs, l, l);
                llRegionSayTo(k, 0, s + " removed from favs");
                // If the favs list for this avatar/sitter combo becomes empty, remove the markers too
                if (llStringLength(llList2String(Favs, l - 1)) > 36 && llList2String(Favs, l) == "|")
                {
                    Favs = llDeleteSubList(Favs, l - 1, l);
                }
            }
            return;
        }

        if (n == 90403) // List Favorites, allow user to pick one to play
        {
            n = llListFindList(Sitters, (list)((string)k));
            if (n != -1)
            {
                // Find sublist start marker
                n = llListFindList(Favs, (list)((string)k + (string)n));
                if (n != -1)
                {
                    // Find sublist end marker
                    l = llListFindList(llList2List(Favs, ++n, -1), (list)"|");
                    if (l < 1)
                        n = -1; // If the list does not have at least 1 element, mark error
                    else
                        l += n - 1; // otherwise adjust to point to the last element before the "|"
                }
            }
            if (n == -1)
            {
                llRegionSayTo(k, 0, "No favs found for this seat");
                llMessageLinked(LINK_THIS, 90005, "", k);
                return;
            }
            if (HDialog)
                llListenRemove(HDialog);

            CDialog = 0x30000000+(integer)llFrand(16777216);
            HDialog = llListen(CDialog, "", "", "");
            Page = 0;
            List = llListSort(llList2List(Favs, n, l), 1, TRUE);
            llDialog(k, "Your favs for this seat:", dlg(), CDialog);
        }
    }

    listen(integer i, string n, key k, string s)
    {
        if (s == "[BACK]")
        {
            llListenRemove(HDialog);
            HDialog = 0;
            llMessageLinked(LINK_THIS, 90005, "", k);
            return;
        }
        if (s == "[<<]")
        {
            Page = Page + -9;
            if (Page < 0)
                Page = (llGetListLength(Favs) - 1) / 9 * 9;
        }
        if (s == "[>>]")
        {
            Page = Page + 9;
            if (Page >= llGetListLength(Favs))
                Page = 0;
        }
        if (-1 != llListFindList(List, (list)s))
        {
            llMessageLinked(LINK_THIS, 90008, s, k);
        }
        llDialog(k, "Your favs for this seat:", dlg(), CDialog);
    }
}
