addpath(genpath('./pvtools'));

pdataPath = './20220801_110450_AntiVCAM1_CTL_ID001_F_18mon_TP0_1_1/14/pdata/1';
out_fname = './20220801_110450_AntiVCAM1_CTL_ID001_F_18mon_TP0_1_1.mat';
recon(pdataPath, out_fname);