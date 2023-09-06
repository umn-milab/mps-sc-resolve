function fill_holes( image )
%-------------------------------------------------------------------------------
% HELP is still missing!
%
% Proposed by Jan Valosek and Rene Labounek, 19th September 2018
% emails: jan.valosek@fnol.cz, rene.labounek@gmail.com
%-------------------------------------------------------------------------------


%  cd /md2/NA-CSD/1998B/Anat/BiasCorrection_test
%  image = '1998B_03s_t2_me2d_tra_p2_thr_bin';
% 
%  gunzip([image '.nii.gz'])

% if image=='T2TRA_thr_bin'
    
    T2TRA_bin = load_untouch_nii([image '.nii']);
    %imshow4(T2TRA_bin.img);

    for i=1:size(T2TRA_bin.img,3)
        T2TRA_bin_fill(:,:,i) = imfill(T2TRA_bin.img(:,:,i),'holes');
    end

    % for k=1:size(T2TRA_bin.img,3)
    %     T2TRA_slice_area(k,1) = regionprops(T2TRA_bin.img(:,:,k),'Area');
    % end

    for i=1:size(T2TRA_bin.img,3)
        T2TRA_bin_fill_remove(:,:,i) = bwareaopen(T2TRA_bin_fill(:,:,i),23000);
    end

    % imshow4(T2TRA_bin_fill_remove);

    T2TRA_bin.img = T2TRA_bin_fill_remove;
    out=[image '_fill.nii'];
    save_untouch_nii(T2TRA_bin,out);

% elseif image=='T2SAG_thr_bin'
%     
%     T2SAG_bin = load_untouch_nii([image '.nii']);
%     %imshow4(T2SAG_bin.img);
% 
%     for i=1:size(T2SAG_bin.img,3)
%         T2SAG_bin_fill(:,:,i) = imfill(T2SAG_bin.img(:,:,i),'holes');
%     end
% 
%     % for k=1:size(T2SAG_bin.img,3)
%     %     T2SAG_slice_area(k,1) = regionprops(T2SAG_bin.img(:,:,k),'Area');
%     % end
% 
%     for i=1:size(T2SAG_bin.img,3)
%         T2SAG_bin_fill_remove(:,:,i) = bwareaopen(T2SAG_bin_fill(:,:,i),30000);
%     end
% 
%     % imshow4(T2SAG_bin_fill_remove);
% 
%     T2SAG_bin.img = T2SAG_bin_fill_remove;
%     out=[image '_fill.nii'];
%     save_untouch_nii(T2SAG_bin,out);
%     
% end

end

