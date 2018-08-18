#! /bin/bash

#title              :slice.sh
#description        :Just a "GUI" for slic3r
#author             :Damien Broqua
#date               :20180818
#version            :0.2
#usage              :bash slice.sh
#bash_version       :4.4
#Requirements       : slic3r-prusa and {dialog or kdialog}
#==============================================================================

STL_PATH=`pwd`
PRINTERS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/printers"
PRINTER=""
STLS=""
SUPPORT=0
ADD_OTHER_FILE=1
SLICER_CONFIG='/tmp/slic3r.ini'
SLICER_CMD=''
DIALOG_CMD=''
DIALOG_TYPE=''

function showMessage {
  echo $3
  case $1 in
    'menu')
      if [ "${DIALOG_TYPE}" = 'dialog' ] ; then
        ${DIALOG_CMD} --title "${2}" --menu "${3}" 24 80 17 ${4} 3>&2 2>&1 1>&3
      else
        ${DIALOG_CMD} --menu ${3} $4
      fi
    ;;
  esac
}

function clean_tmp {
    rm ${SLICER_CONFIG}
}

#Looking for dialog or kdialog
DIALOG_CMD=`which kdialog`
if [ $? -eq 1 ] ; then
    DIALOG_CMD=`which dialog`
    if [ $? -eq 1 ] ; then
        echo -e "\e[31mDialog or Kdialog not found\e[0m"
        exit 1
    else
      DIALOG_TYPE='dialog'
    fi
else
  DIALOG_TYPE='kdialog'
fi

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
if [ "${DIALOG_TYPE}" = 'kdialog' ] ; then
  PRINTER_ID=$(kdialog --title "Printers" --menu "Select the printer" "${W[@]}" 3>&2 2>&1 1>&3) # show dialog and store output
else
  PRINTER_ID=$(dialog --title "Printers" --menu "Select the printer" 24 80 17 "${W[@]}" 3>&2 2>&1 1>&3) # show dialog and store output
fi

if [ $? -ne 0 ]; then # Exit
    exit $?
fi

PRINTER=${PRINTERS_PATH}/$(ls -1 ${PRINTERS_PATH} | sed -n "`echo "$PRINTER_ID p" | sed 's/ //'`")/default.ini

# Support yes or no ?
if [ "${DIALOG_TYPE}" = 'kdialog' ] ; then
  kdialog --title "Support" --yesno "Add support?"
else
  dialog --yesno "Add support?" 0 0
fi

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
    if [ "${DIALOG_TYPE}" = 'kdialog' ] ; then
      STL_ID=$(kdialog --title "Add files" --menu "Available STL" "${W[@]}" 3>&2 2>&1 1>&3) # show dialog and store output
    else
      STL_ID=$(dialog --title "Add files" --menu "Available STL" 24 80 17 "${W[@]}" 3>&2 2>&1 1>&3)
    fi

    if [ $? -eq 1 ] ; then
        ADD_OTHER_FILE=0
    else
        STLS=${STLS}" "$(ls -1 ${STL_PATH}/*.{STL,stl} | sed -n "`echo "$STL_ID p" | sed 's/ //'`")
    fi

    if [ "${DIALOG_TYPE}" = 'kdialog' ] ; then
      kdialog --title "Add" --yesno "Add another file?"
    else
      dialog --title "Add" --yesno "Add another file?" 0 0
    fi
    if [ $? -ne 0 ]; then
        ADD_OTHER_FILE=0
    fi
done

clear

if [ "${STLS}" != "" ] ; then
    ${SLICER_CMD} --load ${SLICER_CONFIG} -m ${STLS}
    clean_tmp
    exit 0
else
    # kdialog --error "No file selected"
    echo "No file selected"
    clean_tmp
    exit 3
fi
