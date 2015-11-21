/******************************************************************
* Shared props with BUTTON (alpha) v0.01a
* Allows props to be rezzed by button. They won't derez when sitters "swap" or if only one avatar stands up.
* Requires [AV]prop script from AVsitter2 box 2.1-09.01 or later.
* Shared props should use PROP3 in the AVpos notecard (a special prop type specifically for shared props).
* 
* example use:

BUTTON myprop|555 <--- rez the prop
BUTTON [CLEAR]|555 <--- clear all props
BUTTON remprop_myprop|555 <--- derez the prop
PROP3 myprop|object|0|<0,0,0><0,0,0> <--- define the prop (in any SITTER)

******************************************************************/


/******************************************************************
* DON'T EDIT BELOW THIS UNLESS YOU KNOW WHAT YOU'RE DOING!
******************************************************************/

default{
	link_message(integer sender, integer num, string msg, key id){
		if(num==555){
			llMessageLinked(LINK_THIS,90220,"remprop_"+msg,""); //remove the prop
			llMessageLinked(LINK_THIS,90220,msg,""); //rez the prop
			llMessageLinked(LINK_THIS,90005,"",id); //give back the menu
		}
	}	
}