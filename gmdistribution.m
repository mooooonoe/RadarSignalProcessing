clc;
close all;
clear;


mu = [1 2;-3 -5];
sigma = cat(3,[2 .5],[1 1]) % 1-by-2-by-2 array

gm = gmdistribution(mu,sigma)
properties(gm)

gm.ComponentProportion

gm.NegativeLogLikelihood

figure();
gmPDF = @(x,y) arrayfun(@(x0,y0) pdf(gm,[x0 y0]),x,y);
fsurf(gmPDF,[-10 10]);


%%
mu1 = [1 2];          % Mean of the 1st component
sigma1 = [2 0; 0 .5]; % Covariance of the 1st component
mu2 = [-3 -5];        % Mean of the 2nd component
sigma2 = [1 0; 0 1];  % Covariance of the 2nd component

rng('default') % For reproducibility
r1 = mvnrnd(mu1,sigma1,1000);
r2 = mvnrnd(mu2,sigma2,1000);
X = [r1; r2];

gm = fitgmdist(X,2)

properties(gm)

gm.NegativeLogLikelihood

figure();
scatter(X(:,1),X(:,2),10,'.') % Scatter plot with points of size 10
hold on
gmPDF = @(x,y) arrayfun(@(x0,y0) pdf(gm,[x0 y0]),x,y);
fcontour(gmPDF,[-8 6]);