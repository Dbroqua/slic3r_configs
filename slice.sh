#! /bin/bash

#title              :slice.sh
#description        :Just a "GUI" for slic3r
#author             :Damien Broqua
#date               :20180818
#version            :0.2
#usage              :bash slice.sh
#bash_version       :4.4
#Requirements       : slic3r-prusa kdialog
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
DENSITIES='0% 5% 10% 15% 20% 30% 40% 50% 60% 70% 80% 90% 100%'
DEFAULT_DENSITY="30%"
GCODE=''

function clean_tmp {
    rm ${SLICER_CONFIG}
}

#Looking for kdialog
DIALOG_CMD=`which kdialog`
if [ $? -eq 1 ] ; then
  echo -e "\e[31mKdialog not found\e[0m"
  exit 1
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


# Select printer
PRINTERS=""
while read -r line; do # process file by file
    PRINTERS+=" ${line}"
done < <( ls -1 ${PRINTERS_PATH} )
PRINTER_NAME=$(kdialog --title "Printers" --combobox "Select the printer" ${PRINTERS}) # show dialog and store output
if [ $? -ne 0 ]; then # Exit
    exit $?
fi
if [ "${PRINTER_NAME}" = "" ] ; then
  kdialog --error "No printer selected!"
  echo -e "\e[31mNo printer selected!\e[0m"
  exit 3
fi
PRINTER=${PRINTERS_PATH}/${PRINTER_NAME}/default.ini
cp ${PRINTER} ${SLICER_CONFIG}


# Support yes or no ?
kdialog --title "Support" --yesno "Add support?"
if [ $? -eq 0 ]; then
    SUPPORT=1
fi
sed -i "s/support_material = 0/support_material = ${SUPPORT}/" ${SLICER_CONFIG}


# Fill density
FILL_DENSITY=$(kdialog --title "Fill density" --combobox "Select fill density (DEFAULT: ${DEFAULT_DENSITY})" ${DENSITIES})
if [ $? -ne 0 ]; then # Exit
    exit $?
fi
if [ "${FILL_DENSITY}" == "" ] ; then
  FILL_DENSITY=${DEFAULT_DENSITY}
fi
sed -i "s/fill_density = 30%/fill_density = ${FILL_DENSITY}/" ${SLICER_CONFIG}


# Select STL file
while [ ${ADD_OTHER_FILE} -eq 1 ] ; do
    STL=$(kdialog --getopenfilename ${STL_PATH} '*.stl *.STL')

    if [ $? -ne 0 ]; then # Exit
        clean_tmp
        exit $?
    fi
    if [ "${STL}" = "" ] ; then
      clean_tmp
      kdialog --error "No file selected!"
      echo -e "\e[31mNo file selected!\e[0m"
      exit 3
    fi

    if [ $? -eq 1 ] ; then
        ADD_OTHER_FILE=0
    else
        STLS+=" ${STL}"

        if [ "${GCODE}" == "" ] ; then
          GCODE="${STL}.gcode"
        fi
    fi

    kdialog --title "Add" --yesno "Add another file?"
    if [ $? -ne 0 ]; then
        ADD_OTHER_FILE=0
    fi
done

if [ "${STLS}" != "" ] ; then
    ${SLICER_CMD} --load ${SLICER_CONFIG} -m ${STLS} -o ${GCODE}
    kdialog --msgbox "File saved in ${GCODE}"
    clean_tmp
    exit 0
else
    kdialog --error "No file selected!"
    echo "No file selected"
    clean_tmp
    exit 3
fi
