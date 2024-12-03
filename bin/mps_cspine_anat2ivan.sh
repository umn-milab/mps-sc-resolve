#!/bin/bash -l

DATAFOLDER=/home/porto-raid2/nestrasil-data/MPS/cspine_resolve
APEND="_CSP"

#DATAFOLDER=/home/range1-raid1/labounek/data-on-porto/controls/cspine_resolve
#APEND=""

IVANFOLDER=/home/range1-raid1/labounek/data-on-porto/shared/MPS-cspine-krasovecivan-20240925

NIIFOLDER=$DATAFOLDER/nii
RESULTFOLDER=$DATAFOLDER/results
ANATFOLDER=$DATAFOLDER/results/anat
DMRIFOLDER=$DATAFOLDER/results/dmri
SAVEFOLDER=$RESULTFOLDER/tables

cd $NIIFOLDER

for SUB in `ls -d 20170127-ST001-2MPS1041-2* 20170801-ST001-2MPS1048-1* 2019*`;do
	if [ ! -d $IVANFOLDER/$SUB ]; then
		mkdir $IVANFOLDER/$SUB
		chmod 770 $IVANFOLDER/$SUB
	fi

	if [ ! -f $IVANFOLDER/$SUB/t2sag.nii.gz ];then
		cp $SUB/t2sag.nii.gz $IVANFOLDER/$SUB/t2sag.nii.gz
	fi

	if [ ! -f $IVANFOLDER/$SUB/t1sag.nii.gz ];then
		cp $SUB/t1sag.nii.gz $IVANFOLDER/$SUB/t1sag.nii.gz
	fi

	if [ ! -f $IVANFOLDER/$SUB/t2tra.nii.gz ];then
		cp $SUB/t2tra.nii.gz $IVANFOLDER/$SUB/t2tra.nii.gz
	fi
	
	echo "$SUB: copy data done."
done


