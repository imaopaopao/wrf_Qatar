#!/bin/bash

############################
##########DOWNLOAD
############################
cd /work/swanson/jingchao/wrf_Qatar/WRF_forecast/WPS/source
for n in 000 003 006 009 012 015 018 021 024 027 030 033 036 039 042 045 048 051 054 057 060 063 066 069 072; do
	wget http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs."`date --utc +%Y%m%d`12"/gfs.t12z.pgrb2.0p50.f$n
done

############################
##########WPS
############################
#STEP 1: Build the links using ./link_grib.csh
cd /work/swanson/jingchao/wrf_Qatar/WRF_forecast/WPS; grfiles=GRIBFILE*; [[ "${#grfiles[@]}" -gt 0 ]] && rm GRIBFILE* 2> /dev/null
./link_grib.csh source/gfs*

#STEP 2: Unpack the GRIB data using ./ungrib.exe
sed -i "4s/.*/ start_date = '`date --utc +%Y-%m-%d`_12:00:00'/" namelist.wps
sed -i "5s/.*/ end_date   = '`date --utc --date='72 hour' +%Y-%m-%d`_12:00:00'/" namelist.wps
ugfiles=FILE*; [[ "${#ugfiles[@]}" -gt 0 ]] && rm FILE* 2> /dev/null
id1=`sbatch ungrib.submit | cut -d ' ' -f 4`

#STEP 3: Generate input data for WRFV3
metfiles=met_em*; [[ "${#metfiles[@]}" -gt 0 ]] && rm met_em* 2> /dev/null
id2=`sbatch -d afterok:$id1 metgrid.submit | cut -d ' ' -f 4`


############################
##########REAL
############################
cd /work/swanson/jingchao/wrf_Qatar/WRF_forecast/WRFV3/test/em_real
id3=`sbatch -d afterok:$id2 real.submit | cut -d ' ' -f 4`


############################
##########WRF
############################
id4=`sbatch -d afterok:$id3 wrf.submit | cut -d ' ' -f 4`


############################
##########NCL
############################
cd /lustre/work/swanson/jingchao/wrf_Qatar/code
id5=`sbatch -d afterok:$id4 ncl.submit | cut -d ' ' -f 4`

############################
##########PUSH
############################
id6=`sbatch -d afterok:$id5 ncl.submit | cut -d ' ' -f 4`