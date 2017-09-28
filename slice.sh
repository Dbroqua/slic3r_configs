#! /bin/bash

#title              :slice.sh
#description        :Just a "GUI" for slic3r
#author             :Damien Broqua
#date               :20170928
#version            :0.1
#usage              :bash slice.sh
#bash_version       :4.4
#Requirements       : slic3r-prusa and dialog
#==============================================================================

STL_PATH=`pwd`
PRINTERS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/printers"
PRINTER=""
STLS=""
SUPPORT=0
ADD_OTHER_FILE=1
SLICER_CONFIG='/tmp/slic3r.ini'
SLICER_CMD=''

function clean_tmp {
    rm ${SLICER_CONFIG}
}

#Looking for slic3r
SLICER_CMD=`which slic3r-prusa`
if [ $? -eq 1 ] ; then
    SLICER_CMD=`which slic3r-prusa3d`
    if [ $? -eq 1 ] ; then
        SLICER_CMD=`which slic3r`
        if [ $? -eq 1 ] ; then
            echo -e "\e[31mSlic3r not found\e[0m"
            exit 1
        fi
    fi
fi

let i=0 # define counting variable
W=() # define working array

# Select printer
while read -r line; do # process file by file
    let i=$i+1
    W+=($i "$line")
done < <( ls -1 ${PRINTERS_PATH} )
PRINTER_ID=$(dialog --title "Choose printer" --menu "Printer" 24 80 17 "${W[@]}" 3>&2 2>&1 1>&3) # show dialog and store output

if [ $? -ne 0 ]; then # Exit
    exit $?
fi

PRINTER=${PRINTERS_PATH}/$(ls -1 ${PRINTERS_PATH} | sed -n "`echo "$PRINTER_ID p" | sed 's/ //'`")/default.ini

# Support yes or no ?
dialog --yesno "Support?" 0 0

if [ $? -eq 0 ]; then
    SUPPORT=1
fi

sed "s/support_material = 0/support_material = ${SUPPORT}/" ${PRINTER} > ${SLICER_CONFIG}


# Select STL file
W=()
i=0
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( ls -1 ${STL_PATH}/*.{STL,stl} )

if [ "${W}" == "" ] ; then
    clear
    clean_tmp
    echo -e "\e[31mNo stl found in the current directory!\e[0m"
    exit 2
fi
while [ ${ADD_OTHER_FILE} -eq 1 ] ; do
    STL_ID=$(dialog --title "Choose STL" --menu "STL (cancel to slice result)" 24 80 17 "${W[@]}" 3>&2 2>&1 1>&3)
    if [ $? -eq 1 ] ; then
        ADD_OTHER_FILE=0
    else
        STLS=${STLS}" "$(ls -1 ${STL_PATH}/*.{STL,stl} | sed -n "`echo "$STL_ID p" | sed 's/ //'`")
    fi
done

clear

if [ "${STLS}" != "" ] ; then
    ${SLICER_CMD} --load ${SLICER_CONFIG} -m ${STLS}
    clean_tmp
    exit 0
else
    echo "No file selected"
    clean_tmp
    exit 3
fi
