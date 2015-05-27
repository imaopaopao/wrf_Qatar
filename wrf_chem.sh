#!/bin/sh
cd `dirname ${0}` || exit 1
. /util/opt/lmod/lmod/init/profile 2> /dev/null
export -f module 2> /dev/null
date --utc +%F-%R

#Download wrf_only files into the source directory
cd /work/swanson/jingchao/wrf/WRF_forecast/WPS/source
#Delete old fils if exist
files=nam.*; [[ "${#files[@]}" -gt 0 ]] && rm nam.* 2> /dev/null

#Fetch Files

hour=`date --utc +%H`
case $hour in
        "00" ) h_update=00 ;; "01" ) h_update=00 ;; "02" ) h_update=00 ;; "03" ) h_update=00 ;;
        "04" ) h_update=00 ;; "05" ) h_update=00 ;; "06" ) h_update=06 ;; "07" ) h_update=06 ;;
        "08" ) h_update=06 ;; "09" ) h_update=06 ;; "10" ) h_update=06 ;; "11" ) h_update=06 ;;
        "12" ) h_update=12 ;; "13" ) h_update=12 ;; "14" ) h_update=12 ;; "15" ) h_update=12 ;;
        "16" ) h_update=12 ;; "17" ) h_update=12 ;; "18" ) h_update=18 ;; "19" ) h_update=18 ;;
        "20" ) h_update=18 ;; "21" ) h_update=18 ;; "22" ) h_update=18 ;; "23" ) h_update=18 ;;
esac

for n in {0..72}; do    ###CHANGE HERE###
URL1="http://www.ftp.ncep.noaa.gov/data/nccf/com/nam/prod/nam.20`date --utc +%y%m%d`/nam.t"$h_update"z.awphys`printf "%02d" $n`.grb2.tm00"
URL2="http://www.ftp.ncep.noaa.gov/data/nccf/com/nam/prod/nam.20`date --utc +%y%m%d`/nam.t"$h_update"z.awphys`printf "%02d" $n`.grb2.tm00.idx"
wget $URL1 &> /dev/null
wget $URL2 &> /dev/null
done

#Run WPS
#STEP 1: Build the links using ./link_grib.csh
cd /work/swanson/jingchao/wrf/WRF_forecast/WPS
grfiles=GRIBFILE*; [[ "${#grfiles[@]}" -gt 0 ]] && rm GRIBFILE* 2> /dev/null
./link_grib.csh source/nam.t"$h_update"z.awphys*
#STEP 2: Unpack the GRIB data using ./ungrib.exe
sed -i "4s/.*/ start_date = '`date --utc +%Y-%m-%d`_"$h_update":00:00'/" namelist.wps				###CHANGE HERE###
sed -i "5s/.*/ end_date = '`date --utc --date='72 hour' +%Y-%m-%d`_"$h_update":00:00'/" namelist.wps		###CHANGE HERE###
ugfiles=FILE*; [[ "${#ugfiles[@]}" -gt 0 ]] && rm FILE* 2> /dev/null
id1=`sbatch ungrib.submit | cut -d ' ' -f 4`
#STEP 3: Generate input data for WRFV3
metfiles=met_em*; [[ "${#metfiles[@]}" -gt 0 ]] && rm met_em* 2> /dev/null
id2=`sbatch -d afterok:$id1 metgrid.submit | cut -d ' ' -f 4`

#Download 72 hours' fire files
#day1. Has to download files in this way because of the end/start month transition issue.
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/data/smoke/FLAMBE/
[[ ! -d "`date --utc +%Y`" ]] && mkdir `date --utc +%Y`; cd `date --utc +%Y`
[[ ! -d "`date --utc +%Y%m`" ]] && mkdir `date --utc +%Y%m`; cd `date --utc +%Y%m`; rm * 2> /dev/null
for i in {0..23}; do
wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date --utc +%Y`/`date --utc +%Y%m`/flambe_arctas_`date --utc +%Y%m%d``printf "%02d" $i`00.dat &> /dev/null
done
#day2
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/data/smoke/FLAMBE/
[[ ! -d "`date --utc --date='1 day' +%Y`" ]] && mkdir `date --utc --date='1 day' +%Y`; cd `date --utc --date='1 day' +%Y`
[[ ! -d "`date --utc --date='1 day' +%Y%m`" ]] && mkdir `date --utc --date='1 day' +%Y%m`; cd `date --utc --date='1 day' +%Y%m`
for i in {0..23}; do
wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date --utc --date='1 day' +%Y`/`date --utc --date='1 day' +%Y%m`/flambe_arctas_`date --utc --date='1 day' +%Y%m%d``printf "%02d" $i`00.dat &> /dev/null
done
#day3
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/data/smoke/FLAMBE/
[[ ! -d "`date --utc --date='2 day' +%Y`" ]] && mkdir `date --utc --date='2 day' +%Y`; cd `date --utc --date='2 day' +%Y`
[[ ! -d "`date --utc --date='2 day' +%Y%m`" ]] && mkdir `date --utc --date='2 day' +%Y%m`; cd `date --utc --date='2 day' +%Y%m`
for i in {0..23}; do
wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date --utc --date='2 day' +%Y`/`date --utc --date='2 day' +%Y%m`/flambe_arctas_`date --utc --date='2 day' +%Y%m%d``printf "%02d" $i`00.dat &> /dev/null
done
#day4
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/data/smoke/FLAMBE/
[[ ! -d "`date --utc --date='3 day' +%Y`" ]] && mkdir `date --utc --date='3 day' +%Y`; cd `date --utc --date='3 day' +%Y`
[[ ! -d "`date --utc --date='3 day' +%Y%m`" ]] && mkdir `date --utc --date='3 day' +%Y%m`; cd `date --utc --date='3 day' +%Y%m`
for i in {0..23}; do
wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date --utc --date='3 day' +%Y`/`date --utc --date='3 day' +%Y%m`/flambe_arctas_`date --utc --date='3 day' +%Y%m%d``printf "%02d" $i`00.dat &> /dev/null
done
#day5
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/data/smoke/FLAMBE/
[[ ! -d "`date --utc --date='4 day' +%Y`" ]] && mkdir `date --utc --date='4 day' +%Y`; cd `date --utc --date='4 day' +%Y`
[[ ! -d "`date --utc --date='4 day' +%Y%m`" ]] && mkdir `date --utc --date='4 day' +%Y%m`; cd `date --utc --date='4 day' +%Y%m`
for i in {0..23}; do
wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date --utc --date='4 day' +%Y`/`date --utc --date='4 day' +%Y%m`/flambe_arctas_`date --utc --date='4 day' +%Y%m%d``printf "%02d" $i`00.dat &> /dev/null
done

#Run WEPS
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/results; rm * 2> /dev/null
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/run
sed -i "5s/.*/START_YEAR                   : `date --utc +%Y`       2012       2012/" namelist.weps
sed -i "6s/.*/START_MONTH                  : `date --utc +%m`         09         09/" namelist.weps
sed -i "7s/.*/START_DAY                    : `date --utc +%d`         15         15/" namelist.weps
sed -i "8s/.*/START_HOUR                   : 01         01         01/" namelist.weps
sed -i "9s/.*/END_YEAR                     : `date --utc --date='96 hour' +%Y`       2012       2012/" namelist.weps
sed -i "10s/.*/END_MONTH                    : `date --utc --date='96 hour' +%m`         09         09/" namelist.weps
sed -i "11s/.*/END_DAY                      : `date --utc --date='96 hour' +%d`         29         29/" namelist.weps
sed -i "12s/.*/END_HOUR                     : 24         24         24/" namelist.weps
id3=`sbatch weps.submit | cut -d ' ' -f 4`

#Run WRFV3
cd /work/swanson/jingchao/wrf/WRF_forecast/WRF_chem/test/em_real
lfiles=met_em*; [[ "${#lfiles[@]}" -gt 0 ]] && rm met_em* 2> /dev/null
id4=`sbatch -d afterok:$id2:$id3 real.submit | cut -d ' ' -f 4`
id5=`sbatch -d afterok:$id4 convert.submit | cut -d ' ' -f 4`
id6=`sbatch -d afterany:$id5 real.submit2 | cut -d ' ' -f 4`
id7=`sbatch -d afterok:$id6 wrf.submit | cut -d ' ' -f 4`

#RESULTS TRANSFER
cd /work/swanson/jingchao/wrf/data/wrf_chem
find . -type d -mtime +2 | xargs rm -rf
[[ ! -d "`date --utc +%Y%m%d`" ]] && mkdir `date --utc +%Y%m%d`; cd `date --utc +%Y%m%d`
ndir="`date --utc +%y%m%d`$h_update"
mkdir $ndir && cd $ndir
#cp /work/swanson/jingchao/wrf/WRF_forecast/WPS/dir.submit ./
cp /work/swanson/jingchao/wrf/code/dir.submit ./
id8=`sbatch -d afterany:$id7 dir.submit | cut -d ' ' -f 4`

########################
#Copy files to igorso
#cd /work/visunl/sdagguma
cd /work/visunl/igorso
find . -type d -mtime +2 | xargs rm -rf
[[ ! -d "`date --utc +%Y%m%d`" ]] && mkdir `date --utc +%Y%m%d`; cd `date --utc +%Y%m%d`
ndir="`date --utc +%y%m%d`$h_update"
mkdir $ndir && cd $ndir
cp /work/swanson/jingchao/wrf/code/dir.submit ./
sbatch dir.submit
########################

cd /work/swanson/jingchao/wrf/code
id9=`sbatch -d afterany:$id7 ncl.submit | cut -d ' ' -f 4`
id10=`sbatch -d afterany:$id9 push.submit | cut -d ' ' -f 4`

echo "Submitted batch job $id1 (ungrib) -> $id2 (metgrid) -> $id3 (WEPS) -> $id4 (REAL1) -> $id5 (convert) -> $id6 (real2) -> $id7 (wrf) -> $id8 (transfer) -> $id9 (NCL) -> $id10 (push)"
