#! /bin/sh

#urlcal.sh /ac/debug/fangzhenhua/url/20161009/IAM_4.1/
#含有一个参数

FILEPATH=$1
UNZIPTOPATH="/ac/debug/urlscan/urlfiles"
OTHERS=0
TOTAL=0
URLPERCENT=0
IAM11X=/ac/var/tmp
IAM4X=/tmp
URLREPORT="/ac/debug/urlscan/urlreport.csv"
URLSTAT=/urlstat.txt
LOGPATH="/ac/debug/urlscan/urlzip.log"
IAM4XURLVERSION="/etc/sinfor/fw/urllibver.txt"
IAM11XURLVERSION="/ac/etc/config/fw/urllibver.txt"
if [ $# -eq 0 ]; then
	echo error
	exit 12
fi
echo $1 >> ${LOGPATH}


if [ ! -f ${URLREPORT} ]; then
	touch ${URLREPORT}
fi

echo IAMversion,zipname,urlversion,url识别率 >> ${URLREPORT}

cd ${FILEPATH}

for n in `ls`
do
	cd ${FILEPATH}${n}
	for i in `ls`
	do
		echo "----------------------" >> ${LOGPATH} 
		if [ ! -d ${UNZIPTOPATH} ]; then
			echo "no path, will mkdir" ${UNZIPTOPATH} >> ${LOGPATH}
			mkdir ${UNZIPTOPATH}
		fi
		
		echo "filename:"${i} >> ${LOGPATH}
		
		tar -xzf ${FILEPATH}/${n}/${i} -C ${UNZIPTOPATH}
		
		if [ $? -ne 0 ] ;then
			echo "error zip" >> ${LOGPATH}
			rm -rf ${UNZIPTOPATH}
			echo "deleted ${UNZIPTOPATH}"
			continue
		fi
		
		cd ${UNZIPTOPATH}
		if [ ! -d ${UNZIPTOPATH}/ac ]; then
			echo "this is IAM_4X" >> ${LOGPATH}
			#不存在ac文件夹 说明是 4.X的设备
			cd ${UNZIPTOPATH}${IAM4X}
			if [ $? -ne 0 ] ;then
				echo ${n}/${i}
			fi
			if [ ! -f ${UNZIPTOPATH}${IAM4X}${URLSTAT} ] ;then
				echo "no urlstat" >> ${LOGPATH}
				continue
			fi
			for m in `awk 'NR!=1{print $NF}' urlstat.txt`
			do 
				TOTAL=$[${TOTAL}+$m]
				#echo ${TOTAL} >> ${LOGPATH}
			done
			if [ -f ${UNZIPTOPATH}${IAM4XURLVERSION} ] ;then
				URLVERSION=`awk -F= '{print $2}' ${UNZIPTOPATH}/${IAM4XURLVERSION}`
				if [ ! ${URLVERSION} ] ;then
					URLVERSION="NONE"
				fi
			else
				URLVERSION="NULL"
			fi
			OTHERS=`grep Others urlstat.txt | awk '{print $2}'`
			#如果不存在OTHERS 
			if [ ! ${OTHERS} ]; then
				echo "no others in "${i} >> ${LOGPATH}
				OTHERS=0
			fi
			#计算
			OTHERS=$[${TOTAL}-${OTHERS}]
			URLPERCENT=$[$OTHERS*10000/$TOTAL]

			echo ${n},${FILEPATH}${i},${URLVERSION},`expr ${URLPERCENT} '/' 100`"."`expr ${URLPERCENT} '%' 100`"%" >> ${URLREPORT}

			rm -rf ${UNZIPTOPATH}
			echo "deleted ${UNZIPTOPATH}"
		else
			#存在ac文件夹 说明是 11.X的设备
			echo "this is IAM_11X" >> ${LOGPATH}
			cd ${UNZIPTOPATH}/${IAM11X}
			if [ ! -f ${UNZIPTOPATH}/${IAM11X}/${URLSTAT} ] ;then
				echo "no urlstat" >> ${LOGPATH}
				continue
			fi
			for m in `awk '{print $1}' urlstat.txt`
			do 
				TOTAL=$[${TOTAL}+$m]
				echo ${TOTAL} >> ${LOGPATH}
			done
			
			if [ -f ${UNZIPTOPATH}/${IAM11XURLVERSION} ] ;then
				URLVERSION=`awk -F= '{print $2}' ${UNZIPTOPATH}/${IAM11XURLVERSION}`
				if [ ! ${URLVERSION} ] ;then
					URLVERSION="NONE"
				fi
			else
				URLVERSION="NULL"
			fi
			
			OTHERS=`grep Others urlstat.txt | awk '{print $1}'`
			#如果不存在OTHERS 
			if [ ! ${OTHERS} ]; then
				echo "no others in "${i} >> ${LOGPATH}
				OTHERS=0
			fi
			echo "OTHERS="${OTHERS} >> ${LOGPATH}
			#计算
			OTHERS=$[${TOTAL}-${OTHERS}]
			URLPERCENT=$[$OTHERS*10000/$TOTAL]
			echo "URLPERCENT="${URLPERCENT} >> ${LOGPATH}
			
			echo ${n},${FILEPATH}${i},${URLVERSION},`expr ${URLPERCENT} '/' 100`"."`expr ${URLPERCENT} '%' 100`"%" >> ${URLREPORT}
			
			rm -rf ${UNZIPTOPATH}
			echo "deleted ${UNZIPTOPATH}"
		fi	
		echo "----------------------" >> ${LOGPATH}
	done
done


