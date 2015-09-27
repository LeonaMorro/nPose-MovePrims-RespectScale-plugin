// LSL script generated - patched Render.hs (0.1.6.2): LSLScripts.nPose MovePrims RespectScale plugin.lslp Sun Sep 27 12:01:46 Mitteleuropäische Sommerzeit 2015
// Started at: 04.05.2013 17:04:00
// Author: XandrineX and Perl Nakajima
// slmember1, 13.04.2015: Added a scale referenz
// slmember1, 29.08.2015: fixed convert function

string gSET_SEPARATOR = "~";
string gSUB_SEPARATOR = "#";

// description => linkId
list gPrimIDs = [];

build_prim_ids(){
    gPrimIDs = [];
    integer number_of_prims = llGetNumberOfPrims();
    integer i;
    for (i = 2; i < number_of_prims + 1; ++i) {
        string desc = llList2String(llGetLinkPrimitiveParams(i,[28]),0);
        gPrimIDs += [desc,i];
    }
}

// abbreviate dump
string convert(float value,integer precision){
    string sValue = (string)((float)llRound(value * llPow(10,precision)) / llPow(10,precision));
    string char;
    do  {
        char = llGetSubString(sValue,-1,-1);
        if (char == "." || char == "0") {
            sValue = llDeleteSubString(sValue,-1,-1);
        }
    }
    while (char == "0");
    return sValue;
}

dump_prim_info(){
    vector sizeRootPrim = llList2Vector(llGetLinkPrimitiveParams(1,[7]),0);
    string sizeRootPrimStr = "<" + llDumpList2String([convert(sizeRootPrim.x,4),convert(sizeRootPrim.y,4),convert(sizeRootPrim.z,4)],",") + ">";
    build_prim_ids();
    list collector;
    integer length = llGetListLength(gPrimIDs);
    integer i;
    for (i = 0; i < length; i += 2) {
        string descr = llList2String(gPrimIDs,i);
        if (llStringLength(descr) > 0 && descr != "(No Description)") {
            integer linkId = llList2Integer(gPrimIDs,i + 1);
            vector posLocal = llList2Vector(llGetLinkPrimitiveParams(linkId,[33]),0);
            rotation rotLocal = llList2Rot(llGetLinkPrimitiveParams(linkId,[29]),0);
            string posLocalStr = "<" + llDumpList2String([convert(posLocal.x,4),convert(posLocal.y,4),convert(posLocal.z,4)],",") + ">";
            string rotLocalStr = "<" + llDumpList2String([convert(rotLocal.x,4),convert(rotLocal.y,4),convert(rotLocal.z,4),convert(rotLocal.s,4)],",") + ">";
            string toAdd = llDumpList2String([descr,posLocalStr,rotLocalStr,sizeRootPrimStr],gSUB_SEPARATOR);
            collector += [llStringLength(toAdd),toAdd];
        }
        else  {
            llOwnerSay("No description for primId=" + llList2String(gPrimIDs,i + 1) + ", skipping...");
        }
    }
    llOwnerSay("Copy and cleanup the following lines to your notecard:");
    dumpCollector(llListSort(collector,1,1));
}

dumpCollector(list collector){
    integer collectorLength = llGetListLength(collector);
    string output = "SATMSG|27131|";
    integer startLength = llStringLength(output);
    integer i;
    for (i = 0; i < collectorLength; i += 2) {
        integer outLength = llStringLength(output);
        integer setLength = llList2Integer(collector,i);
        if (outLength == startLength) {
            if (outLength + setLength < 253) {
                output += llList2String(collector,i + 1);
            }
            else  {
                llOwnerSay("ERROR: too long for Notecard: " + llList2String(collector,i + 1));
                return;
            }
        }
        else  if (outLength + setLength + 1 < 253) {
            output += gSET_SEPARATOR + llList2String(collector,i + 1);
        }
        else  {
            llOwnerSay("\n" + output);
            output = "SATMSG|27131|" + llList2String(collector,i + 1);
        }
    }
    if (output != "SATMSG|27131|") {
        llOwnerSay("\n" + output);
    }
}

set_prims(string message){
    list moveSets = llParseStringKeepNulls(message,[gSET_SEPARATOR],[]);
    integer length = llGetListLength(moveSets);
    vector currentSizeRootPrim = llList2Vector(llGetLinkPrimitiveParams(1,[7]),0);
    integer i;
    for (i = 0; i < length; ++i) {
        list parts = llParseString2List(llList2String(moveSets,i),[gSUB_SEPARATOR],[]);
        integer index = llListFindList(gPrimIDs,[llList2String(parts,0)]);
        if (index == -1) {
            llOwnerSay("Invalid part: " + llDumpList2String(parts,gSUB_SEPARATOR));
        }
        else  {
            vector scaleFactor;
            vector defaultSizeRootPrim = (vector)llList2String(parts,3);
            if (defaultSizeRootPrim.x == 0.0 || defaultSizeRootPrim.y == 0.0 || defaultSizeRootPrim.z == 0.0) {
                scaleFactor = <1.0,1.0,1.0>;
            }
            else  {
                scaleFactor = <currentSizeRootPrim.x / defaultSizeRootPrim.x,currentSizeRootPrim.y / defaultSizeRootPrim.y,currentSizeRootPrim.z / defaultSizeRootPrim.z>;
            }
            vector newPosition = (vector)llList2String(parts,1);
            newPosition = <newPosition.x * scaleFactor.x,newPosition.y * scaleFactor.y,newPosition.z * scaleFactor.z>;
            llSetLinkPrimitiveParamsFast(llList2Integer(gPrimIDs,index + 1),[33,newPosition,29,(rotation)llList2String(parts,2)]);
        }
    }
}

default {


	// msg: primdesc1#<local_pos1>#<local_rot1>~primdesc2#<local_pos2>#<local_rot2>~...
	link_message(integer primId,integer cmdId,string message,key objectKey) {
        if (cmdId == 27131) {
            build_prim_ids();
            set_prims(message);
        }
        else  if (cmdId == 27130) {
            build_prim_ids();
            dump_prim_info();
        }
    }
}
