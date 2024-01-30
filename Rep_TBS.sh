#!/bin/bash
 
T_SED=$(whereis -b sed | cut -sd\  -f2)
#T_AWK=$(whereis -b awk | cut -sd\  -f2)
 
 
# Home dir for the tool
WORK_DIR=~/capacity_reports
 
# Hostname
HOST=`hostname -s`
MOUNTPOINT_LIST="$(mount | egrep "type (ext[34])" | grep oravg | cut -d\  -f3 | xargs -r echo)"
 
[ -d ${WORK_DIR}/report ] || mkdir -p ${WORK_DIR}/report
 
cd ${WORK_DIR}/report
 
#dir="$(dirname $0)"
 
# html templates
p_h1="<script src=\"http://cdnjs.cloudflare.com/ajax/libs/dygraph/2.1.0/dygraph.min.js\"></script>
<link rel=\"stylesheet\" href=\"http://cdnjs.cloudflare.com/ajax/libs/dygraph/2.1.0/dygraph.min.css\" />
<style media = \"all\">
        div.container {
        	position: relative;
        	display: inline-block;
        	width:100%; 
        	height: 400px;
        }
        div.graph {
        	display: inline-block;
        	position: absolute;
        	width: calc(100% - 310px); 
        	height:350px;
        	text-align: center;
        }
        div.legend {
        	display: inline-block;
        	position: absolute;
        	text-align: left; 
        	left: calc(100% - 310px); 
        	width: 310px; 
        	padding-top: 50px; 
        	padding-left: 20px; 
        	height:350px; 
        	font-size:0.8em; 
        }
</style>
</head>
<body style='width: 100%; padding-left: 10px;>"
p_h2="</body></html>"


read_TBS="<p>
<b>Tablespaces Vs Mount Point Data</b> <br>
<p>"
 
### functions

function run_TBS {
    cd ${WORK_DIR}/data
    cp -f *TBS.csv ${WORK_DIR}/report
}
 
# draw graphs
function draw_GR {
# usage
# append_file data_file graph_name ylabel
echo "<div class='container'>" >> $1
echo "   <div class='graph' id='${2}'></div>" >> $1
echo "   <div class='legend' id='${2}_status'></div>" >> $1
echo "</div>" >> $1
echo "<script type='text/javascript'>g2 = new Dygraph(document.getElementById('${2}')," >> $1
cat <(head -n -1 ${WORK_DIR}/report/${2}.csv| ${T_SED} -e "s,^,\",g" -e "s,$,\\\n\" +,g") <(tail -n 1 ${WORK_DIR}/report/${2}.csv | ${T_SED} -e "s,^,\",g" -e "s,$,\"\,,g")  >> $1
echo "{ rollPeriod: 1, showRoller: true, title: '$3', ylabel: '$4',showRangeSelector: true," >> $1
echo " legend: 'always', labelsDiv: document.getElementById('${2}_status'),labelsSeparateLines: true}" >> $1
echo ");</script>" >> $1
}
 
function draw_GR_stack {
# usage
# append_file data_file graph_name ylabel
echo "<div class='container'>" >> $1
echo "   <div class='graph' id='${2}'></div>" >> $1
echo "   <div class='legend' id='${2}_status'></div>" >> $1
echo "</div>" >> $1
echo "<script type='text/javascript'>g2 = new Dygraph(document.getElementById('${2}')," >> $1
cat <(head -n -1 ${WORK_DIR}/report/${2}.csv| ${T_SED} -e "s,^,\",g" -e "s,$,\\\n\" +,g") <(tail -n 1 ${WORK_DIR}/report/${2}.csv | ${T_SED} -e "s,^,\",g" -e "s,$,\"\,,g")  >> $1
echo "{ rollPeriod: 1, showRoller: true, title: '$3', ylabel: '$4',showRangeSelector: true,stackedGraph: true," >> $1
echo " legend: 'always', labelsDiv: document.getElementById('${2}_status'),labelsSeparateLines: true}" >> $1
echo ");</script>" >> $1
}

#Main
# Copy over csv from data to report
run_TBS  


# Generate html file
# S is server name here
for S in $(cd ${WORK_DIR}/data; ls -1 *.out 2>/dev/null | cut -d_ -f1 | sort | uniq)
do
    html_file="${WORK_DIR}/report/${S}_TBS.html"
    echo "<html><head><title>CAPACITY reports on ${S}</title>" > ${html_file}
    echo ${p_h1}                                              >>  ${html_file}
    echo "<a href='${url_prefix}index.html'>Back</a> | Report generated @ `date`"  >>  ${html_file}
    echo "<h1>Server: ${S} </h1>"                             >>  ${html_file}
done

for F in $(cd ${WORK_DIR}/report; ls -1 *TBS.csv 2>/dev/null)
do
    #Beware of % for EM, for shell it is only one %
    FF=${F/%.csv/}
    server=${HOST}
    test=$(echo "${FF}" | cut -d_ -f1)
    detail=MP
    html_file="${WORK_DIR}/report/${server}_TBS.html"

      case "$detail" in
        MP) draw_GR  ${html_file} ${FF} "Tablespace Vs Mountpoint Space Usage: ${test}" "Gigabytes"
            echo "<tr><td width='1000px'>"${read_DB}"</td><td>&nbsp;</td></tr>"                                 >> ${html_file}
           ;;
        *) echo "STEP: create server reports -> ${F}: Not processed"   >> ${html_file}
      ;;
      esac
done

for S in $(cd ${WORK_DIR}/data; ls -1 *.out 2>/dev/null | cut -d_ -f1 | sort | uniq)
do
    html_file="${WORK_DIR}/report/${S}_TBS.html"
    echo "Report generated @ `date`"  >>  ${html_file}
    echo ${p_h2}                                             >>  ${html_file}
done