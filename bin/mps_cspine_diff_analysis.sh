#!/bin/bash -l

ANATFOLDER=$2
SAVEFOLDER=$3

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

	echo -e "$LINE\nHelp for script performing analysis of the spinal cord diffusion data (ZOOMit and/or RESOLVE), version $VERSION."
	echo -e "Analysis contains:\n\tdiffusion preprocessing (merge AP and PA b0 images) with or withnout motion correction by sct_dmri_moco\n\ttopup and eddy (with whole FOV or with manually segmented mask of SC from topup_mean image)\n\tDTI estimation (using dtifit)\n\tregistration between T2TRA and DIFF spaces\n\tvertebrae labeling in DIFF space\n\tmasking results from dtifit by mask of SC"
	echo -e "REQUIREMENTS: Installed bash interpreter, Matlab, FSL and Spinal Cord Toolbox libraries.\n$LINE"
	echo -e "USAGE:\n\n$SCRIPT_NAME <path to subjects directory> <subject> <diff. seq. order>\n\nEXAMPLE:\n\n$SCRIPT_NAME /md2/NA-CSD 2007B 11001"
	echo -e "or\n$SCRIPT_NAME /md2/NA-CSD subjects.txt\n$LINE"
	echo -e "Valosek, Labounek 2018\tfMRI laboratory, Olomouc, CZ\n$LINE"
	exit
}


run_matlab()
{
	# Run Matlab without GUI in bash command line
	$MATLABDIR/bin/matlab -nosplash -nodisplay -nodesktop -r  "$1"
}

main()
{
	RESOLVE_AP=${DATA}/dmri_ap
	RESOLVE_PA=${DATA}/dmri_pa
	READOUT=0.0198



	FOLDER="sct-moco"
	if [ ! -d $DATA/$FOLDER ]; then
		mkdir $DATA/$FOLDER
		chmod 770 $DATA/$FOLDER
	fi

	if [ ! -f $DATA/$FOLDER/dmri_ap_moco.nii.gz ]; then
		cd $DATA/$FOLDER
		#sct_dmri_moco -i ${RESOLVE_AP}.nii.gz -bvec ${RESOLVE_AP}.bvec -bval ${RESOLVE_AP}.bval -g 2 -param 2,1,0.5,MeanSquares -x nn -ofolder $DATA/$FOLDER/ -r 1 -v 0 #-m dmri_mask.nii.gz
		sct_dmri_moco -i ${RESOLVE_AP}.nii.gz -bvec ${RESOLVE_AP}.bvec -ofolder $DATA/$FOLDER/ #-m dmri_mask.nii.gz
		ln -s dmri_ap_moco_dwi_mean.nii.gz dwi_mean.nii.gz
		ln -s dmri_ap_moco_b0_mean.nii.gz b0_mean.nii.gz
	else
		echo "${green}$(date +%x_%T): Preprocessing of diffusion data in $DATA/$FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/dMRI/dti_FA.nii.gz ]; then
		dtifitmoco_function $DATA $FOLDER		# Call function for dtifit
	else
		echo "${green}$(date +%x_%T): Estimation of DTI model using dtifit on data in $FOLDER folder is done.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/dMRI/dti_RD.nii.gz ]; then
		rd_function $DATA $FOLDER		# Call function for dtifit
	else
		echo "${green}$(date +%x_%T): Estimation of RD and AD on data in $FOLDER folder is done.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/T2TRA_in_DIFF.nii.gz ]; then
		t2tra_to_diff_function $DATA $FOLDER		# Call function for registration between T2TRA and DIFF spaces
	else
		echo "${green}$(date +%x_%T): registration between T2TRA and DIFF spaces in $FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/dwi_mean_seg_labeled.nii.gz ]; then
		difflabel_function $DATA $FOLDER		# Call function for labeling of diff data
	else
		echo "${green}$(date +%x_%T): labeling of diff data in $FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/dMRI/dti_FA_cord.nii* ]; then
		masking $DATA $FOLDER		# Call function for masking
	else
		echo "${green}$(date +%x_%T): masking off diffusion data and warping diffusion data into T2TRA in $FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $SAVEFOLDER/${SUB}_FA_level-specific_${FOLDER}.csv ]; then
		metricextract_function $DATA $FOLDER		# Call function for labeling of diff data
	else
		echo "${green}$(date +%x_%T): dMRI level-specific metric extraction in $FOLDER folder has been done before.${normal}"
	fi

	chmod -R g=u $DATA/$FOLDER
	chmod -R o-rwx $DATA/$FOLDER


	FOLDER="topup-eddy"
	if [ ! -d $DATA/$FOLDER ]; then
		mkdir $DATA/$FOLDER
		chmod 770 $DATA/$FOLDER
		diff_prep $RESOLVE_AP $RESOLVE_PA $READOUT $FOLDER $DATA	# Call diff_preop function
	else
		echo "${green}$(date +%x_%T): Preprocessing of diffusion data in $DATA/$FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/b0_topup.nii.gz ]; then
		topup_function $DATA $FOLDER		# Call function for topup
	else
		echo "${green}$(date +%x_%T): topup on data in $DATA/$FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/eddy.nii.gz ]; then
		eddy_function $DATA $FOLDER		# Call function for eddy
	else
		echo "${green}$(date +%x_%T): eddy on data in $DATA/$FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/dMRI/dti_FA.nii.gz ]; then
		dtifit_function $DATA $FOLDER		# Call function for dtifit
	else
		echo "${green}$(date +%x_%T): Estimation of DTI model using dtifit on data in $FOLDER folder is done.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/dMRI/dti_RD.nii.gz ]; then
		rd_function $DATA $FOLDER		# Call function for dtifit
	else
		echo "${green}$(date +%x_%T): Estimation of RD and AD on data in $FOLDER folder is done.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/T2TRA_in_DIFF.nii.gz ]; then
		t2tra_to_diff_function $DATA $FOLDER		# Call function for registration between T2TRA and DIFF spaces
	else
		echo "${green}$(date +%x_%T): registration between T2TRA and DIFF spaces in $FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/dwi_mean_seg_labeled.nii.gz ]; then
		difflabel_function $DATA $FOLDER		# Call function for labeling of diff data
	else
		echo "${green}$(date +%x_%T): labeling of diff data in $FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $DATA/$FOLDER/dMRI/dti_FA_cord.nii* ]; then
		masking $DATA $FOLDER		# Call function for masking
	else
		echo "${green}$(date +%x_%T): masking off diffusion data and warping diffusion data into T2TRA in $FOLDER folder has been done before.${normal}"
	fi

	if [ ! -f $SAVEFOLDER/${SUB}_FA_level-specific_${FOLDER}.csv ]; then
		metricextract_function $DATA $FOLDER		# Call function for labeling of diff data
	else
		echo "${green}$(date +%x_%T): dMRI level-specific metric extraction in $FOLDER folder has been done before.${normal}"
	fi

	chmod -R g=u $DATA/$FOLDER
	chmod -R o-rwx $DATA/$FOLDER

}

#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for diffusion preprocessing of RESOLVE data
diff_prep()
{
	
	RESOLVE_AP=$1
	RESOLVE_PA=$2
	READOUT=$3
	FOLDER=$4
	DATA=$5

	echo "${yellow}$(date +%x_%T): Starting preprocessing of diffusion data in $DATA/$FOLDER folder!${normal}"

	cd $DATA/$FOLDER

	fslmerge -a eddy_input.nii.gz ${RESOLVE_AP}.nii.gz ${RESOLVE_PA}.nii.gz # Merge AP and PA ZOOMit data into one file

	echo "`cat ${RESOLVE_AP}.bval` `cat ${RESOLVE_PA}.bval`" > eddy_input.bval	# Create eddy_input.bval file by merge bval files of RESOLVE_AP and RESOLVE_PA
	paste -d " " ${RESOLVE_AP}.bvec ${RESOLVE_PA}.bvec > eddy_input.bvec	# Create eddy_input.bvec file by merge bvec files of RESOLVE_AP and RESOLVE_PA
	

	B0INDEX=""
	fslsplit eddy_input.nii.gz temporary	# Split RESOLVE data into infividual images
	B0IND=0
	IMAGEID=0

	MERGECOMMAND="fslmerge -a b0.nii.gz" 
	for BVAL in `cat eddy_input.bval`;do			# Create variable B0INDEX containg order of b0 images in merged file
		if [ $BVAL -eq 0 ];then
			B0IND=$(($B0IND+1))
			MERGECOMMAND="$MERGECOMMAND temporary`printf %04d $IMAGEID`.nii.gz"
		fi
		B0INDEX="$B0INDEX $B0IND"
		IMAGEID=$(($IMAGEID+1))
	done
	echo $B0INDEX > index.txt
	B0NUM=`cat index.txt | awk '{print $NF}'`			# Count number of b0 images in merged file
	B0AP=$(($B0NUM/2))

	echo "0 -1 0 $READOUT" > acq_file.txt	
	for MES in `seq 2 $B0NUM`;do					# Create acq_file which is necessary for topup
		if [ $MES -le $B0AP ];then
			echo "0 -1 0 $READOUT" >> acq_file.txt
		else
			echo "0 1 0 $READOUT" >> acq_file.txt
		fi
	done

	`echo $MERGECOMMAND`						# Create file containing only b0 images
	rm temporary*.nii.gz

	echo "${yellow}$(date +%x_%T): Preprocessing of diffusion data in $DATA/$FOLDER folder is done.${normal}"

}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for topup and mean of data after topup
topup_function()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting topup on data in $FOLDER folder!${normal}"
	
	cd $DATA/$FOLDER

	topup --imain=b0.nii.gz --datain=acq_file.txt --out=topup --subsamp=1,1,1,1,1,1,1,1,1 --config=b02b0.cnf --iout=b0_topup --fout=field_topup -v > topup_stdout.txt

	fslmaths b0_topup.nii.gz -Tmean b0_topup_mean.nii.gz # mean b0

	echo "${yellow}$(date +%x_%T): topup on data in $DATA/$FOLDER folder is done.${normal}"
	
}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for eddy (eddy uses either manually segmented mask of SC or whole binarized FOV)
eddy_function()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting eddy on data in $FOLDER folder!${normal}"

	cd $DATA/$FOLDER
	

    EDDYCMD="eddy_openmp"

    if [ ! -f $DATA/$FOLDER/b0_topup_mean_seg.nii.gz ] && [ ! -f $DATA/$FOLDER/b0_topup_mean_bin.nii.gz ];then
		echo "${yellow}$(date +%x_%T): Manually segmented mask of the spinal cord in $DATA/$FOLDER with name b0_topup_mean_seg.nii.gz is not found!${normal}"
		echo "${yellow}$(date +%x_%T): Starting eddy on data in $DATA/$FOLDER folder with binarized FOV as mask!${normal}"
		fslmaths b0_topup_mean.nii.gz -bin b0_topup_mean_bin.nii.gz		
		${EDDYCMD} --imain=eddy_input.nii.gz --mask=b0_topup_mean_bin.nii.gz --index=index.txt --acqp=acq_file.txt --bvecs=eddy_input.bvec --bvals=eddy_input.bval --topup=topup --out=eddy -v > eddy_stdout.txt
		echo "${yellow}$(date +%x_%T): eddy on data in $DATA/$FOLDER folder with binarized FOV as mask is done!${normal}"
	fi
}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for estimation of DTI model using dtifit
dtifit_function()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting estimation of DTI model using dtifit on data in $FOLDER folder.${normal}"
	
	if [ ! -d $DATA/$FOLDER/dMRI ];then
		mkdir $DATA/$FOLDER/dMRI
		chmod 770 $DATA/$FOLDER/dMRI
	fi
	cd $DATA/$FOLDER
	
	cp eddy.nii.gz dMRI/data.nii.gz
	cp eddy_input.bval dMRI/bvals
	cp eddy.eddy_rotated_bvecs dMRI/bvecs

	if [ -f $DATA/$FOLDER/b0_topup_mean_seg.nii.gz ];then 
		cp b0_topup_mean_seg.nii.gz dMRI/nodif_brain_mask.nii.gz
	elif [ ! -f $DATA/$FOLDER/b0_topup_mean_seg.nii.gz ] && [ -f $DATA/$FOLDER/b0_topup_mean_bin.nii.gz ];then
		cp b0_topup_mean_bin.nii.gz dMRI/nodif_brain_mask.nii.gz
	else
		error "Problem during copy data into dMRI folder happened (b0_topup_mean_seg.nii.gz nor b0_topup_mean_bin.nii.gz dMRI/nodif_brain_mask.nii.gz do not exist)!"	
	fi

	cd $DATA/$FOLDER/dMRI
	dtifit -k data.nii.gz -o dti -m nodif_brain_mask.nii.gz -r bvecs -b bvals -w
	
	echo "${yellow}$(date +%x_%T): Estimation of DTI model using dtifit on data in $FOLDER folder is done.${normal}"	
}

#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for estimation of RD and AD
rd_function()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting estimation of RD and AD on data in $FOLDER folder.${normal}"
	
	cd $DATA/$FOLDER/dMRI
	ln -s dti_L1.nii.gz dti_AD.nii.gz
	fslmaths dti_L2.nii.gz -add dti_L3.nii.gz -div 2 dti_RD.nii.gz
	
	echo "${yellow}$(date +%x_%T): Estimation of RD and AD on data in $FOLDER folder is done.${normal}"	
}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for T2TRA coregistration to DIFF space and SC segmentation in DIFF space (dwi_mean image)
t2tra_to_diff_function()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting T2TRA and diffusion data coregistration in $DATA/$FOLDER folder.${normal}"

	cd $DATA/$FOLDER

	if [ $FOLDER == "topup-eddy" ]; then
		cp eddy.eddy_rotated_bvecs bvecs		# necessary, because sct_dmri_separate_b0_and_dwi does not recognize file type .eddy_rotated_bvecs
		sct_dmri_separate_b0_and_dwi -i eddy.nii.gz -bvec bvecs -a 1 -bval eddy_input.bval -r 1
		rm bvecs
		mv eddy_dwi_mean.nii.gz dwi_mean.nii.gz
		mv eddy_b0_mean.nii.gz b0_mean.nii.gz
		mv eddy_dwi.nii.gz dwi.nii.gz
		mv eddy_b0.nii.gz b0.nii.gz
	fi

	sct_register_multimodal -i $ANATFOLDER/T2TRA_thr_bias_corr_seg.nii.gz -d dwi_mean.nii.gz -identity 1 -x nn -o T2TRA_seg_in_DIFF.nii.gz	# used as init centerline for propseg in next step
	mv warp_dwi_mean2T2TRA_thr_bias_corr_seg.nii.gz warp_DIFFtoT2TRA.nii.gz
	mv warp_T2TRA_thr_bias_corr_seg2dwi_mean.nii.gz warp_T2TRAtoDIFF.nii.gz
	mv T2TRA_seg_in_DIFF_inv.nii.gz dwi_mean_in_T2TRA.nii.gz

	if [ ! -f dwi_mean_seg.nii.gz ];then
		echo "${yellow}$(date +%x_%T): Starting SC segmentation in $DATA/$FOLDER folder using sct_deepseg.${normal}"
		sct_deepseg_sc -i dwi_mean.nii.gz -c dwi
		fsleyes dwi_mean.nii.gz dwi_mean_seg.nii.gz
		echo "${yellow}$(date +%x_%T): SC segmentation in $DATA/$FOLDER folder using sct_deepseg is done.${normal}"
	fi

	sct_register_multimodal -i b0_mean.nii.gz -d $ANATFOLDER/T2TRA_thr_bias_corr.nii.gz -iseg dwi_mean_seg.nii.gz -dseg $ANATFOLDER/T2TRA_thr_bias_corr_seg.nii.gz -param step=1,type=seg,algo=slicereg,metric=CC,smooth=5:step=2,type=seg,algo=bsplinesyn,metric=CC,smooth=1,iter=3 -initwarp warp_DIFFtoT2TRA.nii.gz -initwarpinv warp_T2TRAtoDIFF.nii.gz
	mv T2TRA_thr_bias_corr_reg.nii.gz T2TRA_in_DIFF.nii.gz
	mv b0_mean_reg.nii.gz b0_mean_in_T2TRA.nii.gz
	mv warp_T2TRA_thr_bias_corr2b0_mean.nii.gz warp_T2TRAtoDIFF.nii.gz
	mv warp_b0_mean2T2TRA_thr_bias_corr.nii.gz warp_DIFFtoT2TRA.nii.gz
	#rm -r qc

	echo "${yellow}$(date +%x_%T): T2TRA and diffusion data coregistration in $FOLDER folder is done!${normal}"
}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for vertebrae levels labeling in diff space 
difflabel_function()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting labeling of diffusion data in $DATA/$FOLDER folder!${normal}"	

	cd $DATA/$FOLDER

	sct_apply_transfo -i $ANATFOLDER/T2TRA_thr_bias_corr_seg_labeled.nii.gz -d b0_mean.nii.gz -w warp_T2TRAtoDIFF.nii.gz -o b0_mean_warped_labels.nii.gz -x nn

	gunzip b0_mean_warped_labels.nii.gz
	gunzip dwi_mean_seg.nii.gz
	run_matlab "addpath('$MATLABSCRIPTDIR','$NIFTI'),umc_axial_labeling('b0_mean_warped_labels.nii','dwi_mean_seg.nii','dwi_mean_seg_labeled.nii'),exit"
	gzip dwi_mean_seg_labeled.nii
	rm b0_mean_warped_labels.nii
	gzip dwi_mean_seg.nii


	#fslmaths b0_mean_warped_labels.nii.gz -mas dwi_mean_centerline.nii.gz -Xmax -Ymax -uthr 3 -thr 3 output
	#C3C4SLICE=`fslstats output.nii.gz -w | cut -d' ' -f5`
	#rm output.nii.gz
	#sct_label_vertebrae -i b0_mean.nii.gz -s dwi_mean_seg.ni* -c t2 -initz $C3C4SLICE,3 -r 1
	##sct_label_vertebrae -i T2TRA_in_DIFF.nii.gz -s dwi_mean_seg.ni* -c t2 -initz $C3C4SLICE,3 -r 1

	echo "${yellow}$(date +%x_%T): labeling of diffusion data in $FOLDER folder is done!${normal}"

}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Masking of results from dtifit and warping these results into T2TRA space
masking()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting masking of diffusion data in $DATA/$FOLDER folder.${normal}"

	cd $DATA/$FOLDER

	fslmaths dMRI/dti_FA.nii.gz -mas dwi_mean_seg.nii.gz dMRI/dti_FA_cord.nii.gz
	#gunzip dMRI/dti_${NAME}_FA_cord.nii.gz
	fslmaths T2TRA_in_DIFF.nii.gz -mas dwi_mean_seg.nii.gz T2TRA_in_DIFF_cord.nii.gz
	#gunzip T2TRA_in_DIFF_cord.nii.gz
	fslmaths dMRI/dti_MD.nii.gz -mas dwi_mean_seg.nii.gz dMRI/dti_MD_cord.nii.gz
	#gunzip dMRI/dti_${NAME}_MD_cord.nii.gz

	echo "${yellow}$(date +%x_%T): masking of diffusion data in $FOLDER folder is done!${normal}"

# Warping DIFF results into T2TRA
	echo "${yellow}$(date +%x_%T): Starting warping diffusion data into T2TRA in $DATA/$FOLDER folder.${normal}"

	if [ ! -d diff_in_t2tra ];then
		mkdir diff_in_t2tra
		chmod 770 diff_in_t2tra
	fi

	for j in dMRI/dti_FA.nii.gz dMRI/dti_FA_cord.nii.gz dMRI/dti_MD.nii.gz dMRI/dti_MD_cord.nii.gz dwi_mean_seg.nii.gz b0_mean.nii.gz dwi_mean.nii.gz dMRI/dti_V1.nii.gz;do
		OUTPUT=`echo $j | sed 's:.*/::g'`	#delete string before slash if is contained
		sct_apply_transfo -i $DATA/$FOLDER/$j -d $ANATFOLDER/T2TRA_thr_bias_corr.nii.gz -w $DATA/$FOLDER/warp_DIFFtoT2TRA.nii.gz -o $DATA/$FOLDER/diff_in_t2tra/$OUTPUT
	done

	if [ $FOLDER == "topup-eddy" ];then
		j="field_topup.nii.gz"
		OUTPUT=`echo $j | sed 's:.*/::g'`	#delete string before slash if is contained
		sct_apply_transfo -i $DATA/$FOLDER/$j -d $ANATFOLDER/T2TRA_thr_bias_corr.nii.gz -w $DATA/$FOLDER/warp_DIFFtoT2TRA.nii.gz -o $DATA/$FOLDER/diff_in_t2tra/$OUTPUT
	fi
	
	fslmaths $DATA/$FOLDER/diff_in_t2tra/dwi_mean_seg.nii.gz -thr 0.75 -bin $DATA/$FOLDER/diff_in_t2tra/dwi_mean_seg.nii.gz
	fslmaths $DATA/$FOLDER/diff_in_t2tra/dti_FA_cord.nii.gz -thr 0.1 $DATA/$FOLDER/diff_in_t2tra/dti_FA_cord.nii.gz
	fslmaths $DATA/$FOLDER/diff_in_t2tra/dti_MD_cord.nii.gz -thr 0.00001 -mas $DATA/$FOLDER/diff_in_t2tra/dwi_mean_seg.nii.gz $DATA/$FOLDER/diff_in_t2tra/dti_MD_cord.nii.gz
}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for estimation of DTI model using dtifit
dtifitmoco_function()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting estimation of DTI model using dtifit on data in $FOLDER folder.${normal}"
	
	if [ ! -d $DATA/$FOLDER/dMRI ];then
		mkdir $DATA/$FOLDER/dMRI
		chmod 770 $DATA/$FOLDER/dMRI
	fi
	cd $DATA/$FOLDER
	
	cp dmri_ap_moco.nii.gz dMRI/data.nii.gz
	cp ${RESOLVE_AP}.bval dMRI/bvals
	cp ${RESOLVE_AP}.bvec dMRI/bvecs
	
	fslmaths dmri_ap_moco.nii.gz -add 10000 -bin dMRI/nodif_brain_mask.nii.gz

	cd $DATA/$FOLDER/dMRI
	dtifit -k data.nii.gz -o dti -m nodif_brain_mask.nii.gz -r bvecs -b bvals -w
	
	echo "${yellow}$(date +%x_%T): Estimation of DTI model using dtifit on data in $FOLDER folder is done.${normal}"	
}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
# Function which is called for estimation of DTI model using dtifit
metricextract_function()
{
	DATA=$1
	FOLDER=$2

	echo "${yellow}$(date +%x_%T): Starting extraction of level-specific metrics using sct_extract_metric on data in $FOLDER folder.${normal}"
	
	for CN in FA MD AD RD;do
		sct_extract_metric -i $DATA/$FOLDER/dMRI/dti_${CN}.nii.gz -f $DATA/$FOLDER/dwi_mean_seg.nii.gz -vert 1:7 -vertfile $DATA/$FOLDER/dwi_mean_seg_labeled.nii.gz -perlevel 1 -append 0 -method wa -o $SAVEFOLDER/${SUB}_${CN}_level-specific_${FOLDER}.csv
	done
	
	echo "${yellow}$(date +%x_%T): Extraction of level-specific metrics using sct_extract_metric on data in $FOLDER folder is done.${normal}"	
}
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------

if [ $# -eq 0 ] || [ $1 == "-h" ];then
    print_help
else	
    main
fi
