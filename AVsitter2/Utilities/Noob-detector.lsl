/*
 * Noob-detector - Make a report about an AVsitter setup
 *
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

/*
 * Things not implemented:
 * ~ creator of the object
 * ~ which platform/world (OpenSim/SL) and version
 */

integer sendToSupport=FALSE;
integer sendItems = TRUE;
string support_avi = "";

string disclaimer = "This script will inspect your object and create a link you can share with others.\n\nClick OK to proceed.";
string start_message = "Preparing info, please wait...";
string end_message = "Inspection complete! Script removed.";

string product = "Noob Detector";
string version = "1.3";

list allowed_products = ["AVpos","[AV]menu","[AV]object"];

string out;
string next_out;

list notecards_to_read;
key notecard_query;
integer notecard_index;
integer notecard_line;

list item_types = ["TEXTURE","SOUND","LANDMARK","CLOTHING","OBJECT","NOTECARD","SCRIPT","BODYPART","ANIMATION","GESTURE","ALL TYPES"];
list item_ints =  [0,1,3,5,6,7,10,13,20,21];

integer menu_channel;

string url = "https://avsitter.com/settings.php";
string cache;
string webkey;
integer webcount;

add_out(string say, integer force){
    cache+=say;
    if(!force){
        cache+="\n";
    }
    if(llStringLength(llEscapeURL(cache))>1024 || force){
        webcount++;
        llHTTPRequest(url, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded",HTTP_VERIFY_CERT,FALSE], "w="+webkey+"&c="+(string)webcount+"&t="+llEscapeURL(cache));
        cache="";
    }
}

remove_script(){
    llOwnerSay("Diagnostic script removed.");
    llRemoveInventory(llGetScriptName());
}

default {
    state_entry(){
        integer i;
        for(i=0;i<llGetListLength(allowed_products);i++){
            if (llGetInventoryType(llList2String(allowed_products,i))!= INVENTORY_NONE){
                state permission;
            }
        }

        llOwnerSay("Sorry, could not find correct product for this script.");
        remove_script();
    }
}

state permission {
    state_entry(){
        llSetTimerEvent(120);
        llListen((menu_channel=((integer)llFrand(0x7FFFFF80)+1)*-1),"","","");
        llDialog(llGetOwner(),product+" "+version+"\n\n"+disclaimer,["OK"],menu_channel);//RLV
    }

    timer(){
        remove_script();
    }

    listen(integer listen_channel, string name, key id, string message){
        if(message=="OK"){
            state running;
        }
        else{
            remove_script();
        }
    }
}

state running {

    http_response(key request_id, integer status, list metadata, string body){
        llOwnerSay(body);
    }

    state_entry(){

        webkey=(string)llGenerateKey();

        llDialog(llGetOwner(),product+" "+version+"\n\n"+start_message,["OK"],menu_channel);
        llOwnerSay(start_message);

        add_out("Share this info to get help with your AVsitter build!\n",FALSE);
        add_out("----START----",FALSE);

        add_out("user: "+llKey2Name(llGetOwner())+" ("+(string)llGetOwner()+")",FALSE);

        list object_perms_owner;
        integer perms = llGetObjectPermMask(MASK_OWNER);
        if (perms & PERM_COPY) object_perms_owner += "C";
        if (perms & PERM_MODIFY) object_perms_owner += "M";
        if (perms & PERM_TRANSFER) object_perms_owner += "T";

        list object_perms_next;
        perms = llGetObjectPermMask(MASK_NEXT);
        if (perms & PERM_COPY) object_perms_next += "C";
        if (perms & PERM_MODIFY) object_perms_next += "M";
        if (perms & PERM_TRANSFER) object_perms_next += "T";


        add_out("owner perms:["+llDumpList2String(object_perms_owner,"/")+"]",FALSE);
        add_out("next perms:["+llDumpList2String(object_perms_next,"/")+"]",FALSE);

        // Total prims

        add_out("total prims: "+(string)llGetObjectPrimCount(llGetKey()),FALSE);

        // Link number

        add_out("my link number: "+(string)llGetLinkNumber(),FALSE);

        // Read through all prims giving name and description

        add_out("\n----PRIMS----",FALSE);

        add_out("Prim, Name, Desc",FALSE);

        integer i;

        if(llGetObjectPrimCount(llGetKey())>1){
            i=1;
        }

        while (i<=llGetObjectPrimCount(llGetKey())){
            list data = llGetLinkPrimitiveParams(i,[PRIM_NAME,PRIM_DESC]);
            add_out((string)i+", "+llDumpList2String(data,", "),FALSE);
            i++;

            if(llGetObjectPrimCount(llGetKey())==1){
                jump end;
            }
        }
        @end;

        // Inventory

        string line;

        integer j;
        for (j=0;j<llGetListLength(item_types);j++){

            integer type = llList2Integer(item_ints,j);

            integer type_heading_sent=FALSE;
            integer count=0; // need this instead of using i because otherwise there's a gap in numbering when we skip this script
            for (i=0;i<llGetInventoryNumber(type);i++){

                if(!type_heading_sent){
                    add_out("\n----"+llList2String(item_types,j)+"S----",FALSE);
                    type_heading_sent=TRUE;
                }

                string name = llGetInventoryName(type,i);
                if(name!=llGetScriptName()){

                    list perms_owner;
                    perms = llGetInventoryPermMask(name, MASK_OWNER);
                    if (perms & PERM_COPY){
                        perms_owner += "C";
                        if (perms & PERM_TRANSFER){
                            //if(name=="AVpos"){
                                if(sendItems && type!=INVENTORY_ANIMATION){
                                    if(sendToSupport){
                                        llGiveInventory(support_avi,name);
                                    }
                                }
                            //}
                            }
                            if (type==INVENTORY_NOTECARD){
                                if (perms & PERM_COPY){
                                    notecards_to_read+=name; // read notecard!
                                }
                            }
                    }
                    if (perms & PERM_MODIFY) perms_owner += "M";
                    if (perms & PERM_TRANSFER) perms_owner += "T";

                    list perms_next;
                    perms = llGetInventoryPermMask(name, MASK_NEXT);
                    if (perms & PERM_COPY) perms_next += "C";
                    if (perms & PERM_MODIFY) perms_next += "M";
                    if (perms & PERM_TRANSFER) perms_next += "T";

                    string warnings;
                    integer index = llSubStringIndex(name,"  ");
                    if(index!=-1){
                        warnings+="~DOUBLE-SPACE IN NAME!~";
                    }

                    if(type==INVENTORY_SCRIPT){
                        if(llGetScriptState(name)==FALSE){
                            warnings+="~NOT RUNNING!~";
                        }
                    }
                    count++;
                    add_out((string)count+"."+name+" ["+llDumpList2String(perms_owner,"/")+"]["+llDumpList2String(perms_next,"/")+"]"+warnings,FALSE);

                }
            }
        }
        state read_notecards;
    }
}

state read_notecards{

    state_entry(){
        if(llList2String(notecards_to_read,notecard_index)!=""){
            add_out("\n"+llList2String(notecards_to_read,notecard_index)+" (notecard)\n-----------",FALSE);
            notecard_query=llGetNotecardLine(llList2String(notecards_to_read,notecard_index),notecard_line);
        }
        else{
            state end;
        }
    }

    dataserver(key query_id, string body){
        if(query_id == notecard_query){
            if (body != EOF){
                add_out(body,FALSE);
                notecard_query=llGetNotecardLine(llList2String(notecards_to_read,notecard_index),++notecard_line);
            }
            else{
                notecard_index++;
                if(llList2String(notecards_to_read,notecard_index)!=""){
                    notecard_line=0;
                    string line = "\n"+llList2String(notecards_to_read,notecard_index)+"\n-----------";
                    add_out(line,FALSE);
                    notecard_query=llGetNotecardLine(llList2String(notecards_to_read,notecard_index),notecard_line);
                }
                else{
                    state end;
                }
            }
        }
    }

}

state end{
    state_entry(){
        add_out("\nSummary created by the \"Noob-detector script\" from the AVsitter2 utilities box (https://avsitter.github.io/avsitter2_utilities.html)",FALSE);
        add_out("\n\n----END----\n\nend",TRUE);

        string url_final = url+"?q="+webkey;

        llOwnerSay(end_message);
        llOwnerSay("Your link is: "+url_final);

        if(sendToSupport){
            llInstantMessage(support_avi,url_final);
        }

        llLoadURL(llGetOwner(),end_message+" Get link from chat or click here.",url_final);

        llRemoveInventory(llGetScriptName());
    }
}
