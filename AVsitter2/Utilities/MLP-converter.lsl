// MLP to AVsitter converter
// Converts POSE and SYNC only! (facial expressions, props, submenus are not implemented yet)
// You can enter a position offset vector in the description such as <0,0,0.1>

string product = "AVsitter2 MLP converter";
string version = "2.1";

string notecard_basename = "AVpos";

list NOTECARDS;
list PROPS_NOTECARDS;

string notecard_name;
key notecard_query;
integer notecard_line;
integer notecard_pointer;
integer animator_count;
integer animator_total;

list ommit = ["default","stand"];

integer verbose = 0;
Out(integer level,string out){
    if(verbose>=level){
        llOwnerSay(llGetScriptName()+"["+version+"] "+out);
    }
}

/*
"Fixed number of decimals version" from
http://wiki.secondlife.com/wiki/User:Pedro_Oval/Float_formatting_functions
*/
string FormatFloat(float f, integer num_decimals){
    float rounding = (float)(".5e-" + (string)num_decimals) - 0.0000005;
    if (f < 0.) f -= rounding; else f += rounding;
    string ret = llGetSubString((string)f, 0, num_decimals - !num_decimals - 7);
    
    //if ((float)ret == 0.) ret = "0";
    
    if(llSubStringIndex(ret,".")!=-1){
        while(llGetSubString(ret,-1,-1)=="0"){
            ret = llGetSubString(ret,0,-2);
        } 
    }
    if(llGetSubString(ret,-1,-1)=="."){
        ret = llGetSubString(ret,0,-2);
    }
    return ret;
}

finish(){
    if(llSubStringIndex(llGetObjectName(),"Utilities")==-1){
        Out(0,"Removing script");
        llRemoveInventory(llGetScriptName());
    }
}

get_notecards(){
    integer i;
    for(i=0;i<llGetInventoryNumber(INVENTORY_NOTECARD);i++){
        string name = llGetInventoryName(INVENTORY_NOTECARD,i);
        if(llGetSubString(name,0,9)==".MENUITEMS" || llGetSubString(name,0,9)==".POSITIONS"){ //must be in alphabetical order (MENUITEMS FIRST)
            NOTECARDS+=name;
        }
        else if(llGetSubString(name,0,5)==".PROPS"){
            PROPS_NOTECARDS+=name; // not implemented
        }
    }
    //llOwnerSay(llDumpList2String(NOTECARDS,","));
}


Readout_Say(string say){
    string objectname = llGetObjectName();
    llSetObjectName("");
    llRegionSayTo(llGetOwner(),0,"◆"+say);
    llSetObjectName(objectname);
}

default{
    state_entry(){
        Out(0,"Reading MLP notecards...");
        Readout_Say(" ");
        get_notecards();
        //state part_two;
        if(llGetListLength(NOTECARDS)>0){
            notecard_name = llList2String(NOTECARDS,notecard_pointer);
            Readout_Say("--✄--COPY BELOW INTO "+notecard_basename+" NOTECARD--✄--");
            Readout_Say(" ");
            //llOwnerSay("N: "+notecard_name);
            
            Readout_Say("SITTER "+(string)animator_count);
            notecard_query = llGetNotecardLine(notecard_name,notecard_line);
        }
        else{
            Out(0,"No MLP notecards found!");
            finish();
        }
    }
       
    dataserver(key query_id, string data){
        //llOwnerSay((string)notecard_line);
        if(query_id==notecard_query){
            if(data == EOF){
                if(llGetListLength(NOTECARDS)-notecard_pointer>1){
                    notecard_name = llList2String(NOTECARDS,notecard_pointer+=1);
                    //llOwnerSay("N: "+notecard_name);
                    notecard_query = llGetNotecardLine(notecard_name,notecard_line=0);
                }
                else if (animator_count+1<animator_total){
                    animator_count++;
                    Readout_Say(" ");
                    Readout_Say("SITTER "+(string)animator_count);
                    notecard_name = llList2String(NOTECARDS,notecard_pointer=0);
                    notecard_query = llGetNotecardLine(notecard_name,notecard_line=0);
                }
                else{
                    //state part_two;
                    Readout_Say(" ");
                    Readout_Say("--✄--COPY ABOVE INTO "+notecard_basename+" NOTECARD--✄--");
                    finish();
                }
            }
            else{
                string out;
                data = llStringTrim(llList2String(llParseString2List(data,["//"],[]),0),STRING_TRIM);
                if(llGetSubString(notecard_name,0,9)==".MENUITEMS"){
                    string command = llGetSubString(data,0,llSubStringIndex(data," ")-1);
                    list parts = llParseString2List(llGetSubString(data,llSubStringIndex(data," ")+1,-1),[" | "," |","| ","|"],[]);        
                    if(command=="TOMENU" || command =="MENU"){
                        /*
                        if(llListFindList(["-","MAIN MENU","Height","OPTIONS","ShutDown..."],[llList2String(parts,0)])==-1){
                            if(command =="MENU"){
                                Readout_Say(" ");
                            }
                            out+=command+" "+llList2String(parts,0);
                            Readout_Say(out);
                        }
                        */
                    }
                    else if(command=="POSE"){
                        if(llListFindList(ommit,[llList2String(parts,0)])==-1){
                            if(llGetListLength(parts)-1>animator_total){
                                animator_total=llGetListLength(parts)-1;
                            }
                            if(llGetListLength(parts)-animator_count>1){
                                out = "POSE ";
                                if(llGetListLength(parts)+animator_count>2){
                                    out = "SYNC ";
                                }
                                string pose = llStringTrim(llList2String(parts,animator_count+1),STRING_TRIM);
                                pose = llList2String(llParseString2List(pose,["::"],[]),0); //remove MLP facial expressions
                                pose = llList2String(llParseString2List(pose,[";"],[]),0); //remove XPOSE facial expressions
                                
                                out+=llStringTrim(llList2String(parts,0),STRING_TRIM)+"|"+pose;
                                Readout_Say(out);
                            }
                        }
                    }
                }
                else{//POSITIONS
                    if (llSubStringIndex(data,"{")!=-1){//llGetSubString(data,0,0)=="{"){
                        string command = llStringTrim(llGetSubString(data,llSubStringIndex(data,"{")+1,llSubStringIndex(data,"}")-1),STRING_TRIM);
                        if(llListFindList(ommit,[command])==-1){
                            data = llDumpList2String(llParseString2List(data,[" "],[""]),"");//remove spaces
                            list parts = llParseString2List(data,["<"],[]);
                            if(llGetListLength(parts)>animator_count*2+1){
                                vector pos = (vector)("<"+llList2String(parts,animator_count*2+1));
                                vector rot = (vector)("<"+llList2String(parts,animator_count*2+2)); 
                                pos+= (vector)llGetObjectDesc();
			                	string result = "<"+FormatFloat(pos.x,3)+","+FormatFloat(pos.y,3)+","+FormatFloat(pos.z,3)+">";
            				    result += "<"+FormatFloat(rot.x,1)+","+FormatFloat(rot.y,1)+","+FormatFloat(rot.z,1)+">";
                            	Readout_Say("{"+command+"}"+result);    
                            }
                        }
                    }
                }
                notecard_query = llGetNotecardLine(notecard_name,notecard_line+=1);    
            }
        }
    }
}

