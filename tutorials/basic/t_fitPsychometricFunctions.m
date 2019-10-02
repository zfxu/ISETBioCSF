function [validationData, varargout] = t_fitPsychometricFunctions(varargin)
% Find Weibull thresholds in each color direction for previously found data
%
% Syntax:
%   validationData = t_fitPsychometricFuncions([varargin])
%
% Description:
%    Read classification performance data generated by
%        t_colorDetectFindPerformance
%
%    Plot the psychometric functions with a fit Weibull, which is used to
%    find the threshold in each color direction.
%
% Inputs:
%    None required.
%
% Outputs:
%    validationData   - Struct. A structure of validation data.
%    varargout        - (Optional) VARIES. Optional array of additional
%                       data in a cell array format.
%
% Optional key/value pairs:
%    rParams         - Struct. The rParams structure to use. Default empty,
%                      which uses defaults produced by generation function.
%    instanceParams  - Struct. The instanceParams structure to use. Default
%                      empty, which uses generation function defaults.
%    thresholdParams - Struct. The thresholdParams structure to use.
%                      Default empty, which uses defaults produced by the
%                      generation function.
%    setRngSeed      - Boolean. Set the rng seed to a value so output is
%                      reproducible. Default true.
%    generatePlots   - Boolean. Whether to produce psychometric function
%                      output graphs. Default true.
%    delete          - Boolean. Whether to delete the output files. Not yet
%                      implemented. Default false.

%% Parse input
p = inputParser;
p.addParameter('rParams', [], @isemptyorstruct);
p.addParameter('instanceParams', [], @isemptyorstruct);
p.addParameter('thresholdParams', [], @isemptyorstruct);
p.addParameter('freezeNoise', true, @islogical);
p.addParameter('generatePlots', true, @islogical);
p.addParameter('delete', false', @islogical);
p.parse(varargin{:});

rParams = p.Results.rParams;
instanceParams = p.Results.instanceParams;
thresholdParams = p.Results.thresholdParams;

%% Set the default output
varargout = {};
varargout{1} = {};    % psychometricFunctions

%% Clear
if (nargin == 0)
    ieInit;
    close all;
end

%% Get the parameters we need
% t_colorGaborResponseGenerationParams returns a hierarchical struct of
% parameters used by a number of tutorials and functions in this project.
if (isempty(rParams))
    rParams = responseParamsGenerate;

    % Override some defult parameters
    %
    % Set duration equal to sampling interval to do just one frame.
    rParams.temporalParams.stimulusDurationInSeconds = 200 / 1000;
    rParams.temporalParams.stimulusSamplingIntervalInSeconds = ...
        rParams.temporalParams.stimulusDurationInSeconds;
    rParams.temporalParams.secondsToInclude = ...
        rParams.temporalParams.stimulusDurationInSeconds;

    % No eye movements
    rParams.temporalParams.emPathType = 'none';

    rParams.mosaicParams.integrationTimeInSeconds = ...
        rParams.temporalParams.stimulusDurationInSeconds;
    % Iso. Noise - Type coneMosaic.validNoiseFlags to get valid values
    rParams.mosaicParams.isomerizationNoise = 'random';
    % OS Noise - Type outerSegment.validNoiseFlags to get valid values
    rParams.mosaicParams.osNoise = 'random';
    rParams.mosaicParams.osModel = 'Linear';
end

% Fix random number generator so we can validate output exactly
if (p.Results.freezeNoise)
     rng(1);
     if (strcmp(rParams.mosaicParams.isomerizationNoise, 'random'))
         rParams.mosaicParams.isomerizationNoise = 'frozen';
     end
     if (strcmp(rParams.mosaicParams.osNoise, 'random'))
         rParams.mosaicParams.osNoise = 'frozen';
     end
end

%% Parameters that define the LM instances we'll generate here
% Make these numbers in the struct small (trialNum = 2, deltaAngle = 180,
% nContrastsPerDirection = 2) to run through a test quickly.
if (isempty(instanceParams)), instanceParams = instanceParamsGenerate; end

%% Parameters related to how we find thresholds from responses
if (isempty(thresholdParams))
    thresholdParams = thresholdParamsGenerate;
end

%% Set up the rw object for this program
rwObject = IBIOColorDetectReadWriteBasic;
readProgram = 't_colorDetectFindPerformance';
writeProgram = mfilename;

%% Read performance data
%
% We need this both for computing and plotting, so we just do it
paramsList = {rParams.topLevelDirParams, rParams.mosaicParams, ...
    rParams.oiParams, rParams.spatialParams, rParams.temporalParams, ...
    rParams.backgroundParams, instanceParams, thresholdParams};
performanceData = ...
    rwObject.read('performanceData', paramsList, readProgram);

% If everything is working right, these check parameter structures will
% match what we used to specify the file we read in.
%
% SHOULD ACTUALLY CHECK FOR EQUALITY HERE. Should be able to use
% RecursivelyCompareStructs to do so.
rParamsCheck = performanceData.rParams;
instanceParamsCheck = performanceData.instanceParams;
thresholdParamsCheck = performanceData.thresholdParams;

%% Extract data from loaded struct into convenient form
testContrasts = performanceData.testContrasts;
testConeContrasts = performanceData.testConeContrasts;
fitContrasts = logspace(log10(min(testContrasts)), ...
    log10(max(testContrasts)), 100)';
nTrials = instanceParams.trialsNum;

%% Fit psychometric functions
% And make a plot of each along with its fit
for ii = 1:size(performanceData.testConeContrasts, 2)
    % Get the performance data for this test direction, as a function of
    % contrast.
    thePerformance = squeeze(performanceData.percentCorrect(ii, :));
    theStandardError = squeeze(performanceData.stdErr(ii, :));

    % Fit psychometric function and find threshold.
    %
    % The work is done by singleThresholdExtraction, which itself calls the
    % Palemedes toolbox. The Palemedes toolbox is included in the external
    % subfolder of the Isetbio distribution.
    [tempThreshold, fitFractionCorrect(:, ii), ...
        psychometricParams{ii}] = singleThresholdExtraction(...
        testContrasts, thePerformance, ...
        thresholdParams.criterionFraction, nTrials, fitContrasts);
    thresholdContrasts(ii) = tempThreshold;

    % Convert threshold contrast to threshold cone contrasts
    thresholdConeContrasts(:, ii) = testConeContrasts(:, ii) * ...
        thresholdContrasts(ii);
end

%% Validation data
if (nargout > 0)
    validationData.testContrasts = testContrasts;
    validationData.testConeContrasts = testConeContrasts;
    validationData.thresholdContrasts = thresholdContrasts;
    validationData.thresholdConeContrasts = thresholdConeContrasts;
    validationData.fitContrasts = fitContrasts;
    validationData.fitFractionCorrect = fitFractionCorrect;
    validationData.thePerformance = thePerformance;
    validationData.theStandardError = theStandardError;
end

%% Plot psychometric functions
if (p.Results.generatePlots)
    for ii = 1:size(performanceData.testConeContrasts, 2)
        % Make the plot for this test direction
        hFig = figure;
        clf;
        set(hFig, 'Position', [10 10 560 600], 'Color', [1 1 1]);
        subplot('Position', [0.09 0.11 0.92 0.75]);
        plot(fitContrasts, fitFractionCorrect(:, ii), 'r', ...
            'LineWidth', 4.0);
        hold on
        errorbar(testContrasts, thePerformance, theStandardError, 'ro', ...
            'MarkerSize', 18, 'MarkerFaceColor', [1.0 0.8 0.8], ...
            'LineWidth', 1.5);
        plot([testContrasts(1) * 0.9, testContrasts(end) * 1.1], ...
            [thresholdParams.criterionFraction, ...
            thresholdParams.criterionFraction], 'k--', 'LineWidth', 2);
        plot(thresholdContrasts(ii) * [1 1], ...
            [0 thresholdParams.criterionFraction], 'b', 'LineWidth', 3.0);
        plot(thresholdContrasts(ii), 0.40, 'bv', 'LineWidth', 2.0, ...
            'MarkerSize', 12, 'MarkerFaceColor', [0.6 0.6 1.0]);
        yTicks = 0:0.1:1.0;
        xTicks = -7:1:0;
        xTickLabels = sprintf('10^{%d}\n', xTicks);
        set(gca, 'YLim', [0.39 1.05], ...
            'XLim', [testContrasts(1) * 0.9 testContrasts(end) * 1.1], ...
            'XTick', 10.^xTicks, 'XTickLabel', xTickLabels);
        set(gca, 'YTick', yTicks, ...
            'YTickLabel', sprintf('%1.1f\n', yTicks));
        set(gca, 'FontSize', 20, 'XScale', 'log', 'LineWidth', 1.0);
        xlabel('contrast', 'FontWeight', 'bold');
        ylabel('percent correct', 'FontWeight', 'bold');
        box on;
        grid on;
        axis 'square'
        title({sprintf(['LMangle = %2.1f deg\nLMthreshold ', ...
            '(%0.4f%%, %0.4f%%)'], atan2(testConeContrasts(2, ii), ...
            testConeContrasts(1, ii)) / pi * 180, ...
            100 * thresholdContrasts(ii) * testConeContrasts(1, ii), ...
            100 * thresholdContrasts(ii) * testConeContrasts(2, ii)); ''});
        rwObject.write(sprintf('LMPsychoFunctions_%d', ii), hFig, ...
            paramsList, writeProgram, 'Type', 'figure');

        psychometricFunctions{ii}.x = testContrasts;
        psychometricFunctions{ii}.y = thePerformance;
        psychometricFunctions{ii}.xFit = fitContrasts;
        psychometricFunctions{ii}.yFit = fitFractionCorrect(:, ii);
        psychometricFunctions{ii}.thresholdContrast = ...
            thresholdContrasts(ii);
        psychometricFunctions{ii}.criterionFraction = ...
            thresholdParams.criterionFraction;
    end % ii
    varargout{1} = psychometricFunctions;
end

end
