clear all; clc; close all;
% save('data_mps_for_thierry.mat','data_mps','data_hc','data_names','pss_mps','grp_mps','age_hc','age_mps','height_hc','height_mps','weight_hc','weight_mps','sex_hc','sex_mps','mri_corr','mri_corr_names')
data_folder='/home/range1-raid1/labounek/data-on-porto';
project_folder=fullfile(data_folder,'MPS','cspine_resolve');


xls_file = fullfile(project_folder,'results','cspine_resolve.xlsx');
save_path = fullfile(project_folder,'pictures','graphs-20241113-mps1041');
pvaladjust_file = fullfile(project_folder,'results','pvaladjust-20241113.mat');

% xls_file = fullfile(project_folder,'results','cspine_resolve_all_matched.xlsx');
% save_path = fullfile(project_folder,'pictures','graphs-20241001_all_matched');
% pvaladjust_file = fullfile(project_folder,'results','pvaladjust-20241001_all_matched.mat');

dmripreproc='topup-eddy';
roidefinition='level-specific';

% addpath('/home/range1-raid1/labounek/toolbox/matlab/spm12');

graph_specific_sub = 1;
show_sub = '2MPS1041';

clr_hc = [0 0.749 1];
clr_mpsi = [1 1 1]*0.4;
clr_mpsvi = [255 0 0]/255;
clr_stats = [0 220 0]/255;

xmin = -0.5;
xmax = 4.5;


% agethr_HS = 19.5;
% agethr_HS = 14.8;
agethr_HS = 16.5;
% agethr_S1 = 6.9;
agethr_S1 = 7.5;
agethr_S2 = 15.5;

% axismat = [xmin xmax 20 100
%     xmin xmax 4 10
%     xmin xmax 6 16
%     xmin xmax 0.5 1
%     xmin xmax 0.92 1
%     xmin xmax 0.25 0.75
%     xmin xmax 0.3 1.5
%     xmin xmax 0.2 1.2
%     xmin xmax 1 2.3];

axismat = [xmin xmax 20 100
    xmin xmax 4 10
    xmin xmax 6 16
    xmin xmax 0.25 0.75
    xmin xmax 1.3 2.3
    xmin xmax 0.45 1.15
    xmin xmax 0.8 1.5
    ];

if graph_specific_sub ~= 1
    axismat_err = [xmin xmax 40 100
        xmin xmax 5 10
        xmin xmax 8 16
        xmin xmax 0.35 0.75
        xmin xmax 1.4 2.1
        xmin xmax 0.5 1.0
        xmin xmax 0.9 1.3
        ];
else
    axismat_err = [xmin xmax 40 100
        xmin xmax 5 10
        xmin xmax 8 16
        xmin xmax 0.35 0.75
        xmin xmax 1.4 2.1
        xmin xmax 0.45 1.0
        xmin xmax 0.85 1.3
        ];
end

g_ylbl = {
    'CSA [mm^2]'
    'd_{AP} [mm]'
    'd_{RL} [mm]'
    'FA'
    'AD [*10^{-9}m^2/s]' % [*10^{-9}m^2/s]
    'RD [*10^{-9}m^2/s]'
    'MD [*10^{-9}m^2/s]'
    };

load(pvaladjust_file)
[num, txt, raw] = xlsread(xls_file);

nsess=size(raw,1)-2;
nlevels = 7;

% morpho_pos = [6 12 14 16 20];
% morpho_level_pos = 5;
% morpho_metrics = {'CSA' 'AP-diameter' 'RL-dimaeter' 'ecentricity' 'solidity'};

morpho_pos = [6 12 14];
morpho_level_pos = 5;
morpho_metrics = {'CSA' 'AP-diameter' 'RL-diameter'};


dmri_pos = 8;
dmri_level_pos = 5;
dmri_metrics = {'FA' 'AD' 'RD' 'MD'};

measurement_ind = [11 16 17 19 18 12 13 14 15];
measurement = cell2mat(raw(3:end,measurement_ind));
measurement_names = raw(1,measurement_ind);

sex=raw(3:end,3);
pss = [raw{3:end,5}]';
height = [raw{3:end,8}]';
weight = [raw{3:end,9}]';
age = [raw{3:end,10}]';


match_id = [raw{3:end,6}]';
match_visit = [raw{3:end,7}]';
% match_submax = max(match_id);
% match_hcmax = match_submax-2;
match_submax = 20;
match_hcmax = 19;

mpsi_type = raw(3:end,20);
transplant = raw(3:end,21);
donor = raw(3:end,22);
ageT = [raw{3:end,23}]';
mutation = raw(3:end,24);
mutation_sev = raw(3:end,25);


data_names= [morpho_metrics dmri_metrics];

sessid=cell(1,1);
subid=cell(1,1);
visit=zeros(nsess,1);

% morpho = zeros(nsess,nlevels,size(morpho_pos,2));
% dmri = zeros(nsess,nlevels,size(dmri_metrics,2));
data = zeros(nsess,nlevels,size(morpho_pos,2)+size(dmri_metrics,2));

for ind = 1:nsess
    sessid{ind,1} = raw{ind+2,1};
    visit(ind,1) = str2double(sessid{ind,1}(end));
    grp(ind,1) = raw{ind+2,4};
    if raw{ind+2,4}==-1
        project_folder=fullfile(data_folder,'controls','cspine_resolve');
        subid{ind,1}=sessid{ind,1}(16:19);
    else
        project_folder=fullfile(data_folder,'MPS','cspine_resolve');
        subid{ind,1}=sessid{ind,1}(16:23);
    end
    
    
    morpho_file = fullfile(project_folder,'results','tables',[sessid{ind,1} '_t2tra.csv']);  
    vls = ones(nlevels,size(morpho_pos,2))*NaN;
    if isfile(morpho_file)
        T = readtable(morpho_file,'PreserveVariableNames',1);
        for level = 1:nlevels
%             tmp = T{T{:,morpho_level_pos}==level,morpho_pos};
            tmp = T{T{:,morpho_level_pos}==level,{'MEAN(area)' 'MEAN(diameter_AP)' 'MEAN(diameter_RL)'}};
            if ~isempty(tmp)
                if iscell(tmp)
                    tmp=str2double(tmp);
                end
                if tmp(1,1)<20
                    tmp(1,1) = NaN;
                end
                if tmp(1,2)<2
                    tmp(1,2) = NaN;
                end
                if tmp(1,3)<2
                    tmp(1,2) = NaN;
                end
                vls(level,:) = tmp;
            end
        end
    end
%     vls = reshape(vls,1,size(vls,1)*size(vls,2));
    data(ind,:,1:size(morpho_pos,2)) = vls;
    
    for dmriid = 1:size(dmri_metrics,2)
        dmri_file = fullfile(project_folder,'results','tables',[sessid{ind,1} '_' dmri_metrics{1,dmriid} '_' roidefinition '_' dmripreproc '.csv']);
        vls = ones(1,nlevels)*NaN;
%         if strcmp(sessid{ind,1},'20161003-ST001-2MPS1047-1')
%             disp('Check')
%         end
        if isfile(dmri_file) && ~strcmp(sessid{ind,1},'20170926-ST001-2MPS1037-2')
            T = readtable(dmri_file,'PreserveVariableNames',1);
            for level = 1:nlevels
                tmp = T{T{:,dmri_level_pos}==level,'WA()'};
                if ~isempty(tmp)
                    if iscell(tmp)
                        tmp=str2double(tmp);
                    end
                    if strcmp(dmri_metrics{1,dmriid},'MD') || strcmp(dmri_metrics{1,dmriid},'RD') || strcmp(dmri_metrics{1,dmriid},'AD')
                        tmp = tmp*10^3;
                    end
                    if (level==4 && strcmp(sessid{ind,1},'20161003-ST001-2MPS1047-1')) || ...
                            (level<=3 && strcmp(sessid{ind,1},'20180419-ST001-2MPS1051-3')) || ...
                            (level==4 && strcmp(sessid{ind,1},'20190416-ST001-2MPS1022-3'))
                        vls(1,level) = NaN;
                    else
                        vls(1,level) = tmp;
                    end
                end
            end
        end
        vls(vls==0) = NaN;
        data(ind,:,size(morpho_pos,2)+dmriid) = vls;
    end
end

visit_num=max(match_visit)+1;
data_mps = NaN*ones(match_submax,visit_num,size(data,2),size(data,3));
data_hc = NaN*ones(match_hcmax,visit_num,size(data,2),size(data,3));
pss_mps = NaN*ones(match_submax,visit_num);
age_mps = NaN*ones(match_submax,visit_num);
age_hc = NaN*ones(match_hcmax,visit_num);
height_mps = NaN*ones(match_submax,visit_num);
height_hc = NaN*ones(match_hcmax,visit_num);
weight_mps = NaN*ones(match_submax,visit_num);
weight_hc = NaN*ones(match_hcmax,visit_num);
grp_mps = NaN*ones(match_submax,1);
sessid_mps = cell(match_submax,visit_num);
sessid_hc = cell(match_hcmax,visit_num);
subid_mps = cell(match_submax,1);
subid_hc = cell(match_hcmax,1);
sex_mps = cell(match_submax,1);
sex_hc = cell(match_hcmax,1);
measurement_mps = NaN*ones(match_submax,visit_num,size(measurement,2));
measurement_hc = NaN*ones(match_hcmax,visit_num,size(measurement,2));
ageT_mps = NaN*ones(match_submax,1);
donor_mps = cell(match_submax,1);
transplant_mps = cell(match_submax,1);
mpsitype_mps = cell(match_submax,1);
mutation_mps = cell(match_submax,1);
mutation_sev_mps = cell(match_submax,1);
for ind = 1:match_submax
    for vst = 0:max(match_visit)
        mps_pos = match_id==ind & match_visit==vst & grp>=0;
%         hc_pos = match_id==ind & match_visit==vst & grp<0; % 2024113 RL uncomment when the last HC matched to the MPS01 is acquired
        hc_pos = match_id==ind+1 & match_visit==vst & grp<0; % 2024113 RL delete when the last HC matched to the MPS01 is acquired
        if sum(mps_pos)==1
            data_mps(ind,vst+1,:,:) = data(mps_pos,:,:);
            measurement_mps(ind,vst+1,:) = measurement(mps_pos,:);
            pss_mps(ind,vst+1) = pss(mps_pos);
            age_mps(ind,vst+1) = age(mps_pos);
            height_mps(ind,vst+1) = height(mps_pos);
            weight_mps(ind,vst+1) = weight(mps_pos);
            sessid_mps{ind,vst+1} = sessid{mps_pos,1};
        end
        if sum(hc_pos)==1 %% && ind <= match_hcmax
            data_hc(ind,vst+1,:,:) = data(hc_pos,:,:);
            measurement_hc(ind,vst+1,:) = measurement(hc_pos,:);
            age_hc(ind,vst+1) = age(hc_pos);
            height_hc(ind,vst+1) = height(hc_pos);
            weight_hc(ind,vst+1) = weight(hc_pos);
            sessid_hc{ind,vst+1} = sessid{hc_pos,1};
        end
        if vst == 1
            subid_mps{ind,1} = subid{mps_pos,1};
            sex_mps{ind,1} = sex{mps_pos,1};
            grp_mps(ind,1) = grp(mps_pos,1);
            ageT_mps(ind,1) = ageT(mps_pos,1);
            donor_mps{ind,1} = donor{mps_pos,1};
            transplant_mps{ind,1} = transplant{mps_pos,1};
            mpsitype_mps{ind,1} = mpsi_type{mps_pos,1};
            mutation_mps{ind,1} = mutation{mps_pos,1};
            mutation_sev_mps{ind,1} = mutation_sev{mps_pos,1};
            if ind <= match_hcmax
                subid_hc{ind,1} = subid{hc_pos,1};
                sex_hc{ind,1} = sex{hc_pos,1};
            end
        end
    end
end
sessis_all = [sessid_mps; sessid_hc];

bmi_mps = weight_mps ./ (height_mps/100).^2;
bmi_hc = weight_hc ./ (height_hc/100).^2;

subject = repmat((1:size(data_mps,1))',1,size(data_mps,2));

[tmp, p_tmp] = corrcoef(ageT_mps,age_mps(:,2),'Rows','Pairwise');
r_ageXageT_v2 = tmp(1,2);
p_r_ageXageT_v2 = p_tmp(1,2);

for level = 1:size(data_mps,3)
    for vr = 1:size(data_mps,4)
        xdata = data_mps(:,:,level,vr);
        
        [r_pss(level,vr), p_r_pss(level,vr)] = corr(xdata(:),pss_mps(:),'Type','Spearman','Rows','Pairwise');
%         [r_pss_v2(level,vr), p_r_pss_v2(level,vr)] = corr(xdata(:,2),pss_mps(:,2),'Type','Spearman','Rows','Pairwise');
        
        [tmp, p_tmp] = corrcoef(xdata(:,2),pss_mps(:,2),'Rows','Pairwise');
        r_pss_v2(level,vr) = tmp(1,2);
        p_r_pss_v2(level,vr) = p_tmp(1,2);
        
        [tmp, p_tmp] = corrcoef(xdata(:,2),age_mps(:,2),'Rows','Pairwise');
        r_age_v2(level,vr) = tmp(1,2);
        p_r_age_v2(level,vr) = p_tmp(1,2);
        
        [tmp, p_tmp] = corrcoef(xdata(:,2),bmi_mps(:,2),'Rows','Pairwise');
        r_bmi_v2(level,vr) = tmp(1,2);
        p_r_bmi_v2(level,vr) = p_tmp(1,2);
        
        [tmp, p_tmp] = corrcoef(xdata(:,2),height_mps(:,2),'Rows','Pairwise');
        r_height_v2(level,vr) = tmp(1,2);
        p_r_height_v2(level,vr) = p_tmp(1,2);
        
        [tmp, p_tmp] = corrcoef(xdata(:,2),weight_mps(:,2),'Rows','Pairwise');
        r_weight_v2(level,vr) = tmp(1,2);
        p_r_weight_v2(level,vr) = p_tmp(1,2);
        
        [rho_transpl_v2(level,vr), p_rho_transpl_v2(level,vr)] = corr(xdata(:,2),ageT_mps,'Rows','Pairwise','Type','Spearman');
        
        [tmp, p_tmp] = corrcoef(xdata(:,2),ageT_mps,'Rows','Pairwise');
        r_transpl_v2(level,vr) = tmp(1,2);
        p_r_transpl_v2(level,vr) = p_tmp(1,2);
        
        p_tmp = anovan(xdata(:,2),{ageT_mps,age_mps(:,2)},'Continuous',[1 2],'varnames',{'AgeT','Age'},'display','off');
        pANCOVA_ageT_v2(level,vr)= p_tmp(1);
        
        p_tmp = anovan(xdata(:,2),{height_mps(:,2),age_mps(:,2)},'Continuous',[1 2],'varnames',{'Height','Age'},'display','off');
        pANCOVA_height_v2(level,vr)= p_tmp(1);
        
%         p_tmp = anovan(xdata(:,2),{pss_mps(:,2),age_mps(:,2) },'Continuous',2,'varnames',{'PSS','Age'},'display','off');
        p_tmp = anovan(xdata(:,2),{pss_mps(:,2),age_mps(:,2) , height_mps(:,2) },'Continuous',[2 3],'varnames',{'PSS','Age','Height'},'display','off');
        pANCOVA_pss_v2(level,vr)= p_tmp(1);
        
%         p_tmp = anovan(xdata(:),{pss_mps(:),age_mps(:) },'Continuous',2,'varnames',{'PSS','Age'},'display','off');
        p_tmp = anovan(xdata(:),{pss_mps(:),age_mps(:),height_mps(:) },'Continuous',[2 3],'varnames',{'PSS','Age','Height'},'display','off');
%         p_tmp = anovan(xdata(:),{pss_mps(:),age_mps(:),height_mps(:), subject(:) },'Continuous',[2 3],'varnames',{'PSS','Age','Height', 'Subject'},'display','off');
        pANCOVA_pss(level,vr)= p_tmp(1);
        
        xdata_name = [ 'C' num2str(level) '-' data_names{1,vr} ];
        
        mdl_ageT_v2{level,vr} = fitlm([ ageT_mps age_mps(:,2) ],xdata(:,2),'VarNames',{'ageT','age',xdata_name});
        mdl_ageT_v2_R2(level,vr) = mdl_ageT_v2{level,vr}.Rsquared.Ordinary;
        
%         mdl_v2{level,vr} = fitlm([ pss_mps(:,2) age_mps(:,2) height_mps(:,2) ],xdata(:,2));
%         mdl_v2_R2(level,vr) = mdl_v2{level,vr}.Rsquared.Ordinary;
%         mdl{level,vr} = fitlm([ pss_mps(:) age_mps(:) height_mps(:) ],xdata(:));
%         mdl_R2(level,vr) = mdl{level,vr}.Rsquared.Ordinary;
        
    end
end


for vr = 1:size(measurement_mps,3)
    xdata = measurement_mps(:,:,vr);
    
    [rho_measurement_transpl_v2(1,vr), p_rho_measurement_transpl_v2(1,vr)] = corr(xdata(:,2),ageT_mps,'Rows','Pairwise','Type','Spearman');
    
    [tmp, p_tmp] = corrcoef(xdata(:,2),ageT_mps,'Rows','Pairwise');
    r_measurement_transpl_v2(1,vr) = tmp(1,2);
    p_r_measurement_transpl_v2(1,vr) = p_tmp(1,2);
    
    [tmp, p_tmp] = corrcoef(xdata(:,2),height_mps(:,2),'Rows','Pairwise');
    r_measurement_height_v2(1,vr) = tmp(1,2);
    p_r_measurement_height_v2(1,vr) = p_tmp(1,2);
    
    p_tmp = anovan(xdata(:,2),{height_mps(:,2),age_mps(:,2)},'Continuous',[1 2],'varnames',{'Height','Age'},'display','off');
    pANCOVA_measurement_height_v2(1,vr)= p_tmp(1);
end

data_mps_array = [pss_mps; NaN*ones(size(data_hc,1),size(pss_mps,2))];
data_mps_array_names = {'PSS-t0' 'PSS-t1' 'PSS-t2' 'PSS-t3' 'PSS-t4'};
for vr = 1:size(data_mps,4)
    for level = 1:size(data_mps,3)
       data_mps_array = [data_mps_array [ data_mps(:,:,level,vr); data_hc(:,:,level,vr) ] ];
       data_mps_array_names(end+1:end+5) = {
           [data_names{1,vr} '-C' num2str(level) '-t0']
           [data_names{1,vr} '-C' num2str(level) '-t1']
           [data_names{1,vr} '-C' num2str(level) '-t2']
           [data_names{1,vr} '-C' num2str(level) '-t3']
           [data_names{1,vr} '-C' num2str(level) '-t4']
           };
    end
end


tbl=cell(1,1);
for idx = 1:size(data_names,2)
    tbl{1,3+5*(idx-1)} = data_names(1,idx);
    tbl{2,3+5*(idx-1)} = 'Mean';
    tbl{2,4+5*(idx-1)} = 'STD';
    tbl{2,5+5*(idx-1)} = 'pBH / diff';
    tbl{2,6+5*(idx-1)} = 'pAW';
    tbl{2,7+5*(idx-1)} = 'pAH';
end

for idx = 1:nlevels
    tbl{3+2*(idx-1),1} = data_names{1,idx};
    tbl{3+2*(idx-1),1} = ['C' num2str(idx)];
    tbl{3+2*(idx-1),2} = 'Control';
    tbl{4+2*(idx-1),2} = 'MPS';
end

grp_ancova = [ones(size(data_mps,1),1); zeros(size(data_hc,1),1)];
weight_ancova = [weight_mps(:,2); weight_hc(:,2)];
height_ancova = [height_mps(:,2); height_hc(:,2)];
age_ancova = [age_mps(:,2); age_hc(:,2)];
female_ancova = [strcmp(sex_mps,'F'); strcmp(sex_hc,'F')];
matching_ancova = [1:size(data_mps,1) 1:size(data_hc,1)]';

time=0.6:0.933333333333:3.6+0.933333333333;
mri_corr = zeros(size(data_mps,1)+size(data_hc,1),size(data,3)*nlevels);
mri_corr_names = cell(1,1);
mriind=1;
h = struct([]);
for varind = 1:size(data_mps,4)
    h(varind).fig = figure(varind);
    set(h(varind).fig,'Position',[1050 50 900 1200])
    
    for level = 1:nlevels
        y = data_mps(:,2,level,varind);
        y_all = squeeze(data_mps(:,:,level,varind));
        yhc = data_hc(:,2,level,varind);
        
        yhc(yhc==0) = NaN;
        y(y==0) = NaN;
        
        yhc_mean = mean(yhc,'omitnan');
        yhc_std = std(yhc,0,'omitnan');
        
        y_mean = mean(y,'omitnan');
        y_std = std(y,0,'omitnan');
        
        [~, pT(level,varind)]=ttest2(y,yhc);
        pW(level,varind)=ranksum(y,yhc);
        
        
        [~, pT_HS(level,varind)]=ttest2(  y(strcmp(mpsitype_mps,'HS'))  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ) );
        [~, pT_VI(level,varind)]=ttest2(  y(grp_mps==6)  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ) );
        [~, pT_S(level,varind)]=ttest2(  y(strcmp(mpsitype_mps,'S'))  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_S1 & age_mps(:,2) < agethr_S2 ) );
        
        pW_HS(level,varind)=ranksum(  y(strcmp(mpsitype_mps,'HS'))  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ) );
        pW_VI(level,varind)=ranksum(  y(grp_mps==6)  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ) );
        pW_S(level,varind)=ranksum(  y(strcmp(mpsitype_mps,'S'))  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_S1 & age_mps(:,2) < agethr_S2 ) );
        
        p_tmp = anovan([y; yhc],{grp_ancova,weight_ancova},'Continuous',2,'varnames',{'Group','Weight'},'display','off');
%         p_tmp = anovan([y; yhc],{grp_ancova,weight_ancova,female_ancova},'Continuous',2,'varnames',{'Group','Weight','Sex'},'display','off');
%         p_tmp = anovan([y; yhc],{grp_ancova,weight_ancova,age_ancova},'Continuous',[2 3],'varnames',{'Group','Weight','Age'},'display','off');
%         p_tmp = anovan([y; yhc],{grp_ancova,weight_ancova,female_ancova,age_ancova},'Continuous',[2 4],'varnames',{'Group','Weight','Sex','Age'},'display','off');
        pANCOVA_weight(level,varind)= p_tmp(1);
        p_tmp = anovan([y; yhc],{grp_ancova,height_ancova},'Continuous',2,'varnames',{'Group','Height'},'display','off');
%         p_tmp = anovan([y; yhc],{grp_ancova,height_ancova,female_ancova},'Continuous',2,'varnames',{'Group','Height','Sex'},'display','off');
%         p_tmp = anovan([y; yhc],{grp_ancova,height_ancova,age_ancova},'Continuous',[2 3],'varnames',{'Group','Height','Age'},'display','off');
%         p_tmp = anovan([y; yhc],{grp_ancova,height_ancova,female_ancova,age_ancova},'Continuous',[2 4],'varnames',{'Group','Height','Sex','Age'},'display','off');
        pANCOVA_height(level,varind)= p_tmp(1);
%         p_tmp = anovan([y; yhc],{grp_ancova,female_ancova,female_ancova},'Continuous',2,'varnames',{'Group','confounder'},'display','off');
%         pANCOVA_sex(level,varind)= p_tmp(1);
        [~, pT_sexHC(level,varind)]=ttest2(yhc(strcmp(sex_hc,'F')),yhc(~strcmp(sex_hc,'F')));
        [~, pT_sex(level,varind)]=ttest2(y(strcmp(sex_mps,'F')),y(~strcmp(sex_mps,'F')));
        
        mri_corr(:,mriind) = [y; yhc];
        mri_corr_names{1,mriind} = ['C' num2str(level) '-' data_names{1,varind}];
        mriind = mriind + 1;
        
        tbl{3+2*(level-1),3+5*(varind-1)} = yhc_mean;
        tbl{3+2*(level-1),4+5*(varind-1)} = yhc_std;
        tbl{3+2*(level-1),5+5*(varind-1)} = pTadj(level,varind);
        tbl{3+2*(level-1),6+5*(varind-1)} = pANCOVA_weight(level,varind);
        tbl{3+2*(level-1),7+5*(varind-1)} = pANCOVA_height(level,varind);
        tbl{4+2*(level-1),3+5*(varind-1)} = y_mean;
        tbl{4+2*(level-1),4+5*(varind-1)} = y_std;   
        if tbl{3+2*(level-1),5+5*(varind-1)} < 0.05
            tmp = 100 * (tbl{4+2*(level-1),3+5*(varind-1)} - tbl{3+2*(level-1),3+5*(varind-1)}) / tbl{3+2*(level-1),3+5*(varind-1)};
            if tmp < 0
                tbl{4+2*(level-1),5+5*(varind-1)} = [num2str(tmp,'%.2f') '%'];
            else
                tbl{4+2*(level-1),5+5*(varind-1)} = ['+' num2str(tmp,'%.2f') '%'];
            end
        end
        
        subplot(4,2,level)
        plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',clr_stats,'LineWidth',5)
        hold on
        plot([-0.4 0.4],[yhc_mean-yhc_std yhc_mean-yhc_std],'-.','Color',clr_stats,'LineWidth',3)
        plot([-0.4 0.4],[yhc_mean+yhc_std yhc_mean+yhc_std],'-.','Color',clr_stats,'LineWidth',3)
        plot([1.13333333 1.93333333],[y_mean y_mean],'Color',clr_stats,'LineWidth',5)
        plot([1.13333333 1.93333333],[y_mean-y_std y_mean-y_std],'-.','Color',clr_stats,'LineWidth',3)
        plot([1.13333333 1.93333333],[y_mean+y_std y_mean+y_std],'-.','Color',clr_stats,'LineWidth',3)
        scatter(zeros(size(yhc)),yhc,100,'v','MarkerEdgeColor',clr_hc,'LineWidth',3, 'jitter','on', 'jitterAmount', 0.14,'MarkerEdgeAlpha',0.7)
        for ps = 1:size(y,1)
            if grp_mps(ps) == 0 || grp_mps(ps) == 1
                if strcmp(mpsitype_mps{ps,1},'H')
                    mrk = ':^';
                elseif strcmp(mpsitype_mps{ps,1},'HS')
                    mrk = ':o';
                elseif strcmp(mpsitype_mps{ps,1},'S')
                    mrk = ':d';
                end
                clr = clr_mpsi;
            elseif grp_mps(ps) == 6
                mrk = ':x';
                clr = clr_mpsvi;
            end
            tm = time + [0 randn(1,1)*0.105 0 0 0];
            plot(tm(~isnan(y_all(ps,:))),y_all(ps,~isnan(y_all(ps,:))),mrk,'Color',clr,'LineWidth',3,'MarkerSize',9)
        end
        
        if pTadj(level,varind) < 0.05
            plot(1.2,axismat(varind,4)-0.15*(axismat(varind,4)-axismat(varind,3)),'k+','MarkerSize',11,'LineWidth',3)
            if pANCOVA_weight(level,varind) < 0.05
                plot(1.47,axismat(varind,4)-0.15*(axismat(varind,4)-axismat(varind,3)),'k>','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
            if pANCOVA_height(level,varind) < 0.05
                plot(1.8,axismat(varind,4)-0.15*(axismat(varind,4)-axismat(varind,3)),'ks','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
%             if pANCOVA_sex(level,varind) < 0.05
%                 plot(2.15,axismat(varind,4)-0.15*(axismat(varind,4)-axismat(varind,3)),'kd','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
%             end
        end
        hold off
        axis(axismat(varind,:))
        ylabel(['C' num2str(level)])
        grid on
        if level <= nlevels-2
            set(gca,'FontSize',14,'LineWidth',2,'xtick',[0 1.533333333333333333],'xticklabel',{' ' ' '})
        else
            set(gca,'FontSize',14,'LineWidth',2,'xtick',[0 1.533333333333333333],'xticklabel',{'Control' 'MPS'})
        end
    end
    
    yy = squeeze(data_mps(:,2,:,varind));
    CC(:,:,varind) = squeeze(data_hc(age_hc(:,2) > agethr_HS,2,:,varind));
    CC_fS(:,:,varind) = squeeze(data_hc(age_hc(:,2) > agethr_S1 & age_hc(:,2) < agethr_S2,2,:,varind));
    
    yy_HS = yy(strcmp(mpsitype_mps,'HS'),:);
    yy_H = yy(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ,:);
    yy_VI = yy(grp_mps==6,:);
    yy_S = yy(strcmp(mpsitype_mps,'S'),:);
    yy_HfS = yy(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_S1 & age_mps(:,2) < agethr_S2,:);
    
    YY_HS(:,:,varind) = yy_HS;
    YY_H(:,:,varind) = yy_H;
    YY_VI(:,:,varind) = yy_VI;
    YY_S(:,:,varind) = yy_S;
    YY_HfS(:,:,varind) = yy_HfS;
    
    [~, pT_HS_agr(1,varind)]=ttest2(  yy_HS(:)  , yy_H(:) );
    [~, pT_VI_agr(1,varind)]=ttest2(  yy_VI(:)  , yy_H(:) );
    [~, pT_S_agr(1,varind)]=ttest2(  yy_S(:)  , yy_HfS(:) );
    
    pW_HS_agr(1,varind)=ranksum(  yy_HS(:)  , yy_H(:) );
    pW_VI_agr(1,varind)=ranksum(  yy_VI(:)  , yy_H(:) );
    pW_S_agr(1,varind)=ranksum(  yy_S(:)  , yy_HfS(:) );
    
    subplot(4,2,8)
    plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',clr_stats,'LineWidth',5)
    hold on
    plot([-0.4 0.4],[yhc_std yhc_std],'-.','Color',clr_stats,'LineWidth',3)
    plot(0,0,'v','Color',clr_hc,'LineWidth',3,'MarkerSize',13)
    plot([0.5 1.5],[0 0],':^','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
    plot([0.5 1.5],[0 0],':o','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
    plot([0.5 1.5],[0 0],':d','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
    plot([1.5 2.5],[0 0],':x','Color',clr_mpsvi,'LineWidth',3,'MarkerSize',13)
    plot(1,1,'+','Color','k','LineWidth',3,'MarkerSize',11)
    plot(1,1,'>','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
    plot(1,1,'s','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
%     plot(1,1,'d','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
    hold off
%     legend('Mean','± Standard deviation','Healthy control','MPS I','MPS VI','Two-sample t-test (p_{BH}<0.05)',...
%         'ANCOVA (Conf: Weight; p<0.05)','ANCOVA (Conf: Height; p<0.05)','ANCOVA (Conf: Sex; p<0.05)',...
%         'Location','northwest')
    legend('Mean','± Standard deviation','Healthy control','MPS I - Hurler syndrome','MPS I - Hurler-Scheie syndrome','MPS I - Scheie syndrome','MPS VI','Two-sample t-test (p_{BH}<0.05)',...
        'ANCOVA (Conf: Weight; p<0.05)','ANCOVA (Conf: Height; p<0.05)',...
        'Location','northwest')
    set(gca,'FontSize',14,'LineWidth',2)
    axis([-101 -100 -101 -100]);
    axis off
    
    print(fullfile(save_path,['graph' num2str(varind) '-' data_names{1,varind}]),'-dpng','-r300')
    pause(0.15)
    close(h(varind).fig)
    pause(0.1)
    disp(num2str(varind))
end
%% FDR correction - macro and microstructure
[~, ~, ~, pTadj]=fdr_bh(pT(:,1:3));
[~, ~, ~, pTadj(:,4:7)]=fdr_bh(pT(:,4:7));

[~, ~, ~, pWadj]=fdr_bh(pW(:,1:3));
[~, ~, ~, pWadj(:,4:7)]=fdr_bh(pW(:,4:7));
% save(pvaladjust_file,'pTadj','pWadj')
%% Demographics
demographics{1,2}='Control';
demographics{2,2}='Mean';
demographics{2,3}='STD';
demographics{1,4}='MPS';
demographics{2,4}='Mean';
demographics{2,5}='STD';
demographics{2,6}='p';
demographics{3,1}='Participants';
demographics{3,2}=size(data_hc,1);
demographics{3,4}=size(data_mps,1);
demographics{4,1}='Females';
demographics{4,2}=sum(strcmp(sex_hc,'F'));
demographics{4,4}=sum(strcmp(sex_mps,'F'));

demographics{5,1}='Age [y.o.]';
demographics{5,2}=mean(age_hc(:,2));
demographics{5,3}=std(age_hc(:,2));
demographics{5,4}=mean(age_mps(:,2));
demographics{5,5}=std(age_mps(:,2));
[~, demographics{5,6}] = ttest2(age_hc(:,2),age_mps(:,2));

demographics{6,1}='Height [cm]';
demographics{6,2}=mean(height_hc(:,2));
demographics{6,3}=std(height_hc(:,2));
demographics{6,4}=mean(height_mps(:,2));
demographics{6,5}=std(height_mps(:,2));
[~, demographics{6,6}] = ttest2(height_hc(:,2),height_mps(:,2));

demographics{7,1}='Weight [kg]';
demographics{7,2}=mean(weight_hc(:,2));
demographics{7,3}=std(weight_hc(:,2));
demographics{7,4}=mean(weight_mps(:,2));
demographics{7,5}=std(weight_mps(:,2));
[~, demographics{7,6}] = ttest2(weight_hc(:,2),weight_mps(:,2));
%% Cross-sectional graph
h(varind+1).fig = figure(varind+1);
set(h(varind+1).fig,'Position',[1050 40 1000 1300])

x_hc = repmat((1:size(pT,1))-0.25,size(sessid_hc,1),1);
x_mps = repmat((1:size(pT,1))+0.25,size(sessid_mps,1),1);
x_hc = x_hc(:);
x_mps = x_mps(:);
grp_mps_vec = repmat(grp_mps,1,size(pT,1));
grp_mps_vec = grp_mps_vec(:);
x_hc_stat = [
    0.55 0.95;
    1.55 1.95
    2.55 2.95
    3.55 3.95
    4.55 4.95
    5.55 5.95
    6.55 6.95];
x_mps_stat = x_hc_stat + 0.5;
for vr = 1:size(pT,2)
    g = mri_corr(:,7*(vr-1)+1:7*(vr-1)+7);
    g_mps = g(1:size(sessid_mps,1),:);
    g_hc = g(size(sessid_mps,1)+1:end,:);
    g_mps_mean = mean(g_mps,'omitnan');
    g_mps_std = std(g_mps,0,'omitnan');
    g_hc_mean = mean(g_hc,'omitnan');
    g_hc_std = std(g_hc,0,'omitnan');
    
    g_mps = g_mps(:);
    g_hc = g_hc(:);
    
    subplot(size(pT,2),1,vr)
    plot([1.5:6.5; 1.5:6.5],repmat(axismat(vr,[3 4]),size(pT,1)-1,1)','k','LineWidth',2)
    hold on
    plot(x_hc_stat',[g_hc_mean; g_hc_mean],'LineWidth',3,'Color',clr_stats)
    plot(x_hc_stat',[g_hc_mean - g_hc_std; g_hc_mean - g_hc_std],'-.','LineWidth',3,'Color',clr_stats)
    plot(x_hc_stat',[g_hc_mean + g_hc_std; g_hc_mean + g_hc_std],'-.','LineWidth',3,'Color',clr_stats)
    plot(x_mps_stat',[g_mps_mean; g_mps_mean],'LineWidth',3,'Color',clr_stats)
    plot(x_mps_stat',[g_mps_mean - g_mps_std; g_mps_mean - g_mps_std],'-.','LineWidth',3,'Color',clr_stats)
    plot(x_mps_stat',[g_mps_mean + g_mps_std; g_mps_mean + g_mps_std],'-.','LineWidth',3,'Color',clr_stats)
    scatter(x_hc,g_hc,80,'^','MarkerEdgeColor',clr_hc,'LineWidth',3, 'jitter','on', 'jitterAmount', 0.13,'MarkerEdgeAlpha',0.7)
    scatter(x_mps(grp_mps_vec == 0 | grp_mps_vec == 1),g_mps(grp_mps_vec == 0 | grp_mps_vec == 1),80,'o','MarkerEdgeColor',clr_mpsi,'LineWidth',3, 'jitter','on', 'jitterAmount', 0.13,'MarkerEdgeAlpha',0.7)
    scatter(x_mps(grp_mps_vec == 6),g_mps(grp_mps_vec == 6),80,'x','MarkerEdgeColor',clr_mpsvi,'LineWidth',3, 'jitter','on', 'jitterAmount', 0.13,'MarkerEdgeAlpha',0.7)
    for level = 1:size(pT,1)
        if pTadj(level,vr) < 0.05
            plot(mean([x_hc_stat(level,2) x_mps_stat(level,1)])-0.17,axismat(vr,4)-0.15*(axismat(vr,4)-axismat(vr,3)),'k+','MarkerSize',11,'LineWidth',3)
            if pANCOVA_weight(level,vr) < 0.05
                plot(mean([x_hc_stat(level,2) x_mps_stat(level,1)]),axismat(vr,4)-0.15*(axismat(vr,4)-axismat(vr,3)),'k>','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
            if pANCOVA_height(level,vr) < 0.05
                plot(mean([x_hc_stat(level,2) x_mps_stat(level,1)])+0.17,axismat(vr,4)-0.15*(axismat(vr,4)-axismat(vr,3)),'ks','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
        end
    end
    hold off
    grid on
    ylabel(g_ylbl{vr,1})
    if vr < size(pT,2)
        set(gca,'Fontsize',12,'LineWidth',2,'XTick',1:size(pT,1),'XTickLabel','')
    else
        xlabel('Cervical level')
        set(gca,'Fontsize',12,'LineWidth',2,'XTick',1:size(pT,1),'XTickLabel',{'C1' 'C2' 'C3' 'C4' 'C5' 'C6' 'C7'})
    end
    axis([x_hc(1)-0.25 x_mps(end)+0.25 axismat(vr,3) axismat(vr,4)])
end

print(fullfile(save_path,['graph' num2str(varind+1) '-crosssectional']),'-dpng','-r300')
pause(0.15)
close(h(varind+1).fig)
pause(0.1)
disp(num2str(varind+1))

%% Errorbar plot
h(varind+2).fig = figure(varind+2);
set(h(varind+2).fig,'Position',[1050 40 1500 1200])

x = 1:size(pT,1);

for vr = 1:size(pT,2)
    g = mri_corr(:,7*(vr-1)+1:7*(vr-1)+7);
    g_mps = g(1:size(sessid_mps,1),:);
    g_hc = g(size(sessid_mps,1)+1:end,:);
    g_mps_mean = mean(g_mps,'omitnan');
    g_mps_std = std(g_mps,0,'omitnan');
    g_hc_mean = mean(g_hc,'omitnan');
    g_hc_std = std(g_hc,0,'omitnan');
    
    if graph_specific_sub == 1
        g_showsub = g_mps(strcmp(subid_mps,show_sub),:);
    end

    subplot(4,2,vr)
    errorbar(x,g_hc_mean,g_hc_std,'b','LineWidth',4)
    hold on
    errorbar(x,g_mps_mean,g_mps_std,'r','LineWidth',3)
    
    for level = 1:size(pT,1)
        if pTadj(level,vr) < 0.05
            plot(x(level)-0.20,axismat_err(vr,4)-0.11*(axismat_err(vr,4)-axismat_err(vr,3)),'k+','MarkerSize',11,'LineWidth',3)
            if pANCOVA_weight(level,vr) < 0.05
                plot(x(level),axismat_err(vr,4)-0.11*(axismat_err(vr,4)-axismat_err(vr,3)),'k>','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
            if pANCOVA_height(level,vr) < 0.05
                plot(x(level)+0.25,axismat_err(vr,4)-0.11*(axismat_err(vr,4)-axismat_err(vr,3)),'ks','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
        end
    end
    
    if graph_specific_sub == 1
        plot(x,g_showsub,'--d','Color',clr_mpsi,'Linewidth',3,'MarkerSize',11)
    end
    
    hold off
    grid on
    ylabel(g_ylbl{vr,1})
    if vr < size(pT,2)-1
        set(gca,'Fontsize',12,'LineWidth',2,'XTick',1:size(pT,1),'XTickLabel','')
    else
        xlabel('Cervical level')
        set(gca,'Fontsize',12,'LineWidth',2,'XTick',1:size(pT,1),'XTickLabel',{'C1' 'C2' 'C3' 'C4' 'C5' 'C6' 'C7'})
    end
    axis([x(1)-0.5 x(end)+0.5 axismat_err(vr,3) axismat_err(vr,4)])
end

subplot(4,2,8)
plot([-0.4 0.4],[yhc_mean yhc_mean],'b','LineWidth',4)
hold on
plot([-0.4 0.4],[yhc_std yhc_std],'r','LineWidth',3)
plot(1,1,'+','Color','k','LineWidth',3,'MarkerSize',11)
plot(1,1,'>','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
plot(1,1,'s','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
if graph_specific_sub == 1
    plot(1,1,'--d','Color',clr_mpsi,'LineWidth',3,'MarkerSize',11)
end
hold off
if graph_specific_sub ~= 1
    legend('Healthy controls','MPS I and VI patients','Two-sample t-test (p_{BH}<0.05)',...
        'ANCOVA (Conf: Weight; p<0.05)','ANCOVA (Conf: Height; p<0.05)',...
        'Location','northwest')
else
    legend('Healthy controls','MPS I and VI patients','Two-sample t-test (p_{BH}<0.05)',...
        'ANCOVA (Conf: Weight; p<0.05)','ANCOVA (Conf: Height; p<0.05)',...
        show_sub(2:end),...
        'Location','northwest')
end
set(gca,'FontSize',14,'LineWidth',2)
axis([-101 -100 -101 -100]);
axis off

print(fullfile(save_path,['graph' num2str(varind+2) '-crosssectional-errorbar']),'-dpng','-r300')
pause(0.15)
close(h(varind+2).fig)
pause(0.1)
disp(num2str(varind+2))

%% Spearman correlation plot

h(varind+3).fig = figure(varind+3);
set(h(varind+3).fig,'Position',[1000 40 2000 350])

xdata=pss_mps(:,2);
xx = [min(xdata) max(xdata)];

% lvl=6;vr=3;
lvl=3;vr=5;
ydata=data_mps(:,2,lvl,vr);
q = polyfit(xdata(~isnan(xdata+ydata)),ydata(~isnan(xdata+ydata)),1);
yy = q(1).*xx + q(2);
subplot(1,4,1)
plot(xx,yy,'k-.','LineWidth',3)
hold on
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),'o','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),'d','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps==6,1),ydata(grp_mps==6,1),'rx','MarkerSize',14,'LineWidth',4)
text(0.99*xx(2),0.98*max(ydata),['\rho=' num2str(r_pss_v2(lvl,vr),'%.3f') '; p=' num2str(p_r_pss_v2(lvl,vr),'%.3f') ],'HorizontalAlign','right','FontSize',14)
text(0.99*xx(2),0.95*max(ydata),['p_{A|Age}=' num2str(pANCOVA_pss_v2(lvl,vr),'%.3f') ],'HorizontalAlign','right','FontSize',14)
hold off
ylabel(['C' num2str(lvl) ' ' g_ylbl{vr,1}])
xlabel('Physical Symptom Score')
axis([xx min(ydata) max(ydata)])
grid on
set(gca,'FontSize',14,'LineWidth',2)

lvl=4;vr=5;
ydata=data_mps(:,2,lvl,vr);
q = polyfit(xdata(~isnan(xdata+ydata)),ydata(~isnan(xdata+ydata)),1);
yy = q(1).*xx + q(2);
subplot(1,4,2)
plot(xx,yy,'k-.','LineWidth',3)
hold on
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),'o','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),'d','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps==6,1),ydata(grp_mps==6,1),'rx','MarkerSize',14,'LineWidth',4)
text(0.99*xx(2),0.98*max(ydata),['\rho=' num2str(r_pss_v2(lvl,vr),'%.3f') '; p=' num2str(p_r_pss_v2(lvl,vr),'%.3f') ],'HorizontalAlign','right','FontSize',14)
text(0.99*xx(2),0.96*max(ydata),['p_{A|Age}=' num2str(pANCOVA_pss_v2(lvl,vr),'%.3f') ],'HorizontalAlign','right','FontSize',14)
hold off
ylabel(['C' num2str(lvl) ' ' g_ylbl{vr,1}])
xlabel('Physical Symptom Score')
axis([xx min(ydata) max(ydata)])
grid on
set(gca,'FontSize',14,'LineWidth',2)

lvl=4;vr=7;
ydata=data_mps(:,2,lvl,vr);
q = polyfit(xdata(~isnan(xdata+ydata)),ydata(~isnan(xdata+ydata)),1);
yy = q(1).*xx + q(2);
subplot(1,4,3)
plot(xx,yy,'k-.','LineWidth',3)
hold on
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),'o','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),'d','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
plot(xdata(grp_mps==6,1),ydata(grp_mps==6,1),'rx','MarkerSize',14,'LineWidth',4)
text(0.99*xx(2),0.97*max(ydata),['\rho=' num2str(r_pss_v2(lvl,vr),'%.3f') '; p=' num2str(p_r_pss_v2(lvl,vr),'%.3f') ],'HorizontalAlign','right','FontSize',14)
text(0.99*xx(2),0.94*max(ydata),['p_{A|Age}=' num2str(pANCOVA_pss_v2(lvl,vr),'%.3f') ],'HorizontalAlign','right','FontSize',14)
hold off
ylabel(['C' num2str(lvl) ' ' g_ylbl{vr,1}])
xlabel('Physical Symptom Score')
axis([xx min(ydata) max(ydata)])
grid on
set(gca,'FontSize',14,'LineWidth',2)

subplot(1,4,4)
plot([1.5 2.5],[0 0],'^','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
hold on
plot([1.5 2.5],[0 0],'o','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
plot([1.5 2.5],[0 0],'d','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
plot([1.5 2.5],[0 0],'x','Color','r','LineWidth',3,'MarkerSize',13)
hold off
legend('MPS I - Hurler syndrome','MPS I - Hurler-Scheie syndrome','MPS I - Scheie syndrome',...
    'MPS VI',...
    'Location','southwest')
set(gca,'FontSize',14,'LineWidth',2)
axis([-101 -100 -101 -100]);
axis off


print(fullfile(save_path,['graph' num2str(varind+3) '-crosssectional-correlation']),'-dpng','-r300')
pause(0.15)
close(h(varind+3).fig)
pause(0.1)
disp(num2str(varind+3))

%% MANUAL MEASUREMENT STATS
measurement_corr = zeros(size(data_mps,1)+size(data_hc,1),size(measurement,2));
measind=1;
fgrs = varind+4;
sblpos = 1;
h(fgrs).fig = figure(fgrs);
set(h(fgrs).fig,'Position',[50 50 2350 800])
for varind = 1:size(measurement,2)
    subplot(2,5,sblpos)
    sblpos = sblpos + 1;
    
    yhc = measurement_hc(:,2,varind);
    yhc_mean = mean(yhc,'omitnan');
    yhc_std = std(yhc,'omitnan');
    
    y = measurement_mps(:,2,varind);
    y_all = measurement_mps(:,:,varind);
    y_mean = mean(y,'omitnan');
    y_std = std(y,'omitnan');
    
    plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',clr_stats,'LineWidth',5)
    hold on
    plot([-0.4 0.4],[yhc_mean-yhc_std yhc_mean-yhc_std],'-.','Color',clr_stats,'LineWidth',3)
    plot([-0.4 0.4],[yhc_mean+yhc_std yhc_mean+yhc_std],'-.','Color',clr_stats,'LineWidth',3)
    plot([1.13333333 1.93333333],[y_mean y_mean],'Color',clr_stats,'LineWidth',5)
    plot([1.13333333 1.93333333],[y_mean-y_std y_mean-y_std],'-.','Color',clr_stats,'LineWidth',3)
    plot([1.13333333 1.93333333],[y_mean+y_std y_mean+y_std],'-.','Color',clr_stats,'LineWidth',3)
    scatter(zeros(size(yhc)),yhc,100,'v','MarkerEdgeColor',clr_hc,'LineWidth',3, 'jitter','on', 'jitterAmount', 0.14,'MarkerEdgeAlpha',0.7)
    for ps = 1:size(y,1)
        if grp_mps(ps) == 0 || grp_mps(ps) == 1
            if strcmp(mpsitype_mps{ps,1},'H')
                mrk = ':^';
            elseif strcmp(mpsitype_mps{ps,1},'HS')
                mrk = ':o';
            elseif strcmp(mpsitype_mps{ps,1},'S')
                mrk = ':d';
            end
            clr = clr_mpsi;
        elseif grp_mps(ps) == 6
            mrk = ':x';
            clr = clr_mpsvi;
        end
        tm = time + [0 randn(1,1)*0.105 0 0 0];
        plot(tm(~isnan(y_all(ps,:))),y_all(ps,~isnan(y_all(ps,:))),mrk,'Color',clr,'LineWidth',3,'MarkerSize',9)
    end
    
    [~, pT_measurement(1,varind)]=ttest2(yhc,y);
    pW_measurement(1,varind)=ranksum(yhc,y);
    
    [~, pT_measurement_HS(1,varind)]=ttest2(  y(strcmp(mpsitype_mps,'HS'))  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ) );
    [~, pT_measurement_VI(1,varind)]=ttest2(  y(grp_mps==6)  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ) );
    [~, pT_measurement_S(1,varind)]=ttest2(  y(strcmp(mpsitype_mps,'S'))  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_S1 & age_mps(:,2) < agethr_S2 ) );

    pW_measurement_HS(1,varind)=ranksum(  y(strcmp(mpsitype_mps,'HS'))  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ) );
    pW_measurement_VI(1,varind)=ranksum(  y(grp_mps==6)  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ) );
    pW_measurement_S(1,varind)=ranksum(  y(strcmp(mpsitype_mps,'S'))  , y(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_S1 & age_mps(:,2) < agethr_S2 ) );
    
    p_tmp = anovan([y; yhc],{grp_ancova,weight_ancova},'Continuous',2,'varnames',{'Group','Weight'},'display','off');
    pANCOVA_weight_measurement(1,varind)= p_tmp(1);
    p_tmp = anovan([y; yhc],{grp_ancova,height_ancova},'Continuous',2,'varnames',{'Group','Height'},'display','off');
    pANCOVA_height_measurement(1,varind)= p_tmp(1);
%     p_tmp = anovan([y; yhc],{grp_ancova,female_ancova},'varnames',{'Group','Sex'},'display','off');
%     pANCOVA_sex_measurement(1,varind)= p_tmp(1);

    if pTadj_measurement(1,varind) < 0.05
%         plot(1.5,max(td)-0.04*(max(td)-min(td)),'k*','MarkerSize',16,'LineWidth',3)
        cf = 0.95;
        plot(1.2,cf*max([y; yhc]),'k+','MarkerSize',11,'LineWidth',3)
        if pANCOVA_weight_measurement(1,varind) < 0.05
            plot(1.47,cf*max([y; yhc]),'k>','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
        end
        if pANCOVA_height_measurement(1,varind) < 0.05
            plot(1.8,cf*max([y; yhc]),'ks','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
        end
    end
    hold off
    ylabel(measurement_names{1,varind})
    xlim([xmin xmax])
    grid on
    if varind <= 4
        set(gca,'FontSize',14,'LineWidth',2,'xtick',[0 1.533333333333333333],'xticklabel',{' ' ' '})
    else
        set(gca,'FontSize',14,'LineWidth',2,'xtick',[0 1.533333333333333333],'xticklabel',{'Control' 'MPS'})
    end
    
    measurement_corr(:,measind) = [y; yhc];
    measind = measind + 1;
end

subplot(2,5,10)
plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',clr_stats,'LineWidth',5)
hold on
plot([-0.4 0.4],[yhc_std yhc_std],'-.','Color',clr_stats,'LineWidth',3)
plot(0,0,'v','Color',clr_hc,'LineWidth',3,'MarkerSize',13)
plot([0.5 1.5],[0 0],':^','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
plot([0.5 1.5],[0 0],':o','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
plot([0.5 1.5],[0 0],':d','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
plot([1.5 2.5],[0 0],':x','Color',clr_mpsvi,'LineWidth',3,'MarkerSize',13)
plot(1,1,'+','Color','k','LineWidth',3,'MarkerSize',11)
plot(1,1,'>','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
plot(1,1,'s','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
hold off
legend('Mean','± Standard deviation','Healthy control','MPS I - Hurler syndrome','MPS I - Hurler-Scheie syndrome','MPS I - Scheie syndrome','MPS VI','Two-sample t-test (p_{BH}<0.05)',...
    'ANCOVA (Conf: Weight; p<0.05)','ANCOVA (Conf: Height; p<0.05)',...
    'Location','southwest')
set(gca,'FontSize',14,'LineWidth',2)
axis([-101 -100 -101 -100]);
axis off

print(fullfile(save_path,['graph' num2str(fgrs) '-manual-measurements' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs).fig)
pause(0.1)
disp(num2str(fgrs))
%%
[~, ~, ~, pTadj_measurement]=fdr_bh(pT_measurement);
[~, ~, ~, pWadj_measurement]=fdr_bh(pW_measurement);
save(pvaladjust_file,'pTadj','pWadj','pTadj_measurement','pWadj_measurement')

%% Cross-sectional graph - manual measurements
h(fgrs+1).fig = figure(fgrs+1);
set(h(fgrs+1).fig,'Position',[50 50 1200 1000])
colors_box = [0 0 1;1 0 0];
sblpos = 1;
for varind = 1:size(measurement,2)
    subplot(3,3,sblpos)
    sblpos = sblpos + 1;
    
    yhc = measurement_hc(:,2,varind);   
    y = measurement_mps(:,2,varind);
    
    if graph_specific_sub == 1
        y_showsub = y(strcmp(subid_mps,show_sub));
    end
    
    if size(yhc,1) == size(y,1)
        bh = boxplot([yhc y], 1:2,'BoxStyle','outline','Colors',colors_box);
    elseif size(yhc,1) + 1 == size(y,1)
        bh = boxplot([[yhc;NaN] y], 1:2,'BoxStyle','outline','Colors',colors_box);
    end
    hold on
    hh = findobj(gca,'Tag','Box');
    for j=1:length(hh)
        patch(get(hh(j),'XData'),get(hh(j),'YData'),get(hh(j),'Color'),'FaceAlpha',.5,'LineWidth',2);
    end
    for i=1:size(bh,1) % <- # graphics handles/x
        for j = 1:size(bh,2)
           if i == 1 || i == 2
                set(bh(i,j),'linewidth',2,'Color',[0 0 0],'LineStyle','-');
%                         set(bh(i,j),'Color',color_reverse(j,:));
           elseif i == 3 || i == 4
               set(bh(i,j),'linewidth',3,'Color','k','LineStyle','-');
           elseif i == 7
               set(bh(i,j),'Marker','.','MarkerSize',15);
           elseif i ~= 6
               set(bh(i,j),'linewidth',2,'Color',[0 0 0]);
           else
               set(bh(i,j),'linewidth',4,'Color',[0 0 0]);
           end
%                 disp([num2str(i) '    ' num2str(j)])
%                 disp(sprintf('working on component: %3d = %s',i,get(bh(i,1),'tag')));
            pause(.05);
        end
    end
    if pTadj_measurement(1,varind) < 0.05
%         plot(1.5,max(td)-0.04*(max(td)-min(td)),'k*','MarkerSize',16,'LineWidth',3)
        cf = 0.95;
        plot(1.3,cf*max([y; yhc]),'k+','MarkerSize',11,'LineWidth',3)
        if pANCOVA_weight_measurement(1,varind) < 0.05
            plot(1.47,cf*max([y; yhc]),'k>','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
        end
        if pANCOVA_height_measurement(1,varind) < 0.05
            plot(1.7,cf*max([y; yhc]),'ks','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
        end
    end
    if graph_specific_sub == 1
        plot(2,y_showsub,'d','Color',clr_mpsi,'Linewidth',3,'MarkerSize',11)
    end
    grid on
    hold off
    if sblpos <= size(measurement,2) - 2
        set(gca,'XTick',1:2,'Xticklabel','')
    else
        set(gca,'XTick',1:2,'Xticklabel',{'Control','MPS'})
%         xtickangle(30)
    end
    ylabel(measurement_names{1,varind})
    set(gca,'FontSize',14,'LineWidth',2)

end

print(fullfile(save_path,['graph' num2str(fgrs+1) '-manual-measurements-boxplot' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs+1).fig)
pause(0.1)
disp(num2str(fgrs+1))

%% Cross-correlation analysis
data_corr = [mri_corr measurement_corr age_ancova height_ancova weight_ancova female_ancova];
tmp = measurement_names;
for ind = 1:size(tmp,2)-1
    if contains(tmp{ind},'CCA')
        tmp{ind}(end-3:end)=[];
    elseif contains(tmp{ind},'[mm]')
        tmp{ind}(end-4:end)=[];
    end
end
data_corr_names = [mri_corr_names tmp 'Age' 'Height' 'Weight' 'Sex'];

[r_corr, p_corr] = corrcoef(data_corr,'Rows','pairwise');
r_corr = triu(r_corr);
p_corr = triu(p_corr);

[r_corr_control, p_corr_control] = corrcoef(data_corr(size(data_mps,1)+1:end,:),'Rows','pairwise');
r_corr_control = triu(r_corr_control);
p_corr_control = triu(p_corr_control);

%% Cross-correlation plot
[C, D] = meshgrid(1:size(r_corr,1)+1);

h(fgrs+2).fig = figure(fgrs+2);
set(h(fgrs+2).fig, 'Position', [10, 50, 2540, 1050]);
for kd = 1:2
    subplot(1,2,kd)
    if kd == 1 
        temp = r_corr;
    else
        temp = r_corr_control;
    end
    temp(end+1,:) = 0;
    temp(:,end+1) = 0;
    temp(end,end) = -1;
    surf(C,D,temp,'edgecolor','none')
    if kd == 1
        title('Cross-correlation Control+MPS','FontSize',14)
    else
        title('Cross-correlation Control','FontSize',14)
    end
    xlabel('parameter label','FontSize',14)
    ylabel('parameter label','FontSize',14)
    set(gca,'FontSize',11,...
            'ytick',1.5:(size(r_corr,1)+0.5),...
            'yticklabel',data_corr_names,...
            'xtick',1.5:(size(r_corr,1)+0.5),...
            'xticklabel',data_corr_names)
    ytickangle(270)
    colormap jet
    colorbar
    axis([ 1 size(r_corr,1)+1 1 size(r_corr,1)+1 min(r_corr(:)) max(r_corr(:)) ])
    az = 90;
    el = 90;
    view(az, el);
    hold on
    for grph = 1:size(data_names,2)+1
        if grph <= size(data_names,2)
            plot3([grph*nlevels+1 grph*nlevels+1],[1 grph*nlevels+3.0],[1 1],'k','LineWidth',3)
            plot3([grph*nlevels-1.0 size(temp,1)],[grph*nlevels+1 grph*nlevels+1],[1 1],'k','LineWidth',3)
        else
            plot3([grph*nlevels+3 grph*nlevels+3],[1 grph*nlevels+3.0],[1 1],'k','LineWidth',3)
            plot3([grph*nlevels-1.0 size(temp,1)],[grph*nlevels+3 grph*nlevels+3],[1 1],'k','LineWidth',3)
        end
    end
    hold off
end
print(fullfile(save_path,['graph' num2str(fgrs+2) '-crosscorrelation']),'-dpng','-r300')
pause(0.15)
close(h(fgrs+2).fig)
pause(0.1)


h(fgrs+3).fig = figure(fgrs+3);
set(h(fgrs+3).fig, 'Position', [1255+10, 50, 2540, 1050]);
for kd = 1:2
    subplot(1,2,kd)
    if kd == 1 
        temp = p_corr;
    else
        temp = p_corr_control;
    end
    temp(end+1,:) = 0;
    temp(:,end+1) = 0;
    temp(end,end) = 1;
    temp(temp>0.01) = 0.01;
    surf(C,D,temp,'edgecolor','none')
    if kd == 1
        title('Cross-correlation Control+MPS','FontSize',14)
    else
        title('Cross-correlation Control','FontSize',14)
    end
    xlabel('parameter label','FontSize',14)
    ylabel('parameter label','FontSize',14)
    set(gca,'FontSize',12,...
            'ytick',1.5:(size(r_corr,1)+0.5),...
            'yticklabel',data_corr_names,...
            'xtick',1.5:(size(r_corr,1)+0.5),...
            'xticklabel',data_corr_names)
    ytickangle(270)
    colormap hot
    colorbar
    axis([ 1 size(r_corr,1)+1 1 size(r_corr,1)+1 min(r_corr(:)) max(r_corr(:)) ])
    az = 90;
    el = 90;
    view(az, el);
    hold on
    for grph = 1:size(data_names,2)+1
        if grph <= size(data_names,2)
            plot3([grph*nlevels+1 grph*nlevels+1],[1 grph*nlevels+3.0],[1 1],'k','LineWidth',3)
            plot3([grph*nlevels-1.0 size(temp,1)],[grph*nlevels+1 grph*nlevels+1],[1 1],'k','LineWidth',3)
        else
            plot3([grph*nlevels+3 grph*nlevels+3],[1 grph*nlevels+3.0],[1 1],'k','LineWidth',3)
            plot3([grph*nlevels-1.0 size(temp,1)],[grph*nlevels+3 grph*nlevels+3],[1 1],'k','LineWidth',3)
        end
    end
    hold off
end
print(fullfile(save_path,['graph' num2str(fgrs+3) '-crosscorrelation-pvalue']),'-dpng','-r300')
pause(0.15)
close(h(fgrs+3).fig)
pause(0.1)


%% Data dimensionality reduction
% data_reduced_names = {'CSA-C15' 'APdiam-C57' 'FA-C13' 'FA-C57' 'AD-C13' 'AD-C57' 'RD-C13' 'RD-C57' 'MD-C13' 'MD-C57' 'PR' 'BDI' 'ADI' 'D2L' 'CD' 'FM' 'CD:FM'};
% data_reduced=nanmean(data_corr(:,1:5),2);
% data_reduced(:,2)=nanmean(data_corr(:,12:14),2);
% data_reduced(:,3)=nanmean(data_corr(:,22:24),2);
% data_reduced(:,4)=nanmean(data_corr(:,26:28),2);
% data_reduced(:,5)=nanmean(data_corr(:,29:31),2);
% data_reduced(:,6)=nanmean(data_corr(:,33:35),2);
% data_reduced(:,7)=nanmean(data_corr(:,36:38),2);
% data_reduced(:,8)=nanmean(data_corr(:,40:42),2);
% data_reduced(:,9)=nanmean(data_corr(:,43:45),2);
% data_reduced(:,10)=nanmean(data_corr(:,47:49),2);
% data_reduced(:,11:17)=data_corr(:,50:end);

% data_reduced_names = {'CSA-C15' 'APdiam-C57' 'FA-C13' 'FA-C57' 'AD-C57' 'RD-C57' 'CD' 'FM' 'CD:FM'};
% data_reduced=nanmean(data_corr(:,1:5),2);
% data_reduced(:,2)=nanmean(data_corr(:,12:14),2);
% data_reduced(:,3)=nanmean(data_corr(:,22:24),2);
% data_reduced(:,4)=nanmean(data_corr(:,26:28),2);
% data_reduced(:,5)=nanmean(data_corr(:,33:35),2);
% data_reduced(:,6)=nanmean(data_corr(:,40:42),2);
% data_reduced(:,7:9)=data_corr(:,[54:56]);

data_reduced_names = {'C17-CSA' 'C14-AP-diameter' 'C57-AP-diameter' 'C25-RL-diameter' ...
    'C13-FA' 'C67-FA' 'C67-AD' 'C13-RD' 'C67-RD' ...
    'CD' 'FM' 'CD:FM' 'PR' 'BDI' 'D2L' ...
    'Height' 'Weight' 'Age'}; %     'Sex'
data_reduced=nanmean(data_corr(:,1:7),2);
data_reduced(:,2)=nanmean(data_corr(:,8:11),2);
data_reduced(:,3)=nanmean(data_corr(:,12:14),2);
data_reduced(:,4)=nanmean(data_corr(:,16:19),2);
data_reduced(:,5)=nanmean(data_corr(:,22:24),2);
data_reduced(:,6)=nanmean(data_corr(:,27:28),2);
data_reduced(:,7)=nanmean(data_corr(:,34:35),2);
data_reduced(:,8)=nanmean(data_corr(:,36:38),2);
data_reduced(:,9)=nanmean(data_corr(:,41:42),2);
data_reduced(:,10:15)=data_corr(:,[52 53 54 50 55 51]);
data_reduced(:,16)=height_ancova;
data_reduced(:,17)=weight_ancova;
data_reduced(:,18)=age_ancova;
% data_reduced(:,19)=female_ancova;

% data_reduced_names = {'C17-CSA' 'C14-AP-diameter' 'C57-AP-diameter' 'C25-RL-diameter' ...
%     'C13-FA' 'C56-FA' 'C56-AD' 'C67-RD' ... 'C13-RD'
%     'CD' 'FM' 'CD:FM' 'PR' 'BDI' ... 'D2L'
%     'Age'}; %   'Height' 'Weight'  'Sex'
% data_reduced=nanmean(data_corr(:,1:7),2);
% data_reduced(:,2)=nanmean(data_corr(:,8:11),2);
% data_reduced(:,3)=nanmean(data_corr(:,12:14),2);
% data_reduced(:,4)=nanmean(data_corr(:,16:19),2);
% data_reduced(:,5)=nanmean(data_corr(:,22:24),2);
% data_reduced(:,6)=nanmean(data_corr(:,26:27),2);
% data_reduced(:,7)=nanmean(data_corr(:,33:34),2);
% % data_reduced(:,8)=nanmean(data_corr(:,36:38),2);
% data_reduced(:,8)=nanmean(data_corr(:,41:42),2);
% data_reduced(:,9:13)=data_corr(:,[52 53 54 50 55]); % 51
% % data_reduced(:,16)=height_ancova;
% % data_reduced(:,17)=weight_ancova;
% data_reduced(:,14)=age_ancova;
% % data_reduced(:,19)=female_ancova;

[r_corr_reduced, p_corr_reduced] = corrcoef(data_reduced,'Rows','pairwise');
% data_reduced_norm = ( data_reduced - repmat(mean(data_reduced,'omitnan'),size(data_reduced,1),1) ) ./ repmat(std(data_reduced,'omitnan'),size(data_reduced,1),1) ;
%% PCA and FACTORAN analysis
[coeff,latent,explained] = pcacov(r_corr_reduced);
% [coeff,score,latent,tsquared,explained,mu] = pca(fctrn);
explained_cumulative = cumsum(explained);

h(fgrs+4).fig = figure(fgrs+4);
set(h(fgrs+4).fig, 'Position', [10, 50, 2050, 800]);
subplot(1,2,1)
plot([-1 1],[0 0],'k','LineWidth',3)
hold on
plot([0 0],[-1 1],'k','LineWidth',3)
plot([-1 1],[1 -1],'--','LineWidth',3,'Color',[0.6 0.6 0.6])
plot([-1 1],[-1 1],'--','LineWidth',3,'Color',[0.6 0.6 0.6])
% biplot(coeff(:,[1 2]),'Scores',score(:,1:2),'VarLabels',data_reduced_names,'LineWidth',3,'MarkerSize',30)
bp=biplot(coeff(:,[1 2]),'VarLabels',data_reduced_names,'LineWidth',3,'MarkerSize',30);
for ind = 1:(size(bp,1))
    if bp(ind).Color(3) == 1
        bp(ind).Color = [0 0.749 1];
        bp(ind).LineWidth = 4;
        bp(ind).MarkerSize = 40;
        if ind <= size(data_reduced,2)
            c = 2;
        else
            c = 1;
        end
        if strcmp(bp(ind+c*size(data_reduced,2)).String,'C56-AD') || ...
            strcmp(bp(ind+c*size(data_reduced,2)).String,'C56-FA') || ...
            strcmp(bp(ind+c*size(data_reduced,2)).String,'C57-AD') || ...
            strcmp(bp(ind+c*size(data_reduced,2)).String,'C57-FA') || ...
            strcmp(bp(ind+c*size(data_reduced,2)).String,'C67-AD') || ...
            strcmp(bp(ind+c*size(data_reduced,2)).String,'C67-FA') || ...
            strcmp(bp(ind+c*size(data_reduced,2)).String,'C67-RD') || ...
            strcmp(bp(ind+c*size(data_reduced,2)).String,'PR') || ...
            strcmp(bp(ind+c*size(data_reduced,2)).String,'CD:FM')
            bp(ind).Color = clr_mpsvi;
        end
    else     
        bp(ind).FontSize = 13;
        bp(ind).FontWeight = 'bold';
%         if bp(ind).Position(1) < 0
%             bp(ind).HorizontalAlignment = 'right';
%         end
%         if bp(ind).Position(2) >= 0
%             bp(ind).Position(2) = bp(ind).Position(2)+0.025;
%         else
%             bp(ind).Position(2) = bp(ind).Position(2)-0.025;
%         end
        if strcmp(bp(ind).String,'C25-RL-diameter')
            bp(ind).Position(1) = bp(ind).Position(1)-0.005;
            bp(ind).Position(2) = bp(ind).Position(2)-0.025;
        end
        if strcmp(bp(ind).String,'C14-AP-diameter')
            bp(ind).Position(1) = bp(ind).Position(1)-0.030;
            bp(ind).Position(2) = bp(ind).Position(2)+0.005;
        end
        if strcmp(bp(ind).String,'Height')
            bp(ind).Position(2) = bp(ind).Position(2)+0.010;
        end
        if strcmp(bp(ind).String,'C67-FA')
            bp(ind).Position(2) = bp(ind).Position(2)-0.020;
        end
         if strcmp(bp(ind).String,'C67-AD')
            bp(ind).Position(2) = bp(ind).Position(2)+0.005;
        end
        if strcmp(bp(ind).String,'C13-RD')
            bp(ind).Position(1) = bp(ind).Position(1)-0.010;
            bp(ind).Position(2) = bp(ind).Position(2)+0.010;
        end
        if strcmp(bp(ind).String,'C13-FA')
            bp(ind).Position(2) = bp(ind).Position(2)-0.020;
        end
%         if strcmp(bp(ind).String,'C57-FA')
%             bp(ind).Position(1) = bp(ind).Position(1)+0.010;
%             bp(ind).Position(2) = bp(ind).Position(2)+0.017;
%         end
%         if strcmp(bp(ind).String,'FM')
%             bp(ind).Position(1) = bp(ind).Position(1)+0.010;
%             bp(ind).Position(2) = bp(ind).Position(2)+0.010;
%         end
% %         if strcmp(bp(ind).String,'D2L')
% %             bp(ind).Position(2) = bp(ind).Position(2)-0.025;
% %         end
    end
end
bp(end).LineWidth=3;
xlabel(['Component 1 [variability: ' num2str(round(explained(1,1)*100)/100) '%]'])
ylabel(['Component 2 [variability: ' num2str(round(explained(2,1)*100)/100) '%]'])
title('PCA variable biplot projection')
hold off
axis([-0.52 0.52 -0.52 0.52])
grid on
set(gca,'FontSize',14,'LineWidth',2,...
    'XTick',-1:0.1:1,'XTickLabel',-1:0.1:1,...
    'YTick',-1:0.1:1,'YTickLabel',-1:0.1:1)

subplot(1,2,2)
plot(explained,'-','LineWidth',4,'Marker','.','MarkerSize',60,'Color',[0 0.749 1])
axis([1 size(data_reduced,2) 0 explained(1)+2])
grid on
xlabel('Component number')
ylabel('Explained variability [%]')
title('Variability explained per each component')
set(gca,'FontSize',14,'LineWidth',2)

print(fullfile(save_path,['graph' num2str(fgrs+4) '-pca']),'-dpng','-r300')
pause(0.15)
close(h(fgrs+4).fig)
pause(0.1)

%% Treatment age plot - automated qMRI

[lvl, vr] = find(p_r_transpl_v2 < 0.1 & pANCOVA_ageT_v2 < 0.1);

h(fgrs+5).fig = figure(fgrs+5);
set(h(fgrs+5).fig,'Position',[1000 40 780 1200])

xdata = ageT_mps;
xdata_names = 'Age at transplant [m.o.]';
xx = [min(xdata) max(xdata)];
sbpl = 1;
for ind = 1:size(lvl,1)
    ydata = data_mps(:,2,lvl(ind,1),vr(ind,1));
    ydata_names = [ 'C' num2str(lvl(ind,1)) '-' data_names{1,vr(ind,1)} ];
    
    q = polyfit(xdata(~isnan(xdata+ydata)),ydata(~isnan(xdata+ydata)),1);
    yy = q(1).*xx + q(2);
    subplot(3,2,sbpl)
    plot(xx,yy,'k-.','LineWidth',3)
    hold on
    plot(xdata(strcmp(transplant_mps,'Cord Blood') & strcmp(donor_mps,'Matched Unrelated'),1),ydata(strcmp(transplant_mps,'Cord Blood') & strcmp(donor_mps,'Matched Unrelated'),1),'^','Color',[255,99,71]/255,'MarkerSize',14,'LineWidth',4)
    plot(xdata(strcmp(transplant_mps,'Bone Marrow') & strcmp(donor_mps,'Matched Unrelated'),1),ydata(strcmp(transplant_mps,'Bone Marrow') & strcmp(donor_mps,'Matched Unrelated'),1),'^','Color','c','MarkerSize',14,'LineWidth',4)
    plot(xdata(strcmp(transplant_mps,'Cord Blood') & strcmp(donor_mps,'Sibling'),1),ydata(strcmp(transplant_mps,'Cord Blood') & strcmp(donor_mps,'Sibling'),1),'x','Color',[255,99,71]/255,'MarkerSize',14,'LineWidth',4)
    plot(xdata(strcmp(transplant_mps,'Bone Marrow') & strcmp(donor_mps,'Sibling'),1),ydata(strcmp(transplant_mps,'Bone Marrow') & strcmp(donor_mps,'Sibling'),1),'x','Color','c','MarkerSize',14,'LineWidth',4)
    plot(xdata(strcmp(transplant_mps,'Cord Blood') & ~strcmp(donor_mps,'Sibling') & ~strcmp(donor_mps,'Matched Unrelated'),1),ydata(strcmp(transplant_mps,'Cord Blood') & ~strcmp(donor_mps,'Sibling') & ~strcmp(donor_mps,'Matched Unrelated'),1),'o','Color',[255,99,71]/255,'MarkerSize',14,'LineWidth',4)
    plot(xdata(strcmp(transplant_mps,'Bone Marrow') & ~strcmp(donor_mps,'Matched Unrelated') & ~strcmp(donor_mps,'Sibling'),1),ydata(strcmp(transplant_mps,'Bone Marrow') & ~strcmp(donor_mps,'Matched Unrelated') & ~strcmp(donor_mps,'Sibling'),1),'o','Color','c','MarkerSize',14,'LineWidth',4)
    if q(1) > 0
        text(0.98*xx(2),1.10*min(ydata),['r=' num2str(r_transpl_v2(lvl(ind,1),vr(ind,1)),'%.3f') '; p=' num2str(p_r_transpl_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
        text(0.98*xx(2),1.05*min(ydata),['p_{A|Age}=' num2str(pANCOVA_ageT_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
    else
        text(0.98*xx(2),0.95*max(ydata),['r=' num2str(r_transpl_v2(lvl(ind,1),vr(ind,1)),'%.3f') '; p=' num2str(p_r_transpl_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
        text(0.98*xx(2),0.88*max(ydata),['p_{A|Age}=' num2str(pANCOVA_ageT_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
    end
    hold off
    ylabel(['C' num2str(lvl(ind,1)) ' ' g_ylbl{vr(ind,1),1}])
    axis([xx min(ydata) max(ydata)])
    grid on
    if ind < 3
        set(gca,'XTick',0:5:50,'XtickLabel','')
    else
        xlabel(xdata_names)
        set(gca,'XTick',0:5:50,'XtickLabel',0:5:50)
    end
    set(gca,'FontSize',14,'LineWidth',2)
    
    sbpl = sbpl + 2;
end

subplot(3,2,6)
plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',[255,99,71]/255,'LineWidth',5)
hold on
plot([-0.4 0.4],[yhc_std yhc_std],'Color','c','LineWidth',5)
plot([1.5 2.5],[0 0],'^','Color','k','LineWidth',3,'MarkerSize',13)
plot([1.5 2.5],[0 0],'x','Color','k','LineWidth',3,'MarkerSize',13)
plot([0.5 1.5],[0 0],'o','Color','k','LineWidth',3,'MarkerSize',13)
hold off
legend('Transplant: Cord Blood','Transplant: Bone Marrow',...
    'Donor: Matched Unrelated','Donor: Sibling','Donor: Unknown',...
    'Location','southwest')
set(gca,'FontSize',14,'LineWidth',2)
axis([-101 -100 -101 -100]);
axis off

print(fullfile(save_path,['graph' num2str(fgrs+5) '-treatment' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs+5).fig)
pause(0.1)
disp(num2str(fgrs+5))


%% Height patient plot - automated qMRI

[lvl, vr] = find(p_r_height_v2 < 0.05 & pANCOVA_height_v2 < 0.1);

h(fgrs+6).fig = figure(fgrs+6);
set(h(fgrs+6).fig,'Position',[1000 40 1850 1200])

xdata = height_mps(:,2);
xdata_names = 'Height [cm]';
xx = [min(xdata) max(xdata)];
sbpl = 1;
for ind = 1:size(lvl,1)
    ydata = data_mps(:,2,lvl(ind,1),vr(ind,1));
    ydata_names = [ 'C' num2str(lvl(ind,1)) '-' data_names{1,vr(ind,1)} ];
    
    q = polyfit(xdata(~isnan(xdata+ydata)),ydata(~isnan(xdata+ydata)),1);
    yy = q(1).*xx + q(2);
    subplot(3,4,sbpl)
    plot(xx,yy,'k-.','LineWidth',3)
    hold on
    plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),'o','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),'d','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(xdata(grp_mps==6,1),ydata(grp_mps==6,1),'rx','MarkerSize',14,'LineWidth',4)
    if q(1) > 0
        if max(ydata)> 1.5
            text(0.98*xx(2),1.077*min(ydata),['r=' num2str(r_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') '; p=' num2str(p_r_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
            text(0.98*xx(2),1.03*min(ydata),['p_{A|Age}=' num2str(pANCOVA_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
        else
            text(0.98*xx(2),1.13*min(ydata),['r=' num2str(r_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') '; p=' num2str(p_r_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
            text(0.98*xx(2),1.06*min(ydata),['p_{A|Age}=' num2str(pANCOVA_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
        end
    else
        text(0.98*xx(2),0.97*max(ydata),['r=' num2str(r_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') '; p=' num2str(p_r_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
        text(0.98*xx(2),0.93*max(ydata),['p_{A|Age}=' num2str(pANCOVA_height_v2(lvl(ind,1),vr(ind,1)),'%.3f') ],'HorizontalAlign','right','FontSize',14)
    end
    hold off
    ylabel(['C' num2str(lvl(ind,1)) ' ' g_ylbl{vr(ind,1),1}])
    axis([xx min(ydata) max(ydata)])
    grid on
    if ind < 9
        set(gca,'XTick',0:10:200,'XtickLabel','')
    else
        xlabel(xdata_names)
        set(gca,'XTick',0:10:200,'XtickLabel',0:10:200)
    end
    set(gca,'FontSize',14,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

% subplot(3,3,9)
% plot([1.5 2.5],[0 0],'^','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
% hold on
% plot([1.5 2.5],[0 0],'o','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
% plot([1.5 2.5],[0 0],'d','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
% plot([1.5 2.5],[0 0],'x','Color','r','LineWidth',3,'MarkerSize',13)
% hold off
% legend('MPS I - Hurler syndrome','MPS I - Hurler-Scheie syndrome','MPS I - Scheie syndrome',...
%     'MPS VI',...
%     'Location','southwest')
% set(gca,'FontSize',14,'LineWidth',2)
% axis([-101 -100 -101 -100]);
% axis off

print(fullfile(save_path,['graph' num2str(fgrs+6) '-height-corr' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs+6).fig)
pause(0.1)
disp(num2str(fgrs+6))


%% Show H and HS syndromes and MPS VI

[lvl, vr] = find(pT_HS < 0.05 | pT_VI < 0.05);

h(fgrs+7).fig = figure(fgrs+7);
set(h(fgrs+7).fig,'Position',[1000 40 2400 1200])

sbpl = 1;
for ind = 1:size(lvl,1)
    ydata = data_mps(:,2,lvl(ind,1),vr(ind,1));
    ydata_names = [ 'C' num2str(lvl(ind,1)) '-' data_names{1,vr(ind,1)} ];
    
    Cdata = data_hc(age_hc(:,2) > agethr_HS,2,lvl(ind,1),vr(ind,1));
    Hdata = ydata(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ,1);
    HSdata = ydata(strcmp(mpsitype_mps,'HS'),1);
    VIdata = ydata(grp_mps==6,1);
    
    ymax = max([Cdata;Hdata; HSdata; VIdata]);
    
    subplot(2,7,sbpl)
    plot(ones(size(Cdata)),Cdata,'v','Color',clr_hc,'MarkerSize',14,'LineWidth',4)
    hold on
    plot(2*ones(size(Hdata)),Hdata,'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(3*ones(size(HSdata)),HSdata,'o','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(4*ones(size(VIdata)),VIdata,'x','Color',clr_mpsvi,'MarkerSize',14,'LineWidth',4)
    if pT_HS(lvl(ind,1),vr(ind,1)) < 0.05
        text(3,0.97*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    if pT_VI(lvl(ind,1),vr(ind,1)) < 0.05
        text(4,0.97*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    hold off
    ylabel(['C' num2str(lvl(ind,1)) ' ' g_ylbl{vr(ind,1),1}])
    xlim([0.5 4.5])
    grid on
    if ind < 7
        set(gca,'XTick',1:4,'XTickLabel','')
    else
        set(gca,'XTick',1:4,'XTickLabel',{'Healthy controls','Hurler syndrome','Hurler-Scheie syndrome','MPS VI'})
        xtickangle(45)
    end
    set(gca,'FontSize',16,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

vr = find(pT_measurement_HS < 0.10 | pT_measurement_VI < 0.10);

for ind = 1:size(vr,2)
    ydata = measurement_mps(:,2,vr(1,ind));
    
    Cdata = measurement_hc(age_hc(:,2) > agethr_HS,2,vr(1,ind));
    Hdata = ydata(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ,1);
    HSdata = ydata(strcmp(mpsitype_mps,'HS'),1);
    VIdata = ydata(grp_mps==6,1);
    
    ymax = max([Cdata;Hdata; HSdata; VIdata]);
    
    subplot(2,7,sbpl)
    plot(ones(size(Cdata)),Cdata,'v','Color',clr_hc,'MarkerSize',14,'LineWidth',4)
    hold on
    plot(2*ones(size(Hdata)),Hdata,'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(3*ones(size(HSdata)),HSdata,'o','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(4*ones(size(VIdata)),VIdata,'x','Color',clr_mpsvi,'MarkerSize',14,'LineWidth',4)
    if pT_measurement_HS(1,vr(1,ind)) < 0.05
        text(3,0.97*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    if pT_measurement_VI(1,vr(1,ind)) < 0.05
        text(4,0.92*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    hold off
    ylabel(measurement_names{1,vr(1,ind)})
    xlim([0.5 4.5])
    grid on
    set(gca,'XTick',1:4,'XTickLabel',{'Healthy controls','Hurler syndrome','Hurler-Scheie syndrome','MPS VI'})
    xtickangle(45)
    set(gca,'FontSize',16,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

print(fullfile(save_path,['graph' num2str(fgrs+7) '-mps-differences' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs+7).fig)
pause(0.1)
disp(num2str(fgrs+7))

%% Show S syndrome

[lvl, vr] = find(pT_S < 0.1);

h(fgrs+8).fig = figure(fgrs+8);
set(h(fgrs+8).fig,'Position',[1000 40 2400 1200])

sbpl = 1;
for ind = 1:size(lvl,1)
    ydata = data_mps(:,2,lvl(ind,1),vr(ind,1));
    ydata_names = [ 'C' num2str(lvl(ind,1)) '-' data_names{1,vr(ind,1)} ];
    
    Cdata = data_hc(age_hc(:,2) > agethr_S1 & age_hc(:,2) < agethr_S2,2,lvl(ind,1),vr(ind,1));
    Hdata = ydata(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_S1 & age_mps(:,2) < agethr_S2 ,1);
    Sdata = ydata(strcmp(mpsitype_mps,'S'),1);
    
    ymax = max([Cdata;Hdata; Sdata]);
    
    subplot(2,7,sbpl)
    plot(ones(size(Cdata)),Cdata,'v','Color',clr_hc,'MarkerSize',14,'LineWidth',4)
    hold on
    plot(2*ones(size(Hdata)),Hdata,'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(3*ones(size(HSdata)),Sdata,'d','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    if pT_S(lvl(ind,1),vr(ind,1)) < 0.05
        text(3,0.99*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    hold off
    ylabel(['C' num2str(lvl(ind,1)) ' ' g_ylbl{vr(ind,1),1}])
    xlim([0.5 3.5])
    grid on
    set(gca,'XTick',1:3,'XTickLabel',{'Healthy controls','Hurler syndrome','Scheie syndrome'})
    xtickangle(45)
    set(gca,'FontSize',20,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

vr = find(pT_measurement_S < 0.05);

for ind = 1:size(vr,2)
    ydata = measurement_mps(:,2,vr(1,ind));
    
    Cdata = measurement_hc(age_hc(:,2) > agethr_S1 & age_hc(:,2) < agethr_S2,2,vr(1,ind));
    Hdata = ydata(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_S1 & age_mps(:,2) < agethr_S2,1);
    Sdata = ydata(strcmp(mpsitype_mps,'S'),1);
    
    ymax = max([Cdata;Hdata; Sdata]);
    
    subplot(2,7,sbpl)
    plot(ones(size(Cdata)),Cdata,'v','Color',clr_hc,'MarkerSize',14,'LineWidth',4)
    hold on
    plot(2*ones(size(Hdata)),Hdata,'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(3*ones(size(Sdata)),Sdata,'d','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    if pT_measurement_S(1,vr(1,ind)) < 0.05
        if ymax > 15
            text(3,0.92*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
        else
            text(3,0.97*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
        end
    end
    hold off
    ylabel(measurement_names{1,vr(1,ind)})
    xlim([0.5 3.5])
    grid on
    set(gca,'XTick',1:3,'XTickLabel',{'Healthy controls','Hurler syndrome','Scheie syndrome'})
    xtickangle(45)
    set(gca,'FontSize',20,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

print(fullfile(save_path,['graph' num2str(fgrs+8) '-scheie-differences' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs+8).fig)
pause(0.1)
disp(num2str(fgrs+8))


%% Show H and HS syndromes and MPS VI - aggregated data

vr = find(pT_HS_agr < 0.05)';
mrk_size = 140;

h(fgrs+9).fig = figure(fgrs+9);
set(h(fgrs+9).fig,'Position',[1000 40 1200 1200])

sbpl = 1;
for ind = 1:size(vr,1)   
    Cdata = CC(:,:,vr(ind,1));
    Hdata = YY_H(:,:,vr(ind,1));
    HSdata = YY_HS(:,:,vr(ind,1));
    VIdata = YY_VI(:,:,vr(ind,1));
    
    ymax = max([Cdata(:);Hdata(:); HSdata(:); VIdata(:)]);
    
    subplot(2,3,sbpl)
    plot([0.60 1.40],[mean(Cdata(:),'omitnan') mean(Cdata(:),'omitnan')],'k','LineWidth',5)
    hold on
    plot([1.60 2.40],[mean(Hdata(:),'omitnan') mean(Hdata(:),'omitnan')],'k','LineWidth',5)
    plot([2.60 3.40],[mean(HSdata(:),'omitnan') mean(HSdata(:),'omitnan')],'k','LineWidth',5)
    plot([3.60 4.40],[mean(VIdata(:),'omitnan') mean(VIdata(:),'omitnan')],'k','LineWidth',5)
    scatter(ones(size(Cdata(:))),Cdata(:),mrk_size,'v','MarkerEdgeColor',clr_hc,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(2*ones(size(Hdata(:))),Hdata(:),mrk_size,'^','MarkerEdgeColor',clr_mpsi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(3*ones(size(HSdata(:))),HSdata(:),mrk_size,'o','MarkerEdgeColor',clr_mpsi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(4*ones(size(VIdata(:))),VIdata(:),mrk_size,'x','MarkerEdgeColor',clr_mpsvi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    if pT_HS_agr(1,vr(ind,1)) < 0.05
        text(3,0.96*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    if pT_VI_agr(1,vr(ind,1)) < 0.05
        text(4,0.96*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    hold off
    ylabel(['C1-C7 ' g_ylbl{vr(ind,1),1}])
    xlim([0.5 4.5])
    grid on
    if ind < 3
        set(gca,'XTick',1:4,'XTickLabel','')
    else
        set(gca,'XTick',1:4,'XTickLabel',{'Healthy controls','Hurler syndrome','Hurler-Scheie syndrome','MPS VI'})
        xtickangle(45)
    end
    set(gca,'FontSize',16,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

vr = find(pT_measurement_HS < 0.10 | pT_measurement_VI < 0.10);

for ind = 1:size(vr,2)
    ydata = measurement_mps(:,2,vr(1,ind));
    
    Cdata = measurement_hc(age_hc(:,2) > agethr_HS,2,vr(1,ind));
    Hdata = ydata(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_HS ,1);
    HSdata = ydata(strcmp(mpsitype_mps,'HS'),1);
    VIdata = ydata(grp_mps==6,1);
    
    ymax = max([Cdata;Hdata; HSdata; VIdata]);
    
    subplot(2,3,sbpl)
    plot([0.60 1.40],[mean(Cdata,'omitnan') mean(Cdata,'omitnan')],'k','LineWidth',5)
    hold on
    plot([1.60 2.40],[mean(Hdata,'omitnan') mean(Hdata,'omitnan')],'k','LineWidth',5)
    plot([2.60 3.40],[mean(HSdata,'omitnan') mean(HSdata,'omitnan')],'k','LineWidth',5)
    plot([3.60 4.40],[mean(VIdata,'omitnan') mean(VIdata,'omitnan')],'k','LineWidth',5)
    scatter(ones(size(Cdata(:))),Cdata(:),mrk_size,'v','MarkerEdgeColor',clr_hc,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(2*ones(size(Hdata(:))),Hdata(:),mrk_size,'^','MarkerEdgeColor',clr_mpsi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(3*ones(size(HSdata(:))),HSdata(:),mrk_size,'o','MarkerEdgeColor',clr_mpsi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(4*ones(size(VIdata(:))),VIdata(:),mrk_size,'x','MarkerEdgeColor',clr_mpsvi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    if pT_measurement_HS(1,vr(1,ind)) < 0.05
        text(3,0.97*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    if pT_measurement_VI(1,vr(1,ind)) < 0.05
        text(4,0.92*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
    end
    hold off
    ylabel(measurement_names{1,vr(1,ind)})
    xlim([0.5 4.5])
    grid on
    set(gca,'XTick',1:4,'XTickLabel',{'Healthy controls','Hurler syndrome','Hurler-Scheie syndrome','MPS VI'})
    xtickangle(45)
    set(gca,'FontSize',16,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

print(fullfile(save_path,['graph' num2str(fgrs+9) '-mps-aggregated-differences' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs+9).fig)
pause(0.1)
disp(num2str(fgrs+9))


%% Show H and HS syndromes and MPS VI - aggregated data

vr = find(pT_S_agr < 0.05)';
mrk_size = 140;

h(fgrs+10).fig = figure(fgrs+10);
set(h(fgrs+10).fig,'Position',[1000 40 1200 1200])

sbpl = 1;
for ind = 1:size(vr,1)   
    Cdata = CC_fS(:,:,vr(ind,1));
    Hdata = YY_HfS(:,:,vr(ind,1));
    Sdata = YY_S(:,:,vr(ind,1));
    
    ymax = max([Cdata(:);Hdata(:); Sdata(:)]);
    
    subplot(2,3,sbpl)
    plot([0.60 1.40],[mean(Cdata(:),'omitnan') mean(Cdata(:),'omitnan')],'k','LineWidth',5)
    hold on
    plot([1.60 2.40],[mean(Hdata(:),'omitnan') mean(Hdata(:),'omitnan')],'k','LineWidth',5)
    plot([2.60 3.40],[mean(Sdata(:),'omitnan') mean(Sdata(:),'omitnan')],'k','LineWidth',5)
    scatter(ones(size(Cdata(:))),Cdata(:),mrk_size,'v','MarkerEdgeColor',clr_hc,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(2*ones(size(Hdata(:))),Hdata(:),mrk_size,'^','MarkerEdgeColor',clr_mpsi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(3*ones(size(Sdata(:))),Sdata(:),mrk_size,'d','MarkerEdgeColor',clr_mpsi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    if pT_S_agr(1,vr(ind,1)) < 0.05
        if ymax < 0.7
            text(3,1.03*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
        else
            text(3,0.99*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
        end
    end
    hold off
    ylabel(['C1-C7 ' g_ylbl{vr(ind,1),1}])
    xlim([0.5 3.5])
    grid on
    if ind < 3
        set(gca,'XTick',1:3,'XTickLabel','')
    else
        set(gca,'XTick',1:3,'XTickLabel',{'Healthy controls','Hurler syndrome','Scheie syndrome'})
        xtickangle(45)
    end
    set(gca,'FontSize',16,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

vr = find(pT_measurement_S < 0.05);

for ind = 1:size(vr,2)
    ydata = measurement_mps(:,2,vr(1,ind));
    
    Cdata = measurement_hc(age_hc(:,2) > agethr_S1 & age_hc(:,2) < agethr_S2,2,vr(1,ind));
    Hdata = ydata(strcmp(mpsitype_mps,'H') & age_mps(:,2) > agethr_S1 & age_mps(:,2) < agethr_S2,1);
    Sdata = ydata(strcmp(mpsitype_mps,'S'),1);
    
    ymax = max([Cdata;Hdata; Sdata]);
    
    subplot(2,3,sbpl)
    plot([0.60 1.40],[mean(Cdata,'omitnan') mean(Cdata,'omitnan')],'k','LineWidth',5)
    hold on
    plot([1.60 2.40],[mean(Hdata,'omitnan') mean(Hdata,'omitnan')],'k','LineWidth',5)
    plot([2.60 3.40],[mean(Sdata,'omitnan') mean(Sdata,'omitnan')],'k','LineWidth',5)
    scatter(ones(size(Cdata(:))),Cdata(:),mrk_size,'v','MarkerEdgeColor',clr_hc,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(2*ones(size(Hdata(:))),Hdata(:),mrk_size,'^','MarkerEdgeColor',clr_mpsi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    scatter(3*ones(size(Sdata(:))),Sdata(:),mrk_size,'d','MarkerEdgeColor',clr_mpsi,'LineWidth',4,'MarkerEdgeAlpha',0.5,'jitter','on','jitteramount',0.17)
    if pT_measurement_S(1,vr(1,ind)) < 0.05
        if ymax > 18
        	text(3,0.90*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
        else
            text(3,0.98*ymax,'*','Fontsize',28,'Fontweight','bold','HorizontalAlignment','center')
        end
    end
    hold off
    ylabel(measurement_names{1,vr(1,ind)})
    xlim([0.5 3.5])
    grid on
    set(gca,'XTick',1:3,'XTickLabel',{'Healthy controls','Hurler syndrome','Scheie syndrome'})
    xtickangle(45)
    set(gca,'FontSize',16,'LineWidth',2)
    
    sbpl = sbpl + 1;
end

print(fullfile(save_path,['graph' num2str(fgrs+10) '-scheie-aggregated-differences' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs+10).fig)
pause(0.1)
disp(num2str(fgrs+10))


%% Height aggregated patient plot - automated qMRI
h(fgrs+11).fig = figure(fgrs+11);
set(h(fgrs+11).fig,'Position',[1000 40 1850 1200])

xdata = height_mps(:,2);
xdata_names = 'Height [cm]';
xx = [min(xdata) max(xdata)];
r_height_agr = NaN*ones(1,size(data_mps,4));
p_r_height_agr = NaN*ones(1,size(data_mps,4));
pANCOVA_height_agr = NaN*ones(1,size(data_mps,4));
sbpl = 1;
for ind = [4 6 7]
    ydata = mean(squeeze(data_mps(:,2,4:7,ind)),2,'omitnan');
    ydata_names = [ 'C4-C7 ' data_names{1,ind} ];
    
    [tmp_r, tmp_p] = corrcoef(xdata,ydata,'Rows','Pairwise');
    r_height_agr(1,ind) = tmp_r(1,2);
    p_r_height_agr(1,ind) = tmp_p(1,2);
    
    p_tmp = anovan(ydata,{height_mps(:,2),age_mps(:,2)},'Continuous',[1 2],'varnames',{'Height','Age'},'display','off');
    pANCOVA_height_agr(1,ind)= p_tmp(1);
    
    q = polyfit(xdata(~isnan(xdata+ydata)),ydata(~isnan(xdata+ydata)),1);
    yy = q(1).*xx + q(2);
    subplot(3,4,sbpl)
    plot(xx,yy,'k-.','LineWidth',3)
    hold on
    plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'H'),1),'^','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'HS'),1),'o','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(xdata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),ydata(grp_mps<=1 & strcmp(mpsitype_mps,'S'),1),'d','Color',clr_mpsi,'MarkerSize',14,'LineWidth',4)
    plot(xdata(grp_mps==6,1),ydata(grp_mps==6,1),'rx','MarkerSize',14,'LineWidth',4)
    if q(1) > 0
        if max(ydata)> 1.5
            text(0.98*xx(2),1.077*min(ydata),['r=' num2str(r_height_agr(1,ind),'%.3f') '; p=' num2str(p_r_height_agr(1,ind),'%.3f') ],'HorizontalAlign','right','FontSize',14)
            text(0.98*xx(2),1.03*min(ydata),['p_{A|Age}=' num2str(pANCOVA_height_agr(1,ind),'%.3f') ],'HorizontalAlign','right','FontSize',14)
        else
            text(0.98*xx(2),1.13*min(ydata),['r=' num2str(r_height_agr(1,ind),'%.3f') '; p=' num2str(p_r_height_agr(1,ind),'%.3f') ],'HorizontalAlign','right','FontSize',14)
            text(0.98*xx(2),1.06*min(ydata),['p_{A|Age}=' num2str(pANCOVA_height_agr(1,ind),'%.3f') ],'HorizontalAlign','right','FontSize',14)
        end
    else
        text(0.98*xx(2),0.97*max(ydata),['r=' num2str(r_height_agr(1,ind),'%.3f') '; p=' num2str(p_r_height_agr(1,ind),'%.3f') ],'HorizontalAlign','right','FontSize',14)
        text(0.98*xx(2),0.93*max(ydata),['p_{A|Age}=' num2str(pANCOVA_height_agr(1,ind),'%.3f') ],'HorizontalAlign','right','FontSize',14)
    end
    hold off
    ylabel(['C4-C7 ' g_ylbl{ind,1}])
    axis([xx min(ydata) max(ydata)])
    grid on
    if ind < 9
        set(gca,'XTick',0:10:200,'XtickLabel','')
    else
        xlabel(xdata_names)
        set(gca,'XTick',0:10:200,'XtickLabel',0:10:200)
    end
    set(gca,'FontSize',14,'LineWidth',2)
    
    sbpl = sbpl + 5;
end

subplot(3,3,9)
plot([1.5 2.5],[0 0],'^','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
hold on
plot([1.5 2.5],[0 0],'o','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
plot([1.5 2.5],[0 0],'d','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
plot([1.5 2.5],[0 0],'x','Color','r','LineWidth',3,'MarkerSize',13)
hold off
legend('MPS I - Hurler syndrome','MPS I - Hurler-Scheie syndrome','MPS I - Scheie syndrome',...
    'MPS VI',...
    'Location','southwest')
set(gca,'FontSize',14,'LineWidth',2)
axis([-101 -100 -101 -100]);
axis off

print(fullfile(save_path,['graph' num2str(fgrs+11) '-height-aggregated-corr' ]),'-dpng','-r300')
pause(0.15)
close(h(fgrs+11).fig)
pause(0.1)
disp(num2str(fgrs+11))