#!/bin/bash
while getopts :t:c:p: TIMED 
do
       case $TIMED in 
            t) readtomcat=$OPTARG
               ;;
            c) readcommand=$OPTARG
               ;;
            p) inline_tommy_home=$OPTARG
               ;;
       esac
done
	if [[ -n "$inline_tommy_home" ]]; then
              tommyHome="$inline_tommy_home"
        else
		tommyHome="$tommy_home"
        fi

count=1
tommy_home_arr=$(echo $tommyHome | tr "," "\n")

##itering over each comma separted location
for temp_tommy_home in $tommy_home_arr
do
ls $temp_tommy_home > /tmp/directorylist

#itering over each directory of given location
while read line
do
versionFileName=$temp_tommy_home$line'/bin/version.sh'
catalinaFileName=$temp_tommy_home$line'/bin/catalina.sh'
startupFileName=$temp_tommy_home$line'/bin/startup.sh'
if [[  -f $versionFileName && -f $catalinaFileName && -f $startupFileName ]]; then
tomcatLocation[$count]=$temp_tommy_home$line		#directoryname array
tomcatName[$count]=$line                        #tomcatname array

#for storing shutdownport 2nd method
grep "JPDA_ADDRESS=" $temp_tommy_home$line'/bin/catalina.sh' > /tmp/jpda.txt
tempjpda=(`cat /tmp/jpda.txt`)
jpdaPort[$count]=`echo ${tempjpda[0]} | awk -F\" '{print $2}'`

#for storing shutdownport 2nd method
grep "shutdown=\"SHUTDOWN\"" $temp_tommy_home$line'/conf/server.xml' >/tmp/shutdown.txt
checkshut=(`cat /tmp/shutdown.txt`)
shutdownPort[$count]=`echo ${checkshut[1]} | awk -F\" '{print $2}'`

#for storing connector port
grep "\<Connector port=" $temp_tommy_home$line'/conf/server.xml' > /tmp/connector.txt
tempconnector=(`cat /tmp/connector.txt`)
connectorPort[$count]=`echo ${tempconnector[1]} | awk -F\" '{print $2}'`

tomcatpid[$count]=$(ps -afe | grep $temp_tommy_home$line | grep -v grep | awk '{print $2}')

let count++
fi
done < /tmp/directorylist
done

##priting tomcats and port info

cunt=1
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t select tomcat to operate';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0
echo -e '\E[32;32m \t Tomcat Name \t\t\t Connector-Port \t Shutdown-Port \t\t JPDA-Port \t Status/pid';tput sgr0
for i in "${tomcatName[@]}"; do
tempTomcatName=$i
if [ ${#i} -gt 25  ];then
        tempTomcatName="${i:0:23}""..."
fi

	if [[ "${connectorPort[cunt]}" -ne "" ]]; then
		tempConnectorPort="${connectorPort[cunt]}"
	else
		tempConnectorPort= "unknown"
	fi

	if [[ "${shutdownPort[cunt]}" != "" ]]; then
		tempShutdownPort="${shutdownPort[cunt]}"
	else
		tempShutdownPort="unknown"
	fi

	if [[ "${jpdaPort[cunt]}" -ne "" ]]; then
		tempjpdaPort="${jpdaPort[cunt]}"
	else
		tempjpdaPort="unknown"
	fi
	
	if [[ -n "${tomcatpid[cunt]}" ]]; then
		tempStatus="running/${tomcatpid[cunt]}"
	else
		tempStatus="Shutdown/NA"
	fi

printf "%-3s%-30s%20s%24s%20s%20s\n" $cunt $tempTomcatName $tempConnectorPort $tempShutdownPort $tempjpdaPort $tempStatus

let cunt++
done

# reading 1st option i.e tomcat selection
while true
do
	option=$readtomcat
	selectedTomcat=${tomcatName[$option]}
	
	if [[ -n $readtomcat ]] && [[ -n $selectedTomcat ]]; then
		echo ""		
	else
       		read option
	fi


        selectedTomcat=${tomcatName[$option]}
	selectedTomcatLocation=${tomcatLocation[$option]}
	selectedConnectorPort=${connectorPort[$option]}
	selectedjpdaPort=${jpdaPort[$option]}
	selectedShutdownPort=${shutdownPort[$option]}	
                if [[ -z $selectedTomcat ]]; then
                        echo -e '\E[31;31m Are you kidding me, Please try again'; tput sgr0
                        continue;
                else
			echo -e "\E[32;32m \t\t\t\t You have selected ${tomcatName[option]}" ;tput sgr0
                        break;
                fi
done

echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m'
printf "%15s%-30s%-30s%-30s\n" "" "1 - start tomcat" "2 - restart tomcat" "3 - shutdown tomcat" 
printf "%15s%-30s%-30s%-30s\n" "" "4 - kill tomcat" "5 - delete logs" "6 - clean webapps" 
printf "%15s%-30s%-30s%-30s\n" "" "7 - configure port" "8 - tail logs" ""

echo  -e '\E[32;32m \t===============================================================================================';tput sgr0
nextoption=$readcommand
while true
do
if [ $((nextoption)) -gt 8 ] || [ $((nextoption)) -lt 1 ] || [ -z $(echo $nextoption | sed -e 's/[A-Za-z]//g') ]; then
	read nextoption
   # 	echo -e '\E[31;31m Are you kidding me, Please try again'; tput sgr0
else
break;
fi
done

case "$nextoption" in
1) 
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t Starting - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0

$selectedTomcatLocation/bin/startup.sh

echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t tailing logs - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0

logFileName=$selectedTomcatLocation/logs/server.log
        for i in {1..2}
        do
        if [[  -f $logFileName ]]; then
                tail -f $selectedTomcatLocation/logs/server.log
        else
                echo -e '\E[31;31m \t\t\t\t\t No logs found, waiting for 5 sec and trying again'; tput sgr0
                sleep 5
        fi
        done
        if [[  -f $logFileName ]]; then
                tail -f $selectedTomcatLocation/logs/server.log
        else
                echo -e '\E[31;31m \t\t\t\t\t No logs are generating, may be some prbm, please view others logs'; tput sgr0
                cd $selectedTomcatLocation/logs/
                ls -ltr $selectedTomcatLocation/logs/
	fi;;


2) 
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t Restarting - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0

	pid=$(ps -afe | grep $selectedTomcatLocation | grep -v grep | awk '{print $2}')
        if [[ -n $pid ]]; then
                kill -9 $pid
                echo -e '\E[31;31m \t\t\t\t\t !!!Tomcat Killed!!!'; tput sgr0 
        else
                echo -e '\E[36;36m \t\t\t\t\t !Tomcat not started!'; tput sgr0
        fi
        $selectedTomcatLocation/bin/startup.sh
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t tailing logs - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0

	logFileName=$selectedTomcatLocation/logs/server.log
        for i in {1..2}
        do
        if [[  -f $logFileName ]]; then
                tail -f $selectedTomcatLocation/logs/server.log
        else
                echo -e '\E[31;31m \t\t\t\t\t No logs found, waiting for 5 sec and trying again'; tput sgr0
                sleep 5
        fi
        done
        if [[  -f $logFileName ]]; then
                tail -f $selectedTomcatLocation/logs/server.log
        else
                echo -e '\E[31;31m \t\t\t\t\t No logs are generating, may be some prbm, please view others logs'; tput sgr0
                cd $selectedTomcatLocation/logs/
                ls -ltr $selectedTomcatLocation/logs/
        fi;;


3) 
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t Shutting Down - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0

pid=$(ps -afe | grep $selectedTomcatLocation | grep -v grep | awk '{print $2}')
	if [[ -n $pid ]];then
		$selectedTomcatLocation/bin/shutdown.sh
		sleep 6
		kill -9 $pid
                echo -e '\E[31;31m \t\t\t\t\t !!! Killing Tomcat!!!'; tput sgr0
	else
                echo -e '\E[36;31m \t\t\t\t\t !Tomcat not started!'; tput sgr0
	fi
echo -e '\E[31;31m searching for select '$selectedTomcat' again';tput sgr0
ps -afe | grep $selectedTomcatLocation;;

4)
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t Force killing - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0
pid=$(ps -afe | grep $selectedTomcatLocation | grep -v grep | awk '{print $2}')
        if [[ -n $pid ]]; then
                kill -9 $pid
                echo -e '\E[31;31m \t\t\t\t\t !!!Tomcat Killed!!!'; tput sgr0
        else
                echo -e '\E[36;36m \t\t\t\t\t !Tomcat not started!'; tput sgr0
        fi 
echo -e '\E[31;31m searching for select '$selectedTomcat' again';tput sgr0
ps -afe | grep $selectedTomcatLocation;;

5) 
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t removing logs - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0
rm -rvf $selectedTomcatLocation/logs/* ;;

6) 
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t cleaning webapps - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0
cd $selectedTomcatLocation ;;

7) 
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t Changing port properties - '$selectedTomcat'';
echo -e ' \t\t\t\t\t current port values for '$selectedTomcat' are:'
echo -e ' \t\t\t\t\t connectorPort :'$selectedConnectorPort''
echo -e ' \t\t\t\t\t shutdownPort  :'$selectedShutdownPort''
echo -e ' \t\t\t\t\t JPDA Port     :'$selectedjpdaPort''
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0

echo -e ""
echo -e ' \t\t\t\t\t Which port you want to change'
echo -e '\E[32;32m \t\t\t\t\t 1 - connectorPort of '$selectedTomcat''; tput sgr0
echo -e '\E[31;31m \t\t\t\t\t 2 - shutdownPort of '$selectedTomcat''; tput sgr0
echo -e '\E[34;34m \t\t\t\t\t 3 - jpda port of '$selectedTomcat''; tput sgr0

while true
do      
read portChangeReq
if [ $((portChangeReq)) -gt 3 ] || [ $((portChangeReq)) -lt 1 ] || [ -z $(echo $nextoption | sed -e 's/[A-Za-z]//g') ]; then        
        echo -e '\E[31;31m \t\t\t\t\t Are you kidding me, Please try again'; tput sgr0
else
break;
fi
done

case "$portChangeReq" in
1)echo -e '\t\t\t\t\t please enter new connector port:'
read newStartupPort
sed -i 's/Connector port=\"'$selectedConnectorPort'\"/Connector port=\"'$newStartupPort'\"/' $selectedTomcatLocation/conf/server.xml ;;
2)echo "pleas enter new shuutdown button port:" 
read newShutdownPort
sed -i 's/Server port=\"'$selectedShutdownPort'\"/Server port=\"'$newShutdownPort'\"/g' $selectedTomcatLocation/conf/server.xml;;
3)echo "pleas enter new connector port:" 
read newjpdaPort
sed -i '0,/JPDA_ADDRESS=\"'$selectedjpdaPort'\"/s//JPDA_ADDRESS=\"'$newjpdaPort'\"/' $selectedTomcatLocation/bin/catalina.sh ;;
esac
;;

8)
echo  -e '\E[32;32m \t==============================================================================================='
echo -e '\E[31;31m \t\t\t\t\t tailing logs - '$selectedTomcat'';
echo  -e '\E[32;32m \t==============================================================================================='; tput sgr0


logFileName=$selectedTomcatLocation/logs/server.log
        for i in {1..2}
        do
        if [[  -f $logFileName ]]; then
                tail -f $selectedTomcatLocation/logs/server.log
        else
                echo -e '\E[31;31m \t\t\t\t\t\ No logs found, waiting for 5 sec and trying again'; tput sgr0
                sleep 5
        fi
        done
        if [[  -f $logFileName ]]; then
                tail -f $selectedTomcatLocation/logs/server.log
        else
                echo -e '\E[31;31m \t\t\t\t\t No logs are generating, may be some prbm, please view others logs'; tput sgr0
                cd $selectedTomcatLocation/logs/
                ls -ltr $selectedTomcatLocation/logs/
        fi;;
esac

