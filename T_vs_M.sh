#!/bin/bash

# Home dir for the tool
WORK_DIR=~/capacity_reports
[ -d ${WORK_DIR} ] || mkdir -p ${WORK_DIR}
[ -d ${WORK_DIR}/data ] || mkdir -p ${WORK_DIR}/data

# Hostname
HOST=`hostname -s`

# Mountpoitns to monitor
MOUNTPOINT_LIST="$(mount | egrep "type (ext[34])" | grep oravg | cut -d\  -f3 | xargs -r echo)"

# Functions:

function processdb {
#TMP=.tmpfl
echo "IN: processdb, starting with file $1"
TBSN=`cat $1 | awk '{ print $3 }' | sort | uniq | grep -v TABLESPACE_NAME`
DBN=`echo $1 | awk -F _ '{ print $3 }'`
DT=`cat $1 | awk '{ print $1 }' | grep -v DATE | sort | uniq`
#unset arr;
for d in $TBSN
 do
   echo ${d}_${DBN} > ${d}_${DBN}.tmp
   grep $d $1 | awk '{ print $NF }' >> ${d}_${DBN}.tmp
   arr[$CNT]=`echo ${d}_${DBN}.tmp`
   CNT=`expr $CNT + 1`;
 done

touch DT.tmp
echo "DATE" > DT.tmp
 
for e in $DT
 do
   echo $e >> DT.tmp
 done
echo "File array is  ${arr[*]}"

}

function processdf {
echo "IN: processDF: starting with file $1"
echo "IN: processDF: Mountpoint is $MP"
echo "TOTAL_MOUNTPOINT_SPACE" > TOT.tmp
cat $1 | awk '{ print $2 }' | grep -v blocks | awk '{ print $1/1024/1024 }' >> TOT.tmp
}

# Main:

for i in $MOUNTPOINT_LIST
  do
    cd ${WORK_DIR}/data
    MP=`echo $i | tr -d /`
    echo
    echo "Mountpoint is $MP"
    FL=`echo ${MP}_TBS.csv`
    #echo "Touching file $FL"
    farr=`ls *${MP}*`
    echo "File array is : $farr"
    unset arr;
    CNT=0
    for j in $farr   
      do
        echo "Starting with file $j"
        C=`cat $j | wc -l`
        T=`echo $j | awk -F _ '{ print $2 }'`
        if [ $C == 1 ]
          then
            echo "Skipping $j, no data"
        elif [ $T == 'DB' ]
          then
            processdb $j
        elif [ $T == 'DF' ]
          then
          processdf $j
        fi
      done
      # Final generation of csv
      echo  "paste -d, DT.tmp ${arr[*]} TOT.tmp" > ${MP}.sh 
      chmod 755 ${MP}.sh
      ./${MP}.sh > $FL
       rm ${MP}.sh
  done
  
  rm *.tmp