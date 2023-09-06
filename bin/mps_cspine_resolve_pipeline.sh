#!/bin/bash -l

#DATAFOLDER=/home/porto-raid2/nestrasil-data/MPS/cspine_resolve
#APEND="_CSP"

DATAFOLDER=/home/range1-raid1/labounek/data-on-porto/controls/cspine_resolve
APEND=""

NIIFOLDER=$DATAFOLDER/nii
RESULTFOLDER=$DATAFOLDER/results
ANATFOLDER=$DATAFOLDER/results/anat
DMRIFOLDER=$DATAFOLDER/results/dmri
SAVEFOLDER=$RESULTFOLDER/tables

#for SUB in 20160519-ST001-2MPS1021-1 20160628-ST001-2MPS6002-1 20160823-ST001-2MPS1026-1; do # 20161003-ST001-2MPS1047-1
for SUB in $1; do # 20161003-ST001-2MPS1047-1
	SUBANATFOLDER=$ANATFOLDER/${SUB}${APEND}
	if [ ! -d $SUBANATFOLDER ]; then
		mkdir $SUBANATFOLDER
		chmod 770 $SUBANATFOLDER
	fi
	if [ ! -f $SUBANATFOLDER/t1sag.nii.gz ]; then
		cp $NIIFOLDER/${SUB}${APEND}/t1sag.nii.gz $SUBANATFOLDER/t1sag.nii.gz
	fi
	if [ ! -f $SUBANATFOLDER/t2sag.nii.gz ]; then
		cp $NIIFOLDER/${SUB}${APEND}/t2sag.nii.gz $SUBANATFOLDER/t2sag.nii.gz
	fi
	if [ ! -f $SUBANATFOLDER/t2tra.nii.gz ]; then
		cp $NIIFOLDER/${SUB}${APEND}/t2tra.nii.gz $SUBANATFOLDER/t2tra.nii.gz
	fi
	nice -n19 mps_cspine_anat_preproc.sh $SUBANATFOLDER $SAVEFOLDER


	SUBDMRIFOLDER=$DMRIFOLDER/${SUB}${APEND}
	if [ ! -d $SUBDMRIFOLDER ]; then
		mkdir $SUBDMRIFOLDER
		chmod 770 $SUBDMRIFOLDER
	fi
	if [ ! -f $SUBDMRIFOLDER/dmri_ap.nii.gz ]; then
		cp $NIIFOLDER/${SUB}${APEND}/dmri_ap.* $SUBDMRIFOLDER
	fi
	if [ ! -f $SUBDMRIFOLDER/dmri_pa.nii.gz ]; then
		cp $NIIFOLDER/${SUB}${APEND}/dmri_pa.* $SUBDMRIFOLDER
	fi
	nice -n19 mps_cspine_diff_analysis.sh $SUBDMRIFOLDER $SUBANATFOLDER $SAVEFOLDER
done
