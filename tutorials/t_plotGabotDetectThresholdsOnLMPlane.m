%% t_plotGaborDetectThresholdsOnLMPlane
%
% Read classification performance data generated by
%   t_colorGaborDetectFindPerformance
% 
% A) Plot the psychometric functions with a fit Weibull, which is used to find the threshold in each color direction.
% B) Plot the thresholds in the LM contrast plane.
% C) Fit an ellipse to the thresholds.
%
% The fit ellipse may be compared with actual psychophysical data.
%
% The intput comes from and the output goes into a place determined by
%   colorGaborDetectOutputDir
% which itself checks for a preference set by
%   ISETColorDetectPreferencesTemplate
% which you may want to edit before running this and other scripts that
% produce substantial output.  The output within the main output directory
% is sorted by directories whose names are computed from parameters.  This
% naming is done in routine
%   paramsToDirName.
% 
% 7/11/16  npc Wrote it.
% 7/13/16  dhb More.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

% Some plotting parameters
markerSize = 12;
labelFontSize = 16;
titleFontSize = 16;
axisFontSize = 12;

%% Read the output of t_colorGaborDetectFindPerformance
conditionDir = 'cpd2_sfv1.00_fw0.350_tau0.165_dur0.33_nem0_use50_off35_b1_l1_LMS0.62_0.31_0.07_mfv1.00';

%% Define parameters of analysis
%
% Signal source: select between 'photocurrents' and 'isomerizations'
signalSource = 'isomerizations';

% Number of SVM cross validations to use
kFold = 5;

% PCA components.  Set to zero for no PCA
PCAComponents = 200;

dataDir = colorGaborDetectOutputDir(conditionDir,'output');
classificationPerformanceFile = fullfile(dataDir, sprintf('ClassificationPerformance_%s_kFold%0.0f_pca%0.0f.mat',signalSource,kFold,PCAComponents));
pdfBaseFile = sprintf('%s_kFold%0.0f_pca%0.0f',signalSource,kFold,PCAComponents));
fprintf('\nLoading data from %s ...', classificationPerformanceFile);
figureDir = colorGaborDetectOutputDir(conditionDir,'figures');
theData = load(fullfile(dataDir,classificationPerformanceFile));

% Extract data from loaded struct into convenient form
testContrasts = theData.testContrasts;
testConeContrasts = theData.testConeContrasts;
nTrials = theData.nTrials;
fitContrasts = linspace(0,1,100)';
thresholdCriterionFraction = 0.75;

% Make sure S cone component of test contrasts is 0, because in this
% routine we are assuming that we are just looking in the LM plane.
if (any(testConeContrasts(3,:) ~= 0))
    error('This tutorial only knows about the LM plane');
end

%% Fit psychometric functions
%
% And make a plot of each along with its fit
hFig = figure(1); clf;
set(hFig, 'Position', [10 10 1600 1000], 'Color', [1 1 1]);
for ii = 1:size(theData.testConeContrasts,2)
    % Get the performance data for this test direction, as a function of
    % contrast.
    thePerformance = squeeze(theData.percentCorrect(ii,:));
    theStandardError = squeeze(theData.stdErr(ii, :));
    
    % Fit psychometric function and find threshold.
    %
    % The work is done by singleThresholdExtraction, which itself calls the
    % Palemedes toolbox.  The Palemedes toolbox is included in the external
    % subfolder of the Isetbio distribution.
    [tempThreshold,fitFractionCorrect(:,ii),psychometricParams{ii}] = ...
       singleThresholdExtraction(testContrasts,thePerformance,thresholdCriterionFraction,nTrials,fitContrasts);
    thresholdContrasts(ii) = tempThreshold;
    
    % Make the plot for this test direction
    subplot(2, ceil(size(testConeContrasts,2)/2), ii); hold on; set(gca,'FontSize',axisFontSize);
    errorbar(testContrasts, thePerformance, theStandardError, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.5 0.50]);
    plot(fitContrasts,fitFractionCorrect(:,ii),'r','LineWidth', 2.0);
    plot(thresholdContrasts(ii)*[1 1],[0 thresholdCriterionFraction],'b', 'LineWidth', 2.0);
    hold off;
    axis 'square'
    set(gca, 'YLim', [0 1.0],'XLim', [testContrasts(1) testContrasts(end)], 'FontSize', 14);
    xlabel('contrast', 'FontSize' ,labelFontSize, 'FontWeight', 'bold');
    ylabel('percent correct', 'FontSize' ,labelFontSize, 'FontWeight', 'bold');
    box off; grid on
    title(sprintf('LMangle = %2.1f deg', atan2(testConeContrasts(2,ii), testConeContrasts(1,ii))/pi*180),'FontSize',titleFontSize);
    
    % Convert threshold contrast to threshold cone contrasts
    thresholdConeContrasts(:,ii) = testConeContrasts(:,ii)*thresholdContrasts(ii);
end
if (exist('FigureSave','file'))
    FigureSave(fullfile(figureDir,sprintf('LMPsychoFunctions_%s',pdfBaseFile)),hFig,'pdf');
end

%% Thresholds are generally symmetric around the contrast origin
%
% We'll pad with this assumption, which makes both visualization and
% fitting easier.
thresholdConeContrasts = [thresholdConeContrasts -thresholdConeContrasts];

% Remove any NaN thresholds lurking around, as these will mess up attempts
% to fit.
thresholdConeContrastsForFitting0 = [];
for ii = 1:size(thresholdConeContrasts,2)
    if (~any(isnan(thresholdConeContrasts(:,ii))))
        thresholdConeContrastsForFitting0 = [thresholdConeContrastsForFitting0 thresholdConeContrasts(:,ii)];
    end
end

%% Fit ellipse
%
% This method fits a 3D ellipsoid and extracts the LM plane of
% the fit.
%
% The fit will be very bad off the LM plane, since there are no data there.
% But we don't care, because we are only going to look at the fit in the LM
% plane.  To make the fit stable, we generate data for fitting that are off
% the LM plane by simply producing shrunken and shifted copies of the in
% plane data.  A little klugy.
thresholdConeContrastsForFitting1 = 0.5*thresholdConeContrastsForFitting0;
thresholdConeContrastsForFitting1(3,:) = 0.5;
thresholdConeContrastsForFitting2 = 0.5*thresholdConeContrastsForFitting0;
thresholdConeContrastsForFitting2(3,:) = -0.5;
thresholdContrastsForFitting = [thresholdConeContrastsForFitting0 thresholdConeContrastsForFitting1 thresholdConeContrastsForFitting2];
[fitA,fitAinv,fitQ,fitEllParams] = EllipsoidFit(thresholdContrastsForFitting);

% Get the LM plane ellipse from the fit
nThetaEllipse = 200;
circleIn2D = UnitCircleGenerate(nThetaEllipse);
circleInLMPlane = [circleIn2D(1,:) ; circleIn2D(2,:) ; zeros(size(circleIn2D(1,:)))];
ellipsoidInLMPlane = PointsOnEllipsoidFind(fitQ,circleInLMPlane);

%% Plot the thresholds in the LM contrast plane
contrastLim = 0.06;
figure; clf; hold on; set(gca,'FontSize',axisFontSize);
plot(thresholdConeContrasts(1,:),thresholdConeContrasts(2,:),'ro','MarkerFaceColor','r','MarkerSize',markerSize);
plot(ellipsoidInLMPlane(1,:),ellipsoidInLMPlane(2,:),'r','LineWidth',2);
plot([-contrastLim contrastLim],[0 0],'k:','LineWidth',2);
plot([0 0],[-contrastLim contrastLim],'k:','LineWidth',2);
xlabel('L contrast','FontSize',labelFontSize); ylabel('M contrast','FontSize',labelFontSize);
title('M versus L','FontSize',titleFontSize);
xlim([-contrastLim contrastLim]); ylim([-contrastLim contrastLim]);
axis('square');
if (exist('FigureSave','file'))
    FigureSave(fullfile(figureDir,sprintf('LMThresholdContour_%s',pdfBaseFile)),gcf,'pdf');
end
    

