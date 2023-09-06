#!/bin/bash -l

CON=2

SAVEFOLDER=$2
DATA=$1
if [ ${DATA: -1} == "/" ];then
	DATA=${DATA%/}			# delete slash at the end if is containted		
fi
SUB="${DATA##*/}"
APD=${SUB: -4}
if [ $APD == "_CSP" ];then
	SUB=`echo $SUB | sed 's/.\{4\}$//'`
fi

NIFTI=/home/range1-raid1/labounek/toolbox/matlab/NIfTI_tools
BINDIR=/home/range1-raid1/labounek/git/mps-sc-resolve/bin
MATLABSCRIPTDIR=/home/range1-raid1/labounek/git/mps-sc-resolve/matlab
MATLABDIR=/opt/local/matlab2017b

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
cyan=`tput setaf 6`
magneta=`tput setaf 5`
bold=$(tput bold)
normal=$(tput sgr0)

print_help()
{
	LINE="===================================================================================================================="	
	SCRIPT_NAME=${0##*/}
	VERSION=26.09.2018	

	echo -e "$LINE\nHelp for script performing anatomical analysis of the spinal cord data, version $VERSION."
	echo -e "REQUIREMENTS: Installed bash interpreter, Matlab, FSL and Spinal Cord Toolbox libraries and BiasFiledCorrection tool\n(part of ANTS).\n$LINE"
	echo -e "Valosek Jan, Labounek Rene; jan.valosek@fnol.cz, rene.labounek@gmail.com; 2017-2018\nfMRI laboratory, University Hospital Olomouc and Palacky University Olomouc, Czechia\nDepartment of Pediatrics, University of Minnesota, Minneapolis, USA\n$LINE"
	exit
}


run_matlab()
{
	# Run Matlab without GUI in bash command line
	$MATLABDIR/bin/matlab -nosplash -nodisplay -nodesktop -r  "$1"
}

main()
{

	echo "$SUB: Starting analysis..."
#----------------------------------------------------------------------------------------------------
# Variable definition
	T1SAG=`ls ${DATA}/t1sag.nii.gz | sed 's/.\{7\}$//'` # sed deletes last 7 characters from original string and keeps it in variable $T2SAG
	T2SAG=`ls ${DATA}/t2sag.nii.gz | sed 's/.\{7\}$//'` # sed deletes last 7 characters from original string and keeps it in variable $T2SAG
	T2TRA=`ls ${DATA}/t2tra.nii.gz | sed 's/.\{7\}$//'` # sed deletes last 7 characters from original string and keeps it in variable $T2TRA
	
	cd ${DATA}
#----------------------------------------------------------------------------------------------------
# N4BiasFieldCorrection and thresholding of T2TRA and T2SAG

	if [ ! -f T1SAG_thr_bias_corr.nii.gz ] || [ ! -f T2TRA_thr_bias_corr.nii.gz ];then
        	# Thresholding of background noise
		fslmaths ${T2TRA}.nii.gz -thr 20 T2TRA_thr.nii.gz
		fslmaths ${T1SAG}.nii.gz -thr 20 T1SAG_thr.nii.gz
		fslmaths ${T2SAG}.nii.gz -thr 20 T2SAG_thr.nii.gz

        	# Binarize
		fslmaths T2TRA_thr.nii.gz -bin T2TRA_thr_bin.nii.gz
		fslmaths T1SAG_thr.nii.gz -bin T1SAG_thr_bin.nii.gz
		fslmaths T2SAG_thr.nii.gz -bin T2SAG_thr_bin.nii.gz

        	gunzip -f T2TRA_thr_bin.nii.gz
		gunzip -f T1SAG_thr_bin.nii.gz
		gunzip -f T2SAG_thr_bin.nii.gz

		# Call m-file fill_holes.m for filling holes in thresholded binarized image and remove small noise areas
		run_matlab "addpath('$MATLABSCRIPTDIR','$NIFTI'),fill_holes('T2TRA_thr_bin'),exit"
		run_matlab "addpath('$MATLABSCRIPTDIR','$NIFTI'),fill_holes('T1SAG_thr_bin'),exit"
		run_matlab "addpath('$MATLABSCRIPTDIR','$NIFTI'),fill_holes('T2SAG_thr_bin'),exit"
        
        	gzip -f T2TRA_thr_bin.nii T2TRA_thr_bin_fill.nii T1SAG_thr_bin.nii T1SAG_thr_bin_fill.nii T2SAG_thr_bin.nii T2SAG_thr_bin_fill.nii

		# Multiplying thresholded binarized filled image with original image -> thresholded original without holes
		fslmaths T2TRA_thr_bin_fill.nii.gz -mul ${T2TRA}.nii.gz T2TRA_thr_mul.nii.gz
		fslmaths T1SAG_thr_bin_fill.nii.gz -mul ${T1SAG}.nii.gz T1SAG_thr_mul.nii.gz
		fslmaths T2SAG_thr_bin_fill.nii.gz -mul ${T2SAG}.nii.gz T2SAG_thr_mul.nii.gz

		gunzip -f T2TRA_thr_mul.nii.gz T1SAG_thr_mul.nii.gz T2SAG_thr_mul.nii.gz

        	# Bias field correction by N4 function
		N4BiasFieldCorrection -d 3 -i T2TRA_thr_mul.nii -o T2TRA_thr_bias_corr.nii
		N4BiasFieldCorrection -d 3 -i T1SAG_thr_mul.nii -o T1SAG_thr_bias_corr.nii
		N4BiasFieldCorrection -d 3 -i T2SAG_thr_mul.nii -o T2SAG_thr_bias_corr.nii

		gzip -f T2TRA_thr_mul.nii T1SAG_thr_mul.nii T2TRA_thr_bias_corr.nii T1SAG_thr_bias_corr.nii T2SAG_thr_mul.nii T2SAG_thr_bias_corr.nii

		# Normalization 
		fslmaths T2TRA_thr_bias_corr.nii.gz -div `fslstats T2TRA_thr_bias_corr.nii.gz -R | cut -f 2 -d " "` T2TRA_thr_bias_corr.nii.gz
		fslmaths T1SAG_thr_bias_corr.nii.gz -div `fslstats T1SAG_thr_bias_corr.nii.gz -R | cut -f 2 -d " "` T1SAG_thr_bias_corr.nii.gz
		fslmaths T2SAG_thr_bias_corr.nii.gz -div `fslstats T2SAG_thr_bias_corr.nii.gz -R | cut -f 2 -d " "` T2SAG_thr_bias_corr.nii.gz

		# Following images can be removed for save disk space
		rm T2TRA_thr.nii.gz T1SAG_thr.nii.gz T2TRA_thr_bin.nii.gz T1SAG_thr_bin.nii.gz T2TRA_thr_bin_fill.nii.gz T1SAG_thr_bin_fill.nii.gz T2TRA_thr_mul.nii.gz T1SAG_thr_mul.nii.gz
		rm T2SAG_thr.nii.gz T2SAG_thr_bin_fill.nii.gz T2SAG_thr_mul.nii.gz
    	fi

    	# Outputs for next use - T2SAG_thr_bias_corr.nii.gz and T2TRA_thr_bias_corr.nii.gz
#----------------------------------------------------------------------------------------------------
# Slice-by-slice correction of T2TRA image
	
	#if [ ! -f isct_antsSliceRegularizedRegistration.log ];then
	#	
	#	run_matlab "addpath('$BINDIR','$NIFTI'),T2TRA_shift_correction_interp('T2TRA_thr_bias_corr','$BINDIR'),exit"	# Call matlab script for slice-by-slice correction (based on split T2TRA into odd and even slices)		
        #	fslmaths T2TRA_thr_bias_corr_odd_interp.nii -add T2TRA_thr_bias_corr_reg.nii.gz -div 2 T2TRA_thr_bias_corr_avg.nii.gz

	#	mv T2TRA_thr_bias_corr.nii.gz T2TRA_thr_bias_corr_old.nii.gz
	#	mv T2TRA_thr_bias_corr_avg.nii.gz T2TRA_thr_bias_corr.nii.gz

	#	rm odd_to_even.* slice_reg* T2TRA_thr_bias_corr_odd_interp.* T2TRA_thr_bias_corr_even_interp.* T2TRA_thr_bias_corr_reg.*

	#fi
#----------------------------------------------------------------------------------------------------
# Resampling and cropping of T2SAG

	if [ ! -f T1SAG_resample.nii.gz ];then

		sct_resample -i T1SAG_thr_bias_corr.nii.gz -mm 0.520833x0.520833x0.520833 -x spline -o T1SAG_resample.nii.gz -v 0
		fslmaths T1SAG_resample.nii.gz -thr 0 T1SAG_resample.nii.gz

		#sct_crop_image -i T1SAG_resample.nii.gz -o T1SAG_resample.nii.gz -start 0.15 -end 0.85 -dim 1 -v 0

	fi

	if [ ! -f T2SAG_resample.nii.gz ];then

		sct_resample -i T2SAG_thr_bias_corr.nii.gz -mm 0.520833x0.520833x0.520833 -x spline -o T2SAG_resample.nii.gz -v 0
		fslmaths T2SAG_resample.nii.gz -thr 0 T2SAG_resample.nii.gz

		#sct_crop_image -i T1SAG_resample.nii.gz -o T1SAG_resample.nii.gz -start 0.15 -end 0.85 -dim 1 -v 0

	fi
	
#----------------------------------------------------------------------------------------------------
# Spinal cord segmentation of T2SAG

	if [ ! -f T2SAG_resample_seg.nii.gz ];then

		sct_maths -i T2SAG_resample.nii.gz -mul 1000 -o T2SAG_resample_scaled.nii.gz -v 0
		sct_deepseg_sc -i T2SAG_resample_scaled.nii.gz -c t2 -v 0
		mv T2SAG_resample_scaled_seg.nii.gz T2SAG_resample_seg.nii.gz	
		rm T2SAG_resample_scaled.nii.gz
		#fsleyes T2SAG_resample.nii.gz T2SAG_resample_seg.nii.gz

	fi
#----------------------------------------------------------------------------------------------------
# Vertebrae labeling of T2SAG
	if [ ! -f T${CON}SAG_resample_seg_labeled.nii.gz ];then
		
		STR=1
		for st in `seq 2 10`;do
		    STR="$STR,$st"
		done
		sct_label_utils -i T${CON}SAG_resample.nii.gz -create-viewer $STR -o T${CON}SAG_resample_labels_disc.nii.gz -msg "Click at the posterior tip of each inter-vertebral disc, starting with C2/C3 (value=3) and going down."
		#sct_process_segmentation -i T${CON}SAG_resample_seg.nii.gz -p label-vert -discfile T${CON}SAG_resample_labels_disc.nii.gz
		sct_label_vertebrae -i T${CON}SAG_resample.nii.gz -s T${CON}SAG_resample_seg.nii.gz -discfile T${CON}SAG_resample_labels_disc.nii.gz -c t${CON}
		fsleyes T${CON}SAG_resample.nii.gz T${CON}SAG_resample_seg_labeled.nii.gz

	fi
#----------------------------------------------------------------------------------------------------
# Spinal cord segmentation of T2TRA by sct_deepseg_sc

	if [ ! -f T${CON}TRA_thr_bias_corr_seg.nii.gz ];then	

		sct_maths -i T${CON}TRA_thr_bias_corr.nii.gz -mul 1500 -o T${CON}TRA_thr_bias_corr_scaled.nii.gz -v 0
		sct_deepseg_sc -i T${CON}TRA_thr_bias_corr_scaled.nii.gz -c t${CON} -v 0 -centerline svm -kernel 2d #-brain 1 
		mv T${CON}TRA_thr_bias_corr_scaled_seg.nii.gz T${CON}TRA_thr_bias_corr_seg.nii.gz # svm
        	rm T${CON}TRA_thr_bias_corr_scaled.nii.gz
        	fsleyes T${CON}TRA_thr_bias_corr.nii.gz T${CON}TRA_thr_bias_corr_seg.nii.gz 
	fi
#----------------------------------------------------------------------------------------------------
# Spinal cord labeling of T2TRA    
	if [ ! -f T${CON}TRA_thr_bias_corr_seg_labeled.nii.gz ];then

		sct_register_multimodal -i T${CON}SAG_resample_seg.nii.gz -d T${CON}TRA_thr_bias_corr.nii.gz -identity 1 -x nn
		rm T${CON}SAG_resample_seg_reg.nii.gz T${CON}TRA_thr_bias_corr_reg.nii.gz
		sct_apply_transfo -i T${CON}SAG_resample_seg_labeled.nii.gz -d T${CON}TRA_thr_bias_corr.nii.gz -w warp_T${CON}SAG_resample_seg2T${CON}TRA_thr_bias_corr.nii.gz -o T${CON}TRA_warped_labels.nii.gz -x nn
		gunzip T${CON}TRA_warped_labels.nii.gz
		gunzip T${CON}TRA_thr_bias_corr_seg.nii.gz
		run_matlab "addpath('$MATLABSCRIPTDIR','$NIFTI'),umc_axial_labeling('T${CON}TRA_warped_labels.nii','T${CON}TRA_thr_bias_corr_seg.nii','T${CON}TRA_thr_bias_corr_seg_labeled.nii'),exit"
		gzip T${CON}TRA_thr_bias_corr_seg_labeled.nii
		rm T${CON}TRA_warped_labels.nii
		gzip T${CON}TRA_thr_bias_corr_seg.nii
		fsleyes T${CON}TRA_thr_bias_corr.nii.gz T${CON}TRA_thr_bias_corr_seg_labeled.nii.gz
	fi
#----------------------------------------------------------------------------------------------------
# Spinal cord volumetry metric extraction from T1TRA image
	
	if [ ! -f $SAVEFOLDER/${SUB}_t${CON}tra.csv ];then	

		sct_process_segmentation -i T${CON}TRA_thr_bias_corr_seg.nii.gz -perlevel 1 -vert 1:9 -vertfile T${CON}TRA_thr_bias_corr_seg_labeled.nii.gz -angle-corr 1 -append 0 -o $SAVEFOLDER/${SUB}_t${CON}tra.csv # -perslice 1 -p csa -no-angle 0
		#cp ${SUB}_t${CON}tra.csv $SAVEFOLDER/${SUB}_t${CON}tra.csv
		chmod 660 $SAVEFOLDER/${SUB}_t${CON}tra.csv
	fi
#----------------------------------------------------------------------------------------------------
# Spinal cord volumetry metric extraction from T1SAG image
	
	if [ ! -f $SAVEFOLDER/${SUB}_t${CON}sag.csv ];then	

		sct_process_segmentation -i T${CON}SAG_resample_seg.nii.gz -perlevel 1 -vert 1:11 -vertfile T${CON}SAG_resample_seg_labeled.nii.gz -angle-corr 1 -append 0 -o $SAVEFOLDER/${SUB}_t${CON}sag.csv # -perslice 1 -p csa -no-angle 0
		#cp ${SUB}_t${CON}sag.csv $SAVEFOLDER/${SUB}_t${CON}sag.csv
		chmod 660 $SAVEFOLDER/${SUB}_t${CON}sag.csv
	fi

#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
	chmod -R g=u ${DATA}
    	chmod -R o-rwx ${DATA}
	echo "$SUB: Analysis completed."
	#echo -e "You can check anatomical results in T2TRA space by FSLeyes:\n${green}fsleyes T2TRA_thr_bias_corr.nii.gz T2TRA_thr_bias_corr_seg.nii.gz -cm red -a 50 T2TRA_thr_bias_corr_gmseg.nii.gz -cm blue -a 50 T2TRA_thr_bias_corr_seg_labeled.nii.gz -cm subcortical -a 50${normal}"

}


if [ $# -ne 0 ];then
	main
else	
	print_help
fi
