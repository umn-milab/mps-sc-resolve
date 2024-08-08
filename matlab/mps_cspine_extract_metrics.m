clear all; clc; close all;
data_folder='/home/range1-raid1/labounek/data-on-porto';
project_folder=fullfile(data_folder,'MPS','cspine_resolve');
xls_file = fullfile(project_folder,'results','cspine_resolve.xlsx');
save_path = fullfile(project_folder,'pictures','graphs-20240716');
pvaladjust_file = fullfile(project_folder,'results','pvaladjust-20240716.mat');
dmripreproc='topup-eddy';
roidefinition='level-specific';

addpath('/home/range1-raid1/labounek/toolbox/matlab/spm12');

clr_hc = [0 0.749 1];
clr_mpsi = [1 1 1]*0.4;
clr_mpsvi = [255 0 0]/255;
clr_stats = [0 220 0]/255;

% load(pvaladjust_file)
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

measurement_ind = [11:12 15:17 19 18];
measurement = cell2mat(raw(3:end,measurement_ind));
measurement_names = raw(1,measurement_ind);

sex=raw(3:end,3);
height = [raw{3:end,8}]';
weight = [raw{3:end,9}]';
age = [raw{3:end,10}]';

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
                vls(level,:) = tmp;
            end
        end
    end
%     vls = reshape(vls,1,size(vls,1)*size(vls,2));
    data(ind,:,1:size(morpho_pos,2)) = vls;
    
    for dmriid = 1:size(dmri_metrics,2)
        dmri_file = fullfile(project_folder,'results','tables',[sessid{ind,1} '_' dmri_metrics{1,dmriid} '_' roidefinition '_' dmripreproc '.csv']);
        vls = ones(1,nlevels)*NaN;
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
                    vls(1,level) = tmp;
                end
            end
        end
        vls(vls==0) = NaN;
        data(ind,:,size(morpho_pos,2)+dmriid) = vls;
    end
end

subidunique=unique(subid);
glbmean = squeeze(nanmean(data));
glbstd = squeeze(nanstd(data));

xmin = -0.5;
xmax = 3.5;

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
    xmin xmax 0.35 1.2
    xmin xmax 0.8 1.5
    ];

tbl=cell(1,1);
for idx = 1:size(data_names,2)
    tbl{1,3+5*(idx-1)} = data_names(1,idx);
    tbl{2,3+5*(idx-1)} = 'Mean';
    tbl{2,4+5*(idx-1)} = 'STD';
    tbl{2,5+5*(idx-1)} = 'p / diff [%]';
    tbl{2,6+5*(idx-1)} = 'pAW';
    tbl{2,7+5*(idx-1)} = 'pAH';
end

for idx = 1:nlevels
    tbl{3+2*(idx-1),1} = data_names{1,idx};
    tbl{3+2*(idx-1),1} = ['C' num2str(idx)];
    tbl{3+2*(idx-1),2} = 'Control';
    tbl{4+2*(idx-1),2} = 'MPS';
end

mri_corr = zeros(size(subidunique,1),size(data,3)*nlevels);
mri_corr_names = cell(1,1);
mriind=1;
h = struct([]);
for varind = 1:size(data,3)
    h(varind).fig = figure(varind);
    set(h(varind).fig,'Position',[1050 50 900 1200])
    
    for level = 1:nlevels
        lthr = glbmean(level,varind) - 3.2*glbstd(level,varind);
        uthr = glbmean(level,varind) + 3.2*glbstd(level,varind);
        subplot(4,2,level)
        yhc = data(grp==-1,level,varind);
        yhc(yhc<lthr) = NaN;
        yhc(yhc>uthr) = NaN;
        yhc(yhc==0) = [];
        yhc(isnan(yhc)) = [];
        yhc_mean = mean(yhc);
        yhc_std = std(yhc);
        plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',clr_stats,'LineWidth',5)
        hold on
        plot([-0.4 0.4],[yhc_mean-yhc_std yhc_mean-yhc_std],'-.','Color',clr_stats,'LineWidth',3)
        plot([-0.4 0.4],[yhc_mean+yhc_std yhc_mean+yhc_std],'-.','Color',clr_stats,'LineWidth',3)
        td = zeros(size(subidunique,1),1);
        if varind==1 && level==1
            tg = zeros(size(subidunique,1),1);
            td_age = zeros(size(subidunique,1),1);
            td_height = zeros(size(subidunique,1),1);
            td_weight = zeros(size(subidunique,1),1);
            td_female = zeros(size(subidunique,1),1);
            grp_anova=zeros(size(subidunique,1),1);
        end
        for sb = 1:size(subidunique,1)
            ps=strcmp(subid,subidunique{sb,1});
            y = data(ps,level,varind);
            y(y<lthr) = NaN;
            y(y>uthr) = NaN;
            gr = grp(ps);
            td(sb)=nanmean(y);
            if varind==1 && level==1
                sx=sex(ps);
                tg(sb)=gr(1);
                td_age(sb)=nanmean(age(ps));
                td_height(sb)=nanmean(height(ps));
                td_weight(sb)=nanmean(weight(ps));
                if strcmp(sx{1,1},'F')
                    td_female(sb)=1;
                end
            end
        end
        if varind==1 && level==1
            grp_anova(tg~=-1)=1;
        end
%         if level==3 && varind == 5
%             disp('yes')
%         end
        ymps = td(tg~=-1);
        ymps(ymps<lthr) = NaN;
        ymps(ymps>uthr) = NaN;
        ymps(ymps==0) = [];
        ymps(isnan(ymps)) = [];
        ymps_mean = nanmean(ymps);
        ymps_std = nanstd(ymps);
        plot([0.6 3.4],[ymps_mean ymps_mean],'Color',clr_stats,'LineWidth',5)
        plot([0.6 3.4],[ymps_mean-ymps_std ymps_mean-ymps_std],'-.','Color',clr_stats,'LineWidth',3)
        plot([0.6 3.4],[ymps_mean+ymps_std ymps_mean+ymps_std],'-.','Color',clr_stats,'LineWidth',3)
        for sb = 1:size(subidunique,1)
            ps=strcmp(subid,subidunique{sb,1});

            y = data(ps,level,varind);
            y(y<lthr) = NaN;
            y(y>uthr) = NaN;
            gr = grp(ps);
            if gr(1)==-1
                clr=clr_hc;
                mrk = ':^';
                time = 0;
            elseif gr(1) == 6
                clr=clr_mpsvi;
                mrk = ':x';
                time=visit(ps,1);
            else
                clr=clr_mpsi;
                mrk = ':o';
                time=visit(ps,1);
            end
            if gr(1) ~= -1
                plot(time,y,mrk,'Color',clr,'LineWidth',3,'MarkerSize',9)
            else
                plot(time+randn(size(time))*0.1,y,mrk,'Color',clr,'LineWidth',2,'MarkerSize',9)
            end
            
%             if strcmp(subidunique{sb},'2MPS1047') % || strcmp(subidunique{sb},'2MPS1038') || strcmp(subidunique{sb},'2MPS1058') % || strcmp(subidunique{sb},'2MPS1015') %|| strcmp(subidunique{sb},'2MPS1037')
%                 text(time(1)+0.1,y(1),subidunique{sb}(2:end))
%             end
        end
        
        [~, pT(level,varind)]=ttest2(td(tg==-1),td(tg>0));
        pW(level,varind)=ranksum(td(tg==-1),td(tg>0));
        p_tmp = anovan(td,{grp_anova,td_weight},'Continuous',2,'varnames',{'Group','confounder'},'display','off');
        pANCOVA_weight(level,varind)= p_tmp(1);
        p_tmp = anovan(td,{grp_anova,td_height},'Continuous',2,'varnames',{'Group','confounder'},'display','off');
        pANCOVA_height(level,varind)= p_tmp(1);
        p_tmp = anovan(td,{grp_anova,td_female},'Continuous',2,'varnames',{'Group','confounder'},'display','off');
        pANCOVA_sex(level,varind)= p_tmp(1);
        [~, pT_sexHC(level,varind)]=ttest2(td(tg==-1 & td_female==1),td(tg==-1 & td_female==0));
        [~, pT_sex(level,varind)]=ttest2(td(td_female==1),td(td_female==0));
%         if pT(level,varind)<0.05 || pW(level,varind)<0.05
%             text(xmin+0.2,axismat(varind,3)+0.1*(axismat(varind,4)-axismat(varind,3)),['p_t=' num2str(pT(level,varind)) '; p_W=' num2str(pW(level,varind))],'FontSize',12)
%         end
        if pTadj(level,varind) < 0.05
            plot(1.2,axismat(varind,4)-0.15*(axismat(varind,4)-axismat(varind,3)),'k+','MarkerSize',11,'LineWidth',3)
            if pANCOVA_weight(level,varind) < 0.05
                plot(1.47,axismat(varind,4)-0.15*(axismat(varind,4)-axismat(varind,3)),'k>','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
            if pANCOVA_height(level,varind) < 0.05
                plot(1.8,axismat(varind,4)-0.15*(axismat(varind,4)-axismat(varind,3)),'ks','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
            if pANCOVA_sex(level,varind) < 0.05
                plot(2.15,axismat(varind,4)-0.15*(axismat(varind,4)-axismat(varind,3)),'kd','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
            end
        end
        hold off
        axis(axismat(varind,:))
        ylabel(['C' num2str(level)])
        grid on
        if level <= nlevels-2
            set(gca,'FontSize',14,'LineWidth',2,'xtick',0:3,'xticklabel',{' ' ' ' ' ' ' '})
        else
            set(gca,'FontSize',14,'LineWidth',2,'xtick',0:3,'xticklabel',{'Control' 'Visit 1' 'Visit 2' 'Visit 3'})
        end
        
        mri_corr(:,mriind) = td;
        mri_corr_names{1,mriind} = ['C' num2str(level) '-' data_names{1,varind}];
        mriind = mriind + 1;
        
        tbl{3+2*(level-1),3+5*(varind-1)} = nanmean(td(tg==-1));
        tbl{3+2*(level-1),4+5*(varind-1)} = nanstd(td(tg==-1));
        tbl{3+2*(level-1),5+5*(varind-1)} = pTadj(level,varind);
        tbl{3+2*(level-1),6+5*(varind-1)} = pANCOVA_weight(level,varind);
        tbl{3+2*(level-1),7+5*(varind-1)} = pANCOVA_height(level,varind);
        tbl{4+2*(level-1),3+5*(varind-1)} = nanmean(td(tg>0));
        tbl{4+2*(level-1),4+5*(varind-1)} = nanstd(td(tg>0));   
        if tbl{3+2*(level-1),5+5*(varind-1)} < 0.05
            tmp = 100 * (tbl{4+2*(level-1),3+5*(varind-1)} - tbl{3+2*(level-1),3+5*(varind-1)}) / tbl{3+2*(level-1),3+5*(varind-1)};
            if tmp < 0
                tbl{4+2*(level-1),5+5*(varind-1)} = [num2str(tmp,'%.2f') '%'];
            else
                tbl{4+2*(level-1),5+5*(varind-1)} = ['+' num2str(tmp,'%.2f') '%'];
            end
        end
    end
    
    subplot(4,2,8)
    plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',clr_stats,'LineWidth',5)
    hold on
    plot([-0.4 0.4],[yhc_std yhc_std],'-.','Color',clr_stats,'LineWidth',3)
    plot(0,0,'^','Color',clr_hc,'LineWidth',3,'MarkerSize',13)
    plot([0.5 1.5],[0 0],':o','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
    plot([1.5 2.5],[0 0],':x','Color',clr_mpsvi,'LineWidth',3,'MarkerSize',13)
    plot(1,1,'+','Color','k','LineWidth',3,'MarkerSize',11)
    plot(1,1,'>','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
    plot(1,1,'s','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
    plot(1,1,'d','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
    hold off
    legend('Mean','± Standard deviation','Healthy control','MPS I','MPS VI','Two-sample t-test (p_{BH}<0.05)',...
        'ANCOVA (Conf: Weight; p<0.05)','ANCOVA (Conf: Height; p<0.05)','ANCOVA (Conf: Sex; p<0.05)',...
        'Location','northwest')
    set(gca,'FontSize',14,'LineWidth',2)
    axis([-101 -100 -101 -100]);
    axis off
    
%     set(gcf,'NextPlot','add');
%     axes;
%     ht = title(data_names{1,varind},'FontSize',18);
%     set(gca,'Visible','off');
%     set(ht,'Visible','on');
    
    
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
demographics{3,2}=sum(tg==-1);
demographics{3,4}=sum(tg~=-1);
demographics{4,1}='Females';
demographics{4,2}=sum(td_female(tg==-1));
demographics{4,4}=sum(td_female(tg~=-1));

demographics{5,1}='Age [y.o.]';
demographics{5,2}=mean(td_age(tg==-1));
demographics{5,3}=std(td_age(tg==-1));
demographics{5,4}=mean(td_age(tg~=-1));
demographics{5,5}=std(td_age(tg~=-1));
[~, demographics{5,6}] = ttest2(td_age(tg==-1),td_age(tg~=-1));

demographics{6,1}='Height [cm]';
demographics{6,2}=mean(td_height(tg==-1));
demographics{6,3}=std(td_height(tg==-1));
demographics{6,4}=mean(td_height(tg~=-1));
demographics{6,5}=std(td_height(tg~=-1));
[~, demographics{6,6}] = ttest2(td_height(tg==-1),td_height(tg~=-1));

demographics{7,1}='Weight [kg]';
demographics{7,2}=mean(td_weight(tg==-1));
demographics{7,3}=std(td_weight(tg==-1));
demographics{7,4}=mean(td_weight(tg~=-1));
demographics{7,5}=std(td_weight(tg~=-1));
[~, demographics{7,6}] = ttest2(td_weight(tg==-1),td_weight(tg~=-1));
%%
measurement_corr = zeros(size(subidunique,1),size(measurement,2));
measind=1;
fgrs = varind+1;
sblpos = 1;
h(fgrs).fig = figure(fgrs);
set(h(fgrs).fig,'Position',[150 50 1800 800])
for varind = 1:size(measurement,2)
    subplot(2,4,sblpos)
    if varind ~= 3
        sblpos = sblpos + 1;
    else
        sblpos = sblpos + 2;
    end
    
    yhc = measurement(grp==-1,varind);
    yhc(yhc==0) = [];
    yhc(isnan(yhc)) = [];
    yhc_mean = mean(yhc);
    yhc_std = std(yhc);
    plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',clr_stats,'LineWidth',5)
    hold on
    plot([-0.4 0.4],[yhc_mean-yhc_std yhc_mean-yhc_std],'-.','Color',clr_stats,'LineWidth',3)
    plot([-0.4 0.4],[yhc_mean+yhc_std yhc_mean+yhc_std],'-.','Color',clr_stats,'LineWidth',3)
    td = zeros(size(subidunique,1),1);
    tg = zeros(size(subidunique,1),1);
    for sb = 1:size(subidunique,1)
        ps=strcmp(subid,subidunique{sb,1});
        y = measurement(ps,varind);
        gr = grp(ps);
        td(sb)=nanmean(y);
        tg(sb)=gr(1);
    end
%         if level==3 && varind == 5
%             disp('yes')
%         end
    ymps = td(tg~=-1);
    ymps(ymps==0) = [];
    ymps(isnan(ymps)) = [];
    ymps_mean = mean(ymps);
    ymps_std = std(ymps);
    plot([0.6 3.4],[ymps_mean ymps_mean],'Color',clr_stats,'LineWidth',5)
    plot([0.6 3.4],[ymps_mean-ymps_std ymps_mean-ymps_std],'-.','Color',clr_stats,'LineWidth',3)
    plot([0.6 3.4],[ymps_mean+ymps_std ymps_mean+ymps_std],'-.','Color',clr_stats,'LineWidth',3)
 
    td = zeros(size(subidunique,1),1);
    tg = zeros(size(subidunique,1),1);
    
    for sb = 1:size(subidunique,1)
        ps=strcmp(subid,subidunique{sb,1});
        
        y = measurement(ps,varind);
        
        gr = grp(ps);
        if gr(1)==-1
            clr=clr_hc;
            mrk = ':^';
            time = 0;
        elseif gr(1) == 6
            clr=clr_mpsvi;
            mrk = ':x';
            time=visit(ps,1);
        else
            clr=clr_mpsi;
            mrk = ':o';
            time=visit(ps,1);
        end
        if gr(1) ~= -1
            plot(time,y,mrk,'Color',clr,'LineWidth',3,'MarkerSize',9)
        else
            plot(time+randn(size(time))*0.1,y,mrk,'Color',clr,'LineWidth',2,'MarkerSize',9)
        end
        
%         if strcmp(subidunique{sb},'2MPS1047') % || strcmp(subidunique{sb},'2MPS1038') || strcmp(subidunique{sb},'2MPS1058') % || strcmp(subidunique{sb},'2MPS1015') %|| strcmp(subidunique{sb},'2MPS1037')
%             text(time(1)+0.1,y(1),subidunique{sb}(2:end))
%         end
        td(sb)=nanmean(y);
        tg(sb)=gr(1);
    end
    
    [~, pT_measurement(1,varind)]=ttest2(td(tg==-1),td(tg>0));
    pW_measurement(1,varind)=ranksum(td(tg==-1),td(tg>0));
    p_tmp = anovan(td,{grp_anova,td_weight},'Continuous',2,'varnames',{'Group','confounder'},'display','off');
    pANCOVA_weight_measurement(1,varind)= p_tmp(1);
    p_tmp = anovan(td,{grp_anova,td_height},'Continuous',2,'varnames',{'Group','confounder'},'display','off');
    pANCOVA_height_measurement(1,varind)= p_tmp(1);
    p_tmp = anovan(td,{grp_anova,td_female},'Continuous',2,'varnames',{'Group','confounder'},'display','off');
    pANCOVA_sex_measurement(1,varind)= p_tmp(1);
%     if pT_measurement(1,varind)<0.05 || pW_measurement(1,varind)<0.05
%         text(xmin+0.2,max(td)-0.05*(max(td)-min(td)),['p_t=' num2str(pT_measurement(1,varind)) '; p_W=' num2str(pW_measurement(1,varind))],'FontSize',12)
%     end
    if pTadj_measurement(1,varind) < 0.05
%         plot(1.5,max(td)-0.04*(max(td)-min(td)),'k*','MarkerSize',16,'LineWidth',3)
        if varind <= 4
            cf = 1.10;
        else
            cf = 0.95;
        end
        plot(1.2,cf*max(td),'k+','MarkerSize',11,'LineWidth',3)
        if pANCOVA_weight_measurement(1,varind) < 0.05
            if varind <= 4
                cf = 1.10;
            else
                cf = 0.95;
            end
            plot(1.47,cf*max(td),'k>','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
        end
        if pANCOVA_height_measurement(1,varind) < 0.05
            if varind <= 4
                cf = 1.10;
            else
                cf = 0.95;
            end
            plot(1.8,cf*max(td),'ks','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
        end
        if pANCOVA_sex_measurement(1,varind) < 0.05
            if varind <= 4
                cf = 1.10;
            else
                cf = 0.95;
            end
            plot(2.15,cf*max(td),'kd','MarkerSize',11,'LineWidth',2,'MarkerFaceColor','k')
        end
    end
    hold off
    ylabel(measurement_names{1,varind})
    xlim([xmin xmax])
    grid on
    if varind <= 3
        set(gca,'FontSize',14,'LineWidth',2,'xtick',0:3,'xticklabel',{' ' ' ' ' ' ' '})
    else
        set(gca,'FontSize',14,'LineWidth',2,'xtick',0:3,'xticklabel',{'Control' 'Visit 1' 'Visit 2' 'Visit 3'})
    end
    
    measurement_corr(:,measind) = td;
    measind = measind + 1;
end

subplot(2,4,4)
plot([-0.4 0.4],[yhc_mean yhc_mean],'Color',clr_stats,'LineWidth',5)
hold on
plot([-0.4 0.4],[yhc_std yhc_std],'-.','Color',clr_stats,'LineWidth',3)
plot(0,0,'^','Color',clr_hc,'LineWidth',3,'MarkerSize',13)
plot([0.5 1.5],[0 0],':o','Color',clr_mpsi,'LineWidth',3,'MarkerSize',13)
plot([1.5 2.5],[0 0],':x','Color',clr_mpsvi,'LineWidth',3,'MarkerSize',13)
plot(1,1,'+','Color','k','LineWidth',3,'MarkerSize',11)
plot(1,1,'>','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
plot(1,1,'s','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
plot(1,1,'d','Color','k','LineWidth',2,'MarkerSize',11,'MarkerFaceColor','k')
hold off
legend('Mean','± Standard deviation','Healthy control','MPS I','MPS VI','Two-sample t-test (p_{BH}<0.05)',...
    'ANCOVA (Conf: Weight; p<0.05)','ANCOVA (Conf: Height; p<0.05)','ANCOVA (Conf: Sex; p<0.05)',...
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
%% Cross-correlation analysis
data_corr = [mri_corr measurement_corr td_age td_height td_weight td_female];
tmp = measurement_names;
for ind = 1:size(tmp,2)-1
    tmp{ind}(end-4:end)=[];
end
data_corr_names = [mri_corr_names tmp 'Age' 'Height' 'Weight' 'Sex'];

[r_corr, p_corr] = corrcoef(data_corr,'Rows','pairwise');
r_corr = triu(r_corr);
p_corr = triu(p_corr);

[r_corr_control, p_corr_control] = corrcoef(data_corr(tg==-1,:),'Rows','pairwise');
r_corr_control = triu(r_corr_control);
p_corr_control = triu(p_corr_control);

%% Cross-correlation plot
[C, D] = meshgrid(1:size(r_corr,1)+1);

h(fgrs+1).fig = figure(fgrs+1);
set(h(fgrs+1).fig, 'Position', [10, 50, 2540, 1050]);
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
        plot3([grph*nlevels+1 grph*nlevels+1],[1 grph*nlevels+3.0],[1 1],'k','LineWidth',3)
        plot3([grph*nlevels-1.0 size(temp,1)],[grph*nlevels+1 grph*nlevels+1],[1 1],'k','LineWidth',3)
    end
    hold off
end
print(fullfile(save_path,['graph' num2str(fgrs+1) '-crosscorrelation']),'-dpng','-r300')
pause(0.15)
close(h(fgrs+1).fig)
pause(0.1)


h(fgrs+2).fig = figure(fgrs+2);
set(h(fgrs+2).fig, 'Position', [1255+10, 50, 2540, 1050]);
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
        plot3([grph*nlevels+1 grph*nlevels+1],[1 grph*nlevels+3.0],[1 1],'g','LineWidth',3)
        plot3([grph*nlevels-1.0 size(temp,1)],[grph*nlevels+1 grph*nlevels+1],[1 1],'g','LineWidth',3)
    end
    hold off
end
print(fullfile(save_path,['graph' num2str(fgrs+2) '-crosscorrelation-pvalue']),'-dpng','-r300')
pause(0.15)
close(h(fgrs+2).fig)
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

data_reduced_names = {'C17-CSA' 'C14-AP-diameter' 'C57-AP-diameter' 'C17-RL-diameter' 'C13-FA' 'C57-FA' 'C57-AD' 'C57-RD' 'CD' 'FM' 'CD:FM' 'PR' 'BDI' 'ADI' 'D2L' 'Height' 'Weight' 'Age' 'Sex'};
data_reduced=nanmean(data_corr(:,1:7),2);
data_reduced(:,2)=nanmean(data_corr(:,8:11),2);
data_reduced(:,3)=nanmean(data_corr(:,12:14),2);
data_reduced(:,4)=nanmean(data_corr(:,15:21),2);
data_reduced(:,5)=nanmean(data_corr(:,22:24),2);
data_reduced(:,6)=nanmean(data_corr(:,26:28),2);
data_reduced(:,7)=nanmean(data_corr(:,33:35),2);
data_reduced(:,8)=nanmean(data_corr(:,40:42),2);
data_reduced(:,9:15)=data_corr(:,[54:56 50:53]);
data_reduced(:,16)=td_height;
data_reduced(:,17)=td_weight;
data_reduced(:,18)=td_age;
data_reduced(:,19)=td_female;


[r_corr_reduced, p_corr_reduced] = corrcoef(data_reduced,'Rows','pairwise');
%% PCA and FACTORAN analysis
[coeff,latent,explained] = pcacov(r_corr_reduced);
% [coeff,score,latent,tsquared,explained,mu] = pca(fctrn);
explained_cumulative = cumsum(explained);

h(fgrs+3).fig = figure(fgrs+3);
set(h(fgrs+3).fig, 'Position', [10, 50, 2150, 800]);
subplot(1,2,1)
% biplot(coeff(:,[1 2]),'Scores',score(:,1:2),'VarLabels',data_reduced_names,'LineWidth',3,'MarkerSize',30)
bp=biplot(coeff(:,[1 2]),'VarLabels',data_reduced_names,'LineWidth',3,'MarkerSize',30);
for ind = 1:(size(bp,1)-1)
    if bp(ind).Color(3) == 1
        bp(ind).Color = [0 0.749 1];
        bp(ind).LineWidth = 4;
        bp(ind).MarkerSize = 40;
    else     
        bp(ind).FontSize = 13;
        bp(ind).FontWeight = 'bold';
        if bp(ind).Position(1) < 0
            bp(ind).HorizontalAlignment = 'right';
        end
        if bp(ind).Position(2) >= 0
            bp(ind).Position(2) = bp(ind).Position(2)+0.025;
        else
            bp(ind).Position(2) = bp(ind).Position(2)-0.025;
        end
        if strcmp(bp(ind).String,'ADI')
            bp(ind).Position(1) = bp(ind).Position(1)+0.040;
            bp(ind).Position(2) = bp(ind).Position(2)-0.005;
        end
        if strcmp(bp(ind).String,'Height')
            bp(ind).Position(1) = bp(ind).Position(1)+0.010;
            bp(ind).Position(2) = bp(ind).Position(2)-0.020;
        end
        if strcmp(bp(ind).String,'C13-FA')
            bp(ind).Position(2) = bp(ind).Position(2)-0.010;
        end
        if strcmp(bp(ind).String,'C57-FA')
            bp(ind).Position(1) = bp(ind).Position(1)+0.010;
            bp(ind).Position(2) = bp(ind).Position(2)+0.017;
        end
        if strcmp(bp(ind).String,'FM')
            bp(ind).Position(1) = bp(ind).Position(1)+0.010;
            bp(ind).Position(2) = bp(ind).Position(2)+0.010;
        end
%         if strcmp(bp(ind).String,'D2L')
%             bp(ind).Position(2) = bp(ind).Position(2)-0.025;
%         end
    end
end
bp(end).LineWidth=3;
% xlabel(['Component 1 [variability: ' num2str(round(explained(1,1)*100)/100) '%]'])
% ylabel(['Component 2 [variability: ' num2str(round(explained(2,1)*100)/100) '%]'])
title('PCA variable biplot projection')
set(gca,'FontSize',14,'LineWidth',2)

subplot(1,2,2)
plot(explained,'-','LineWidth',4,'Marker','.','MarkerSize',60,'Color',[0 0.749 1])
axis([1 size(data_reduced,2) 0 explained(1)+2])
grid on
xlabel('Component number')
ylabel('Explained variability [%]')
title('Variability explained per each component')
set(gca,'FontSize',14,'LineWidth',2)

print(fullfile(save_path,['graph' num2str(fgrs+3) '-pca']),'-dpng','-r300')
pause(0.15)
close(h(fgrs+3).fig)
pause(0.1)