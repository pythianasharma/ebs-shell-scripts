#!/usr/bin/ksh
# Author : Ashish Sharma TCS
# Description : Deamon Process shell script Modified.
#
##############################################################
#set -x

##############################################################
##############
# Variables
##############
##############################################################

SUCCESS=0
FAILURE=1
y=0;
QF=$PWD/.qfile2`date +%d%m%y%H%M%S`
LOGF=$PWD/Deamon`date +%d%m%y%H%M%S`.log
PWF=$PWD/.pworfl`date +%d%m%y%H%M%S`
TDF=$PWD/.tdefl`date +%d%m%y%H%M%S`

##############################################################
##############
# Functions
##############
##############################################################

function logit {
echo  "$1" >> $LOGF
}

function showUsage {
      echo " "
      echo "Usage:Deamon_AIX.ksh -n No. of parallel workers -t Time Delay in seconds -s program to run -a Arguments file to the program to run [-h]"
      echo " "
      echo " "
      echo "Example: "
      echo "     Deamon_AIX.ksh -n 2 -t 10 -s scritp.ksh -a argumentfile"
      echo " "
}

function Pstrt {
 logit "\n\tNumber of Parallel workers : $1\n"
 echo $1 > $PWF
}

function Tstrt {
 logit "\tTime Delay used by the Deamon : $1\n"
 echo $1 > $TDF
}

function Cstrt {
 logit "\tScript used by the Deamon : $1\n"
 SCR=$1
}

function Astrt {
 logit "\tCommand File used by the Deamon : $1\n"
 CMDF=$1
}

function strt {
   logit "In strt $1 Commands on this run"
   CNT=0
   unset arr;
while read line
 do
   logit "Starting with command : $line"
    nohup $PWD/$SCR $line 2>&1 > /dev/null &
    arr[$CNT]=`echo $!`
    echo ${arr[$CNT]} >> $QF
    CNT=`expr $CNT + 1`;
    if [ $CNT = $1 ]
      then
      logit "Reached Threshold Removing $CNT lines from $CMDF"
      #sed -i 1,${CNT}d $CMDF 2>&1 >> $LOGF
      cat $CMDF | sed 1,${CNT}d > .$CMDF.tmp
      logit `echo $?`
      mv .$CMDF.tmp $CMDF
      break;
    fi
done < $CMDF ;
}

##############################################################
##############
# Main :
##############
##############################################################

while getopts :n:h:t:s:a: arguments
      do
         case $arguments in
            h) showUsage
               exit $SUCCESS;;

            n) ParNo="$OPTARG";;

            t) TimNo="$OPTARG";;

            s) SimNo="$OPTARG";;

            a) AimNo="$OPTARG";;

            :) echo "$0 [$LINENO] Unable to proceed. Switch -$OPTARG requires a value"
               showUsage
               exit $FAILURE;;

            \?) echo "Invalid switch $OPTARG"
                showUsage
                exit $FAILURE;;
         esac
     done

if test "$ParNo" = ""
     then
        showUsage
        exit $FAILURE
     fi

if test "$TimNo" = ""
     then
        showUsage
        exit $FAILURE
     fi

if test "$SimNo" = ""
     then
        showUsage
        exit $FAILURE
     fi

if test "$AimNo" = ""
     then
        echo "Command file does not exists."
        showUsage
        exit $FAILURE
     fi

    Pstrt $ParNo

    Tstrt $TimNo

    Cstrt $SimNo

    Astrt $AimNo

#Yes The Program Starts!

cat /dev/null > $QF

tot=`cat $CMDF | wc -l`

   logit "Starting the program $0 at `date`"


   MCN=`cat $PWF`

strt $MCN ;

#Beginning the Program :

logit "Entering True Loop"
while true
 do
  logit "Entering Check loop"
   while read line
    do
      unset arr2;
      CNT2=0
      ps -ef | grep $line | grep $SCR | grep -v grep 2>&1 >/dev/null
      if [ $? = 0 ]
       then
        continue;
       else
        logit "Process $line completed Deleting the completed process $line from $QF"
        arr2[$CNT2]=$line
        CNT2=`expr $CNT2 + 1`;
        #Now the process from the $QF should be removed.
        #sed -i /${line}/d $QF
        cat $QF | sed s/${line}//g | sed /^$/d > $QF.tmp
        logit "`echo $?`"
        mv $QF.tmp $QF
       fi
     done < $QF
      logit "Finished iterating Check Loop"

   unset MCN
   MCN=`cat $PWF`
   QLEN=`cat $QF | wc -l`
   if [ $QLEN -lt $MCN ]
    then
     #logit "QLEN is less than MCN"
     unset CLEN
     CLEN=`cat $CMDF | wc -l`
     DF=`expr $MCN - $QLEN`;
     if [ $DF -lt $CLEN ]
     then
      #logit "DF is less than CLEN"
      logit "Submitting $DF new jobs"
      strt $DF
     elif [ $DF -ge $CLEN ]
      then
      #logit "DF is ge CLEN"
      logit "Submitting remaining $CLEN Jobs"
      strt $CLEN
     fi
   fi

 unset CLEN
 CLEN=`cat $CMDF | wc -l`
 if [ $CLEN = 0 ]
  then
   logit "Length of $CMDF has reached zero , Breaking the True Loop"
   break ;
  else
   logit "$CMDF has $CLEN jobs remaining"
 fi

  unset TF
  TF=`cat $TDF`
  logit "Off to sleep for $TF seconds at `date`"
  sleep $TF;
  logit "Waking up at `date`"
 done

    logit "\tCompleted $0 on `date`\n"
    rm $QF $PWF $TDF
