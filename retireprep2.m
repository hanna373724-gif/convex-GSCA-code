%% BN-ready GSCA code for Retirement Preparation Vulnerability
% Middle-aged adults: multidimensional life domains -> retirement preparation
% Requires GSCA Prime package

clear; clc;
disp("=== 초기화 완료 ===")

%% Step 0. Import data
Data_full = readtable("retry_BN.csv");
disp("=== step0. 완료 ===")

%% Step 0-1. Create retirement preparation score
% prep1-prep4의 평균 점수 사용
prep_items = {'prep1','prep2','prep3','prep4'};

Data_full.retire_prep_score = mean(Data_full{:, prep_items}, 2, 'omitnan');
disp("=== step 0-1. 완료 ===")

%% Step 0-2. Dichotomize retirement preparation by bottom 30%
% 하위 30% = 취약집단(1), 나머지 = 비취약집단(0)
cut30_retire = prctile(Data_full.retire_prep_score, 30);

Data_full.retire_prep = double(Data_full.retire_prep_score <= cut30_retire);

% 문자형 라벨도 함께 생성
Data_full.retire_prep_label = strings(height(Data_full),1);
Data_full.retire_prep_label(Data_full.retire_prep == 1) = "vulnerable";
Data_full.retire_prep_label(Data_full.retire_prep == 0) = "unvulnerable";
disp("=== step 0-2. 완료 ===")

%% Step 1. Select variables for GSCA
vars = {'phys2','phys3','phys4','phys5', ...
'bhv1','bhv2','bhv3','bhv4','bhv5','bhv6', ...
'chg1','chg2','chg3','chg4', ...
'view1','view2','view3','view4','view5', ...
'cog1','cog2','cog3','cog4','cog5','cog6','cog7', ...
'accept1','accept2','accept3','accept4','accept5','accept6', ...
'mental1','mental2','mental3','mental4','mental5','mental6','mental7','mental8','mental9', ...
'ewb1','ewb2','ewb3', ...
'est1','est2','est3','est4','est5','est6','est7','est8','est9','est10', ...
'fam1','fam2','fam3','fam4','fam5', ...
'care1','care2','care3','care4', ...
'rel2','rel4','rel5','rel6', ...
'satis1','satis2','satis3', ...
'actstr1','actstr2','actstr3', ...
'econ1','econ2','econ3', ...
'workbal1','workbal2','workbal3', ...
'area1','area2','area3','area4','area5','area6','area7','area8','area10', ...
'access1','access2','access3','access4','access5','access6','access7', ...
'policy1','policy2','policy3'};

Z = Data_full(:, vars);
disp("=== step 1. 완료 ===")

%% Step 2. Specify 1st-order model
% 19개 하위요인
% 1 phys
% 2 bhv
% 3 chg
% 4 view
% 5 cog
% 6 accept
% 7 mental
% 8 ewb
% 9 est
% 10 fam
% 11 care
% 12 rel
% 13 satis
% 14 actstr
% 15 econ
% 16 workbal
% 17 area
% 18 access
% 19 policy

N_ind_per_CV = [4; 6; 4; 5; 7; 6; 9; 3; 10; 5; 4; 4; 3; 3; 3; 3; 9; 7; 3];
J = sum(N_ind_per_CV);      % number of observed variables
P1 = size(N_ind_per_CV,1);  % number of 1st-order components

Model.o1.W0 = zeros(J,P1);
ed = cumsum(N_ind_per_CV);
st = [1; ed(1:end-1)+1];
for p = 1:P1
    Model.o1.W0(st(p):ed(p),p) = 1;
end

% 같은 상위차원에 속하는 하위요인끼리 같은 scale type 부여
Model.o1.Type_ScaleCV = [1,1,1, 2,2,2, 3,3,3, 4,4,4, 5,5,5,5, 6,6,6];

Model.o1.TypeCV_Predefined = num2cell(zeros(1,P1));
Model.o1.C0 = Model.o1.W0';
disp("=== step 2. 완료 ===")

%% plus. 하위요인 개수, 전체 문항수, scale type 개수 확인
size(N_ind_per_CV)
sum(N_ind_per_CV)
length(Model.o1.Type_ScaleCV)

%% Step 3. Specify 2nd-order model
% 6개 차원
% phys_D      = phys, bhv, chg
% cog_D       = view, cog, accept
% psy_D       = mental, ewb, est
% soc_D       = fam, care, rel
% workeco_D   = satis, actstr, econ, workbal
% env_D       = area, access, policy

P2 = 6;

Model.o2.W0 = blkdiag( ...
    ones(3,1), ...  % phys_D
    ones(3,1), ...  % cog_D
    ones(3,1), ...  % psy_D
    ones(3,1), ...  % soc_D
    ones(4,1), ...  % workeco_D
    ones(3,1)  ...  % env_D
);

Model.o2.TypeCV_Scale = [1,2,3,4,5,6];
Model.o2.TypeCV_Predefined = {0,0,0,0,0,0};

Model.o2.C0 = blkdiag( ...
    ones(1,3), ones(1,3), ones(1,3), ...
    ones(1,3), ones(1,4), ones(1,3) ...
);

Model.o2.B0 = zeros(P2,P2);
disp("=== step 3. 완료 ===")

%% Step 4. Estimation options
clear Est
 
% 1차 모델용 (플랫 구조체)
Est.o1 = struct;
Est.o1.N_Boot    = 20;
Est.o1.Max_iter  = 100;
Est.o1.Min_limit = 1e-5;
Est.o1.Forcing_W = false;
Est.o1.Eval      = true;
Est.o1.save_ETC = true;
Est.o1.Name_OV   = string(Z.Properties.VariableNames);
Est.o1.Name_CV   = [ ...
    "phys","bhv","chg", ...
    "view","cog","accept", ...
    "mental","ewb","est", ...
    "fam","care","rel", ...
    "satis","actstr","econ","workbal", ...
    "area","access","policy" ...
];
 
% 2차 모델용 (플랫 구조체)
Est.o2 = struct;
Est.o2.N_Boot    = 20;
Est.o2.Max_iter  = 100;
Est.o2.Min_limit = 1e-5;
Est.o2.Forcing_W = false;
Est.o2.Eval      = true;
Est.o2.save_ETC = true;
Est.o2.Name_CV   = [ ...
    "phys_D","cog_D","psy_D","soc_D","workeco_D","env_D" ...
];
 

disp("=== step 4. 완료 ===")

%% Step 5. Run GSCA
Results = gsca.fit(Z{:,:}, Model, Est);
disp("=== step 5. 완료 ===")

%% Step 6. Review results
gsca.summary(Results);
disp("=== step 6. 완료 ===")

%% Step 7. Extract scores
% 1차 하위요인 점수
Data_S1 = Results.INI(1).CVscore;

% 2차 차원 점수
Data_S2 = Results.INI(2).CVscore;
disp("=== step 7. 완료 ===")

%% Step 8. Categorize subfactor and dimension scores into Low / Mid / High

% ----------------------------
% 8-1. Subfactor scores (1st-order)
% ----------------------------
sub_names = {'phys','bhv','chg', ...
             'view','cog','accept', ...
             'mental','ewb','est', ...
             'fam','care','rel', ...
             'satis','actstr','econ','workbal', ...
             'area','access','policy'};

for i = 1:length(sub_names)
    x = Data_S1.(sub_names{i});

    p33 = prctile(x, 33.33);
    p67 = prctile(x, 66.67);

    cat = strings(length(x),1);
    cat(x <= p33) = "Low";
    cat(x > p33 & x <= p67) = "Mid";
    cat(x > p67) = "High";

    Data_S1.(strcat(sub_names{i}, '_cat')) = cat;
end

% ----------------------------
% 8-2. Dimension scores (2nd-order)
% ----------------------------
dim_names = {'phys_D','cog_D','psy_D','soc_D','workeco_D','env_D'};

for i = 1:length(dim_names)
    x = Data_S2.(dim_names{i});

    p33 = prctile(x, 33.33);
    p67 = prctile(x, 66.67);

    cat = strings(length(x),1);
    cat(x <= p33) = "Low";
    cat(x > p33 & x <= p67) = "Mid";
    cat(x > p67) = "High";

    Data_S2.(strcat(dim_names{i}, '_cat')) = cat;
end
disp("=== step 8. 완료 ===")

%% Step 9. Create BN input dataset
Data_BN_full = [ ...
    Data_S1, ...
    Data_S2, ...
    Data_full(:, {'retire_prep_score','retire_prep','retire_prep_label'}) ...
];
disp("=== step 9. 완료 ===")

%% Step 10. Save output files
writetable(Data_S1, "subfactor_scores.csv");
writetable(Data_S2, "dimension_scores.csv");
writetable(Data_BN, "retirement_BN_input.csv");
disp("=== step 10. 완료 ===")

%% Step 11. Quick check
disp("=== Frequency of retire_prep ===");
disp(tabulate(Data_full.retire_prep));

disp("=== Summary of retire_prep_score ===");
disp(summary(Data_full.retire_prep_score));

disp("=== Saved files ===");
disp("1) subfactor_scores.csv");
disp("2) dimension_scores.csv");
disp("3) retirement_BN_input.csv");
disp("=== step 11. 완료 ===")