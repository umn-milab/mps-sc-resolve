function umc_axial_labeling(label_filename,mask_filename,save_filename)
axial_mask = load_untouch_nii(mask_filename);
sagital_label = load_untouch_nii(label_filename);
axial_label = zeros(size(axial_mask.img));
for sl = 1:size(axial_mask.img,3)
        mask_sl = axial_mask.img(:,:,sl);
        mask_sum = sum(mask_sl(:));
        label_sl = sagital_label.img(:,:,sl);
        label_sum = sum(label_sl(:));      
        if label_sum > 0 &&  mask_sum > 0
                label = median(label_sl(label_sl>0));
                mask_sl(mask_sl==1) = label;
                axial_label(:,:,sl) = mask_sl;
        end
end
axial_mask.img = axial_label;
save_untouch_nii(axial_mask,save_filename);