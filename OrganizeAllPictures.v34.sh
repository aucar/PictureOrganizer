#!/bin/bash

# This file is part of the PictureOrganizer distribution (https://github.com/aucar/PictureOrganizer).
# Copyright (c) 2015 Ahmet Ucar.
# http://www.ahmetucar.org
# 
# This program is free software: you can redistribute it and/or modify  
# it under the terms of the GNU General Public License as published by  
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


# RELEASE NOTES
# v.34
# Cleanup

clear

SCRIPTVERSION="v.34"
PRESUMEDATES=0
PRESUMELOCATIONS=0

#Will be assigned later
DEBUGFILE=""



function Bootstrap(){

	# Find Current Directory
	CURRDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	DEBUGFILE="${CURRDIR}/`date +%Y-%m-%d`.htm"

	
	
	
    Print_In_Color c "*************************************************************************"
    Print_In_Color c "*** "

    Print_In_Color c "*** Script Version              : $SCRIPTVERSION"
    
    if [ "${BASH_VERSINFO}" -lt 4 ]; then 
    
        Print_In_Color r "*** Bash Version                : $BASH_VERSION"
        Print_In_Color r "Sorry, you need at least bash-4.0 to run this script." >&2; 
        exit 1
    else
        Print_In_Color g "*** Bash Version                : $BASH_VERSION"
    fi  
    
    
    



if [ -d "$CURRDIR" ]; then
    Print_In_Color g "*** Working Directory           : $CURRDIR" 
fi



    Print_In_Color c "*** Debug File                  : $DEBUGFILE" 


# Find Where The Applications Are
# Used readlink to get absolute path
APPDIR=$(readlink -f "${CURRDIR}/Applications/Windows/")

if [ -d "$APPDIR" ]; then
    Print_In_Color g "*** Application Directory Found : $APPDIR" 
fi

# Find Exif Tool
EXIF="${APPDIR}/exiftool/exiftool(-k).exe"

if [ ! -f ${EXIF} ]; then
    Print_In_Color r "*** ERROR                       : EXIF not found!"
else
    Print_In_Color g "*** EXIF Tool Version           : $(echo -ne '\n' | ${EXIF} -ver)" 
fi

# Find JQ Tool
JQ="${APPDIR}/jq/jq.exe"

if [ ! -f ${JQ} ]; then
    Print_In_Color r "*** ERROR                       : JQ not found!"
else
    Print_In_Color g "*** JQ Tool Version             : $(${JQ} --version)" 
fi


SOURCEDIR="${CURRDIR}/UnorganizedFiles"
    Print_In_Color c "*** Source Directory            : $SOURCEDIR" 
    
TARGETDIR="${CURRDIR}/OrganizedFiles"
    Print_In_Color c "*** Target Directory            : $TARGETDIR"

    
LASTPICYEAR="2016"
LASTPICMONTH="Unknown"
LASTPICDATE="Unknown"
LASTPICLOCATION="[Unknown]"

TOTALFILECOUNT=$(find $SOURCEDIR -type f -not -name '*.sh' -not -name '.picasa.ini' | wc -l)
    Print_In_Color c "*** File Count in Source Dir    : $TOTALFILECOUNT"

FILECOUNTER=0



DATEPRESUMED=0
YEARPRESUMED=0
MONTHYEARPRESUMED=0

DATESOURCE=0
#0 DateTimeOriginal
#1 MediaCreationDate
#2 CreateDate
#3 Presumed
#4 Not Presumed


LOCATIONSOURCE=0
#1 Cache
#2 Google
#3 Presumed
#4 Not Presumed

AREA2="NL DE BE FR LU MO ES JP MA"


    
Print_In_Color c "*** "
Print_In_Color c "*************************************************************************"

}


function Print_In_Color() {
  local code="\033["
  case "$1" in
    black  | bk) color="${code}0;30m";;
    red    |  r) color="${code}1;31m";;
    green  |  g) color="${code}1;32m";;
    yellow |  y) color="${code}1;33m";;
    blue   |  b) color="${code}1;34m";;
    purple |  p) color="${code}1;35m";;
    cyan   |  c) color="${code}1;36m";;
    gray   | gr) color="${code}0;37m";;
    *) local text="$1"
  esac
  [ -z "$text" ] && local text="$color$2${code}0m"
  echo "$2<br />" >> "$DEBUGFILE"
  printf "$text\n"
}

function Get_Safe_String {
  #echo $(echo "$1" | sed -e "s/[^A-Za-z0-9._-]/_/g")
  echo "${1//[[:cntrl:]|!@#$%^&*()]}"
}

function Get_Absolute_Path {
  cd "$(dirname '$1')" &>/dev/null && printf "%s/%s" "$PWD" "${1##*/}"
}


function ListContains() {
  for word in $1; do
    [[ $word = $2 ]] && return 0
  done
  return 1
}

function Write_GEO_Code_To_Cache () {
   #Call me like ReadGEOCode "36.88,34.82"
    local COORD="$1"
    
    #echo ${COORD}
    #echo "http://maps.googleapis.com/maps/api/geocode/json?latlng=${COORD}&sensor=true"
    #curl -s "http://maps.googleapis.com/maps/api/geocode/json?latlng=${COORD}&sensor=true"
    
    #Read last line
    #GEONAME=$(curl -s "http://maps.googleapis.com/maps/api/geocode/json?latlng=$COORD&sensor=true" | ${JQ} -r '"[\(.results[0].address_components[] | select(.types[] | contains("country")) | .short_name), \(.results[0].address_components[] | select(.types[] | contains("administrative_area_level_1") // contains("administrative_area_level_2")) | .long_name)] \(.results[0].address_components[] | select(.types[] | contains("route")) | .long_name)"' | tail -n +2)
    
    #Read first line
    if [ "${COORD}" != "" ]; then
    
        CURLED="$(curl -s "http://maps.googleapis.com/maps/api/geocode/json?latlng=$COORD&sensor=true")"
    
        COUNTYNAME="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("country")) | .short_name')"
        
        
        
        if ListContains "$AREA2" "$COUNTYNAME"; then
            AREANAME="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("administrative_area_level_2")) | .long_name')"
            
            if [ "${AREANAME}" == "" ]; then
                AREANAME="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("administrative_area_level_1")) | .long_name')"
            fi  
            
        else
            AREANAME="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("administrative_area_level_1")) | .long_name')"
            
            if [ "${AREANAME}" == "" ]; then
                AREANAME="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("administrative_area_level_2")) | .long_name')"
            fi              
            
        fi  
        
            
        ROUTENAME="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("route")) | .long_name')"
        #ROUTENAME="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("locality")) | .long_name')"
        
        #echo "ROUTENAME : ${ROUTENAME}"
        
        if ListContains "$AREA2" "$COUNTYNAME"; then
            echo
        else
            AREA3="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("administrative_area_level_3")) | .long_name')"
            if [ "${AREA3}" != "" ]; then
                ROUTENAME="${AREA3}"
            fi  
            
            #echo "AREA3 : ${AREA3}"
            
            AREA4="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] | contains("administrative_area_level_4")) | .long_name')"
            if [ "${AREA4}" != "" ]; then
                ROUTENAME="${AREA4}"
            fi          
            
            #echo "AREA4 : ${AREA4}"
            
            
            LOCALITY="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] == "locality") | .long_name')"
            if [ "${LOCALITY}" != "" ]; then
                ROUTENAME="${LOCALITY}"
            fi          
        fi
        
        SUBLOCALITYONE="$(echo $CURLED | ${JQ} -r '.results[0].address_components[] | select(.types[] == "sublocality_level_1") | .long_name')"
        if [ "${SUBLOCALITYONE}" != "" ]; then
            ROUTENAME="${SUBLOCALITYONE}"
        fi  
        
        #echo "LOCALITY : ${LOCALITY}"
        
        if [ "${ROUTENAME}" == "" ]; then
            ROUTENAME="Unknown"
        fi  
        
        #echo "ROUTENAME : ${ROUTENAME}"
        
    
        
        GEONAME="[$COUNTYNAME, $AREANAME, $ROUTENAME]"
        
    else
        GEONAME=""
    fi
    
    
    if [ "${GEONAME}" != "[, ] " ]; then
       echo "$COORD = $GEONAME" >> geocodes.ini 
       echo "$GEONAME"
    else
       echo ""
    fi  
    
    
    
    
}

function Get_GEO_Code_From_Cache () {
   #Call me like Get_GEO_Code_From_Cache "36.88,34.82"

   local GEONAME=$(sed -n "s/.*$1 *= *\([^ ]*.*\)/\1/p" < geocodes.ini | head -1)
    
   echo "$GEONAME"
}

function CopyFileToFolder () {
   #Call me like CopyFileToFolder "A/pic.jpg" "target"
   
   source="$1"
   destination="$2"

    #Extract file name and extension
    file=${source##*/}
    namewoext=${file%.*}
    ext=${file##*.}

if [[ ! -e "$destination/$namewoext.$ext" ]]; then
    # file does not exist in the destination directory
    cp "$source" "$destination"
    RENAMEDTARGETFILE="$destination/$namewoext.$ext"
else
    num=2
    #echo "$destination/[$num]$namewoext.$ext" 
    
    while [[ -e "$destination/[$num]$namewoext.$ext" ]]; do
        (( num++ ))
    done
    cp "$source" "$destination/[$num]$namewoext.$ext" 
    RENAMEDTARGETFILE="$destination/[$num]$namewoext.$ext"
fi    
   
IsFileCopied "$source" "$RENAMEDTARGETFILE"
   
}

function IsFileCopied () {
   #Call me like CopyFileToFolder "A/pic.jpg" "target"
   
   source="$1"
   destination="$2"

if [ ! -f "${RENAMEDTARGETFILE}" ]; then
    echo "I could not copy '$source' to '$destination'" >> "${CURRDIR}/errors.txt"
fi
}


# Date Functions

function Get_Year_From_Picture {

	DATESOURCE=0
    
	local tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %Y -DateTimeOriginal "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"
	
	if [ "$tmpdate" = "" ]; then
        tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %Y -MediaCreateDate "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"
		DATESOURCE=1
    fi
	
	if [ "$tmpdate" = "" ]; then
        tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %Y -CreateDate "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"
		DATESOURCE=2
    fi

	
	#If there is no date info
	if [ "$tmpdate" == "" ]; then

		if [ $PRESUMEDATES -eq 1 ]; then
			Presume_Date_If_Necessary "year"
			tmpdate="$PICYEAR"
			DATESOURCE=3
		else
			tmpdate="Unknown"
			DATESOURCE=4
		fi	
	
	fi
	
	echo "$tmpdate"
	return ${DATESOURCE}
	
}

function Get_YearMonth_From_Picture {

    DATESOURCE=0
	
	local tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %m_%B -DateTimeOriginal "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"

	if [ "$tmpdate" = "" ]; then
        tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %m_%B -MediaCreateDate "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"
		DATESOURCE=1
    fi
	
	if [ "$tmpdate" = "" ]; then
        tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %m_%B -CreateDate "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"
		DATESOURCE=2
    fi
	
	
	#If there is no date info
	if [ "$tmpdate" == "" ]; then

		if [ $PRESUMEDATES -eq 1 ]; then
			Presume_Date_If_Necessary "month"
			tmpdate="$PICMONTH"
			DATESOURCE=3
		else
			tmpdate="Unknown"
			DATESOURCE=4
		fi	
	
	fi
	
	echo "$tmpdate"	
	return ${DATESOURCE}	
}

function Get_FullDate_From_Picture {

    DATESOURCE=0
	
	local tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %Y.%m.%d -DateTimeOriginal "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"    
	
	if [ "$tmpdate" = "" ]; then
        tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %Y.%m.%d -MediaCreateDate "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"
		DATESOURCE=1
    fi
	
	if [ "$tmpdate" = "" ]; then
        tmpdate="$(Get_Safe_String "$(${EXIF} -S -d %Y.%m.%d -CreateDate "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )")"
		DATESOURCE=2
    fi	
	
	#If there is no date info
	if [ "$tmpdate" == "" ]; then

		if [ $PRESUMEDATES -eq 1 ]; then
			Presume_Date_If_Necessary "day"
			tmpdate="$PICDATE"
			DATESOURCE=3
		else
			tmpdate="Unknown"
			DATESOURCE=4
		fi	
	
	fi
	
	echo "$tmpdate"	
	return ${DATESOURCE}		
}


function Presume_Date_If_Necessary {
#$1 "year", "month", "day"

#PICDATE, PICYEAR, PICMONTH

    if [ "$1" == "year" ]; then
    
        YEARPRESUMED=0
        
        if [ "${PICYEAR}" != "" ]; then
           LASTPICYEAR="${PICYEAR}"
        else
           PICYEAR="${LASTPICYEAR}"
           YEARPRESUMED=1
        fi    
    fi
    
    if [ "$1" == "month" ]; then
    
        MONTHYEARPRESUMED=0
        
		if [ "${PICMONTH}" != "" ]; then
		   LASTPICMONTH="${PICMONTH}"
		else
		   PICMONTH="${LASTPICMONTH}"
		   MONTHYEARPRESUMED=1
		fi     
    fi

    if [ "$1" == "day" ]; then
    
        DATEPRESUMED=0
        
        if [ "${PICDATE}" != "" ]; then
           LASTPICYEAR="${PICDATE}"
        else
           PICDATE="${LASTPICYEAR}"
           DATEPRESUMED=1
        fi    
    fi    
    
}

function Print_Date_InColor {

	Print_In_Color c "\n\tWhen\t\t:"   
	
	if [ "${DATESOURCE}" == 0 ]; then       
		Print_In_Color g "\t${PICDATE} (DateTimeOriginal)"
	elif [ "${DATESOURCE}" == 1 ]; then
		Print_In_Color p "\t${PICDATE} (MediaCreationDate)"			
	elif [ "${DATESOURCE}" == 2 ]; then
		Print_In_Color p "\t${PICDATE} (FileCreateDate)"
	elif [ "${DATESOURCE}" == 3 ]; then
		Print_In_Color y "\t${PICDATE} (Presumed)"
	elif [ "${DATESOURCE}" == 4 ]; then
		Print_In_Color r "\t${PICDATE} (Not Presumed)"			
	else
		Print_In_Color r "\t${PICDATE} (Unknown) $DATESOURCE"           
	fi  

	Print_In_Color c ""
	
}


# GPS Functions

function Get_Latitude_Picture {

    local tmpcord="$(${EXIF} -S -c %.2f -GPSLatitude "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ')"

    if echo "$tmpcord" | grep -q "N"; then
        tmpcord="$(echo $tmpcord | cut -f1 -d ' ')"
    else
        tmpcord="-$(echo $tmpcord | cut -f1 -d ' ')"    
    fi 
    	
    if [ "${tmpcord}" == "-" ] || [ "${tmpcord}" == "" ]; then
        tmpcord="Unknown"
    fi
    
    echo "${tmpcord}"
}

function Get_Longitude_Picture {

    local tmpcord="$(${EXIF} -S -c %.2f -GPSLongitude "$1" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ')"

    if echo "$tmpcord" | grep -q "E"; then
        tmpcord="$(echo $tmpcord | cut -f1 -d ' ')"
    else
        tmpcord="-$(echo $tmpcord | cut -f1 -d ' ')"    
    fi 
    
    if [ "${tmpcord}" == "-" ] || [ "${tmpcord}" == "" ]; then
        tmpcord="Unknown"
    fi  
        
    echo "${tmpcord}"
}

function Get_Human_Friendly_Location_From_Picture {

    LOCATIONSOURCE=0
    local tmploc="Unknown"
    
    if [ "$1" != "Unknown,Unknown" ]; then
    
        #Try to find it from cache
        tmploc="$(Get_GEO_Code_From_Cache $1)"

        
        #I found it in Cache
        if [ "$tmploc" != "" ]; then
           
           LASTPICLOCATION="${tmploc}"
           LOCATIONSOURCE=1
        
        #I didn't find it in Cache
        else    
           tmploc="$(Write_GEO_Code_To_Cache $1)"
           LASTPICLOCATION="${tmploc}"
           LOCATIONSOURCE=2
           #Print_In_Color p "      $tmploc (Google)(Identified)"
        fi

    else
           
		if [ $PRESUMELOCATIONS -eq 1 ]; then
		   tmploc="${LASTPICLOCATION}"
           LOCATIONSOURCE=3
		else
		   tmploc="[Unknown]"
           LOCATIONSOURCE=4
		fi	
		

		   
		   
        
    fi
    
    echo "${tmploc}"    
    return ${LOCATIONSOURCE}
}

function Print_Location_InColor {
    
    if [ "${PICLOCATION}" != "Unknown" ]; then

        if [ "${LOCATIONSOURCE}" == 1 ]; then       
            Print_In_Color g "\t${PICLOCATION} (Cache)(Identified)"
        elif [ "${LOCATIONSOURCE}" == 2 ]; then
            Print_In_Color p "\t${PICLOCATION} (Google)(Identified)"
        elif [ "${LOCATIONSOURCE}" == 3 ]; then
            Print_In_Color y "\t${PICLOCATION} (Presumed)"
        elif [ "${LOCATIONSOURCE}" == 4 ]; then
            Print_In_Color r "\t${PICLOCATION} (Not Presumed)"			
        else
            Print_In_Color r "\t${PICLOCATION} (Unknown Method) $LOCATIONSOURCE"           
        fi  
    else
    
        Print_In_Color r "\t${PICLOCATION} (Unknown)"
            
    fi
    
}

function Process_Picture_File {

    local REALFILE="$1"
	local PIC=""
    
    FILECOUNTER=$((FILECOUNTER+1))
    #Extract file name and extension
    REALFILE_FILENAME_WITH_EXTENTION=${REALFILE##*/}
    REALFILE_NAME_WITHOUT_EXTENTION=${REALFILE_FILENAME_WITH_EXTENTION%.*}
    REALFILE_JUST_EXTENTION=${REALFILE_FILENAME_WITH_EXTENTION##*.}

    if [ $REALFILE_JUST_EXTENTION == "jpg" ] || [ $REALFILE_JUST_EXTENTION == "JPG" ]  || [ $REALFILE_JUST_EXTENTION == "jpeg" ]  || [ $REALFILE_JUST_EXTENTION == "JPEG" ]  || [ $REALFILE_JUST_EXTENTION == "png" ]  || [ $REALFILE_JUST_EXTENTION == "PNG" ]  || [ $REALFILE_JUST_EXTENTION == "mov" ]  || [ $REALFILE_JUST_EXTENTION == "MOV" ] || [ $REALFILE_JUST_EXTENTION == "mp4" ]  || [ $REALFILE_JUST_EXTENTION == "MP4" ]; then

		PIC="$1"

    else

		[ -f "${1%.*}.png" ] && PIC="${1%.*}.png"
		[ -f "${1%.*}.PNG" ] && PIC="${1%.*}.PNG"
		[ -f "${1%.*}.mov" ] && PIC="${1%.*}.mov"
		[ -f "${1%.*}.MOV" ] && PIC="${1%.*}.MOV"		
		[ -f "${1%.*}.mp4" ] && PIC="${1%.*}.mp4"
		[ -f "${1%.*}.MP4" ] && PIC="${1%.*}.MP4"	
		[ -f "${1%.*}.jpg" ] && PIC="${1%.*}.jpg"
		[ -f "${1%.*}.JPG" ] && PIC="${1%.*}.JPG"
		[ -f "${1%.*}.jpeg" ] && PIC="${1%.*}.jpeg"
		[ -f "${1%.*}.JPEG" ] && PIC="${1%.*}.JPEG"
		
	fi

	
    PICTUREFILE_FILENAME_WITH_EXTENTION=${PIC##*/}
    PICTUREFILE_NAME_WITHOUT_EXTENTION=${PICTUREFILE_FILENAME_WITH_EXTENTION%.*}
    PICTUREFILE_JUST_EXTENTION=${PICTUREFILE_FILENAME_WITH_EXTENTION##*.}

	
	
    Print_In_Color c "\n=========================================================================\n"
	
    Print_In_Color c "\t(${FILECOUNTER}/${TOTALFILECOUNT})\t:\t$REALFILE_NAME_WITHOUT_EXTENTION.$REALFILE_JUST_EXTENTION"
    
	if [ "${REALFILE}" != "${PIC}" ]; then
		Print_In_Color p "\tExtracting Info From $PICTUREFILE_NAME_WITHOUT_EXTENTION.$PICTUREFILE_JUST_EXTENTION"
	fi
	
	

    ######################      WHEN        #######################
    # Set year
    PICYEAR="$(Get_Year_From_Picture "$PIC")"
    
    # Set month
    PICMONTH="$(Get_YearMonth_From_Picture "$PIC")"  

    # Set date  
    PICDATE="$(Get_FullDate_From_Picture "$PIC")"	

	#Get the return code from Geodata
	DATESOURCE=$?
	
    # Print the date
    Print_Date_InColor   

    
    ######################      WHERE       #######################
    
    #Set Place
	#PICLOCATION="Unknown"
    PICLATITUDE="$(Get_Latitude_Picture "$PIC")"
    PICLONGITUDE="$(Get_Longitude_Picture "$PIC")"
    
    #if [ "$PICLATITUDE" != "Unknown" ] && [ "$PICLONGITUDE" != "Unknown" ]; then
    
        #Print that I found GPS data
        Print_In_Color c "\tWhere\t\t:"
		
		if [ "$PICLATITUDE" != "Unknown" ] && [ "$PICLONGITUDE" != "Unknown" ]; then
			Print_In_Color g "\tLatitude = $PICLATITUDE\tLongitude = $PICLONGITUDE" 
		else
			Print_In_Color r "\tLatitude = $PICLATITUDE\tLongitude = $PICLONGITUDE"		
		fi
		
		
        #Print human readeable information
        PICLOCATION="$(Get_Human_Friendly_Location_From_Picture "$PICLATITUDE,$PICLONGITUDE")"
		
        #Get the return code from Geodata
        LOCATIONSOURCE=$?
		
		#Keep sanitization on the second linei we need return code
		PICLOCATION="$(Get_Safe_String "$PICLOCATION")"
        

        
        # Print location in color
        Print_Location_InColor
    
                
    #else
        #No GPS data is available
    #    Print_In_Color r "\tWhere\t:\tLatitude = $PICLATITUDE\tLongitude = $PICLONGITUDE"
    #fi      


    


        
    ######################      COPY        #######################
    
    TARDIR="${TARGETDIR}/${PICYEAR}/${PICMONTH}/${PICDATE} ${PICLOCATION}"
    

    #echo "Moving To  : ${TARDIR}"
    Print_In_Color c "\n\n\tDestination\t:"
	Print_In_Color g "\t${PICYEAR}/${PICMONTH}/${PICDATE} ${PICLOCATION}"
	
	
    mkdir -p "${TARDIR}"
    
    RENAMEDTARGETFILE=""
    CopyFileToFolder "$REALFILE" "${TARDIR}"

    
    #Auto rotate target file
    Print_In_Color c "\n\tName\t\t:"
	Print_In_Color g "\t${RENAMEDTARGETFILE##*/}"

    #${EXIF} -Orientation=1 -n "$RENAMEDTARGETFILE"
    
    #Print_In_Color c "\n=========================================================================\n"
    


}


#echo "[Geocodes]" >> "${CURRDIR}/geocodes.ini"

#Bootstrap the script
Bootstrap

#find ${SOURCEDIR} -type f  -not -name '*.sh' -not -name '.picasa.ini' -print0 | while IFS= read -r -d '' PIC; do
#   echo "=$PIC="
   #${EXIF} -S -d %Y -DateTimeOriginal "$PIC" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' '
#   echo "=$(${EXIF} -S -d %Y -DateTimeOriginal "$PIC" < /dev/null 2> /dev/null| cut -f 2- -d: | cut -f 2- -d ' ' )="
#done



find ${SOURCEDIR} -type f  -not -name '*.sh' -not -name '.picasa.ini' -print0 | while IFS= read -r -d '' PICTUREFILE; do
#    echo "$PICTUREFILE"
	Process_Picture_File "$PICTUREFILE"
done


#shopt -s globstar

#for PICT in "$(find ${SOURCEDIR}/** -type f  -not -name '*.sh' -not -name '.picasa.ini')"; do 
#	echo "$PICT"
	#Process_Picture_File "$PICT"
#done




Print_In_Color c "\n=========================================================================\n"
Print_In_Color c "\n=========================================================================\n"

Print_In_Color g  "\tFile Count in $SOURCEDIR"
Print_In_Color g  "\t$(find $SOURCEDIR -type f -not -name '*.sh' -not -name '.picasa.ini' | wc -l)\n\n"

Print_In_Color g "\tFile Count in ${TARGETDIR}"
Print_In_Color g "\t$(find ${TARGETDIR} -type f | wc -l)"