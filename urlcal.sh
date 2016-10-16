#! /bin/sh
#@param: 
#		 1.url未去重数据源 /日期/(下面各个为设备文件夹,内含该设备的客户url识别zip)
#		 2.报表生成处
#urlcal.sh /ac/debug/fangzhenhua/url/20161009/IAM_4.1/
#含有一个参数
#
#未去重url识别率调用函数
#@param: 
#		 1.url未去重数据源 /日期/(下面各个为设备文件夹,内含该设备的客户url识别zip)
#		 2.报表生成处
#@return:
#		 NULL
#未去重待解压文件路径
param1=${1}
#去重带解压文件路径
param2=${2}      
#解压至路径
param3=${3}
#报表生成路径
PATHSCRIPT=`pwd`
url_total_1() {
FILEPATH=$1
UNZIPTOPATH=$2"/urlfiles"
#UNZIPTOPATH="/ac/debug/urlscan/urlfiles"
OTHERS=0
TOTAL=0
URLPERCENT=0
IAM11X=/ac/var/tmp
IAM4X=/tmp
URLREPORT=$2"/urlreport.csv"
URLSTAT=/urlstat.txt
LOGPATH=$2"/urlzip.log"
IAM4XURLVERSION="/etc/sinfor/fw/urllibver.txt"
IAM11XURLVERSION="/ac/etc/config/fw/urllibver.txt"
URLUPLOADFILLE=$2"/other_urlcount.csv"
if [ $# -lt 2 ]; then
	echo args error
	exit 12
fi

if [ ! -d $2 ] ;then
	echo "no path, will mkdir" $2 >> ${LOGPATH}
	mkdir $2
fi

echo $1 >> ${LOGPATH}


if [ ! -f ${URLREPORT} ]; then
	touch ${URLREPORT}
fi


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
				rm -rf ${UNZIPTOPATH}
				continue
			fi
			TOTAL=0
			for m in `awk 'NR!=1{print $NF}' urlstat.txt`
			do 
				TOTAL=$[${TOTAL}+$m]
				echo ${TOTAL} >> ${LOGPATH}
			done
			if [ -f ${UNZIPTOPATH}${IAM4XURLVERSION} ] ;then
				URLVERSION=`awk -F= '{print $2}' ${UNZIPTOPATH}/${IAM4XURLVERSION}`
				if [ ! ${URLVERSION} ] ;then
					URLVERSION="NONE"
				fi
			else
				URLVERSION="NULL"
			fi
			URLUPLOAD=`cat urlupload.txt | wc -l` 2>/dev/null
			if [ $? -eq 0 ] ;then
				echo ${i},${URLUPLOAD} >> ${URLUPLOADFILLE}
			fi
			OTHERS=`grep Others urlstat.txt | awk '{print $2}'`
			#如果不存在OTHERS 
			if [ ! ${OTHERS} ]; then
				echo "no others in "${i} >> ${LOGPATH}
				OTHERS=0
			fi
			#计算
			if [ ${TOTAL} -ne 0 ] ;then
				LEFTS=$[${TOTAL}-${OTHERS}]
			else
				rm -rf ${UNZIPTOPATH}
				continue
			fi
			URLPERCENT=$[$LEFTS*10000/$TOTAL]

			echo ${n},${i},${URLVERSION},`expr ${URLPERCENT} '/' 100`"."`expr ${URLPERCENT} '%' 100`"%",${TOTAL},${OTHERS}>> ${URLREPORT}

			rm -rf ${UNZIPTOPATH}
			echo "deleted ${UNZIPTOPATH}"
		else
			#存在ac文件夹 说明是 11.X的设备
			echo "this is IAM_11X" >> ${LOGPATH}
			cd ${UNZIPTOPATH}/${IAM11X}
			if [ ! -f ${UNZIPTOPATH}/${IAM11X}/${URLSTAT} ] ;then
				echo "no urlstat" >> ${LOGPATH}
				rm -rf ${UNZIPTOPATH}
				continue
			fi
			
			TOTAL=0
			
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

			URLUPLOAD=`cat urlupload.txt | wc -l` 2>/dev/null
			if [ $? -eq 0 ] ;then
				echo ${i},${URLUPLOAD} >> ${URLUPLOADFILLE}
			fi
			
			if [ ${TOTAL} -ne 0 ] ;then
				LEFTS=$[${TOTAL}-${OTHERS}]
			else
				rm -rf ${UNZIPTOPATH}
				continue
			fi
			
			OTHERS=`grep Others urlstat.txt | awk '{print $1}'`
			#如果不存在OTHERS 
			if [ ! ${OTHERS} ]; then
				echo "no others in "${i} >> ${LOGPATH}
				OTHERS=0
			fi
			echo "OTHERS="${OTHERS} >> ${LOGPATH}
			#计算
			LEFTS=$[${TOTAL}-${OTHERS}]
			URLPERCENT=$[$LEFTS*10000/$TOTAL]
			echo "URLPERCENT="${URLPERCENT} >> ${LOGPATH}
			
			echo ${n},${FILEPATH}${i},${URLVERSION},`expr ${URLPERCENT} '/' 100`"."`expr ${URLPERCENT} '%' 100`"%",${TOTAL},${OTHERS} >> ${URLREPORT}
			
			rm -rf ${UNZIPTOPATH}
			echo "deleted ${UNZIPTOPATH}"
		fi	
		echo "----------------------" >> ${LOGPATH}
	done
done
}
#未去重url识别率调用函数
#@param: 
#		 1.url去重数据源 /日期/(下面各个为设备文件夹,内含该设备的客户url识别zip)
#		 2.other_urlcount.csv 的路径 上一个函数的生成 parma2
#@return:
#		 NULL

url_total_2 () {
#压缩目的地 /ac/debug/urlfiles
unzip_path=$2"/urlfiles"
urlreport=$2"/urlreport.csv"
other_urlcount=$2"/other_urlcount.csv"
urlreport_final=$2"/urlreport_final.csv"
#压缩路径 /ac/debug/url_dp/     压缩文件名iam11.tar.gz
zip_path=$1
out_index=0
total=`ls ${zip_path}/*.zip | wc -l`


#对压缩文件进行循环
for zfile in `ls ${zip_path}`
do
  #id找到
  id=`basename ${zfile} | awk -F_ '{print $1}'`
  out_index=`expr ${out_index} + 1`
  echo -e "id: ${id}\t process: ${out_index}/${total}"
  if [ ! -d ${unzip_path} ] ;then
  	mkdir ${unzip_path}
  fi
  rm -rf ${unzip_path}/*
  7z x ${zip_path}/${zfile} -o${unzip_path} -psinfor86627902 -y > /dev/null
  mkdir ${unzip_path}/cmd
  mkdir ${unzip_path}/file

  tar -zxvf ${unzip_path}/cmd_info.tar.gz -C ${unzip_path}/cmd
  tar -zxvf ${unzip_path}/file_info.tar.gz -C ${unzip_path}/file
  if [ $? -ne 0 ]
  then
    echo "unzip ${zfile} failed"
  else
  	if [ -f ${urlreport} ] ;then
  		for i in `cat ${urlreport}` 
  		do
  			s21=0
  			s22=0
  			s1=0
			s11_return=0
			url_mdd_percent=0
  			id_dp=`echo ${i} | awk -F"/" '{print $6}'`
  			id_dp1=`echo ${id_dp} | awk -F"_" '{print $1}'`
  			
  			if [ "${id}" != "${id_dp1}" ] ;then
  				continue
  			else
  				echo ${id}  ${id_dp} >> /tmp/fangzhenhua
  			fi
		    #s1 from other_urlcount
		    s1=`grep ${id} ${other_urlcount} | awk -F"," '{printf $2}'`
		    if [ ${s1}x == ""x ] ;then
		    	continue
		    fi
		    s11_return=`echo ${s1} | wc -l`
		    if [ ${s11_return} -ne 1 ] ;then
		    	s1=NULL
		    fi
		    #s21 data from mdd mdd 可能会有1到多个
		    s21=`cat ${unzip_path}/cmd/total_urlcount_stat.log | grep mdd`
		    s21_return=`cat ${unzip_path}/cmd/total_urlcount_stat.log | grep mdd | wc -l`
		    echo "${s21_return}---->" >> /tmp/fangzhenhua
		    if [ ${s21_return} -ne 1 ] ;then
		      url_mdd_percent=NULL
		    else
		      s21=`echo ${s21} | awk '{printf $1}'`
		      if [ ${s21} -ne 0 -a ${s1}x != ""x ] ;then
		      	url_mdd_percent=$[$s1*10000/$s21]
		      else
		      	s21=NULL
		      	url_mdd_percent=NULL
		      fi
		    fi
		    echo ${s21} >> /tmp/fangzhenhua
		    #s22 data from DC dc可能没有
		    s22=`cat ${unzip_path}/cmd/total_urlcount_stat.log | grep DC`
		    s22_return=`cat ${unzip_path}/cmd/total_urlcount_stat.log | grep DC | wc -l`
		    if [ ${s22_return} -ne 1 ] ;then
		      url_DC_percent=NULL
		    else
		      s22=`echo ${s22} | awk '{printf $1}'`
		      if [ ${s22} -ne 0 -a ${s1}x != ""x ] ;then
		        url_DC_percent=$[$s1*10000/${s22}]
		      else
		      	s22=NULL
		      	url_DC_percent=NULL
		      fi
		    fi
		    if [ ${url_DC_percent} != "NULL" -a ${url_mdd_percent} != "NULL" ] ;then
    			echo ${i},${s1},${s21},${s22},`expr ${url_mdd_percent} '/' 100`"."`expr ${url_mdd_percent} '%' 100`"%",`expr ${url_DC_percent} '/' 100`"."`expr ${url_DC_percent} '%' 100`"%" >> ${urlreport_final}
			else
				echo ${i},${s1},NULL,NULL,NULL,NULL >> ${urlreport_final}
			fi
		done
	else
		echo no ${urlreport} bey
	fi
  fi
done

}

url_total_1 ${param1} ${param3}
cd ${PATHSCRIPT}
#输出表头
urlreport_final=${param3}"/urlreport_final.csv"
echo IAMversion,zipname,urlversion,url识别率,total,others_未去重,others_去重,total_mdd_去重后,total_DC_去重后,url识别率_mdd_去重,url识别率_DC_去重 >> ${urlreport_final}

url_total_2 ${param2} ${param3} 


echo lol


