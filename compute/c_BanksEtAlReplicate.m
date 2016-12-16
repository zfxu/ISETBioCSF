function [validationData, extraData] = c_BanksEtAlReplicate(varargin)
% [validationData, extraData] = c_BanksEtAlReplicate(varargin)
%
% Compute thresholds to replicate Banks et al, 1987, more or less.
%
% This looks at L+M detection thrsholds, which seems close enough for right now to
% the isochromatic thresholds studied by Banks et al.
%
% Key/value pairs
%   'nTrainingSamples' - value (default 500).  Number of training samples to cycle through.
%   'cyclesPerDegree' - vector (default [3 5 10 20 40]). Spatial frequencoes of grating to be investigated.
%   'luminances' - vector (default [3.4 34 340]).  Luminances in cd/m2 to be investigated.
%   'pupilDiamMm' - value (default 2).  Pupil diameter in mm.
%   'blur' - true/false (default true). Incorporate lens blur.
%   'innerSegmentDiamMicrons' - Diameter of the cone light-collecting area, in microns 
%       Default:
%       diameterForSquareApertureFromDiameterForCircularAperture(3.0), where 3 microns = 6 min arc FOR 300 mirons/degree in the human retina.
%   'conePacking'   - how cones are packed spatially. 
%       Choose from : 'rect', for a rectangular mosaic
%                     'hex', for a hex mosaic with an eccentricity-varying cone spacing
%                     {'hex', coneSpacingMicrons} for a hex mosaic with the given cone spacing
%   'imagePixels' - value (default 400).  Size of image pixel array
%   'computeResponses' - true/false (default true).  Compute responses.
%   'findPerformance' - true/false (default true).  Find performance.
%   'fitPsychometric' - true/false (default true).  Fit psychometric functions.
%   'generatePlots' - true/false (default true).  No plots are generated unless this is true.
%   'visualizedResponseNormalization' - how to normalize visualized responses
%        Available options: 'submosaicBasedZscore', 'LMSabsoluteResponseBased', 'LMabsoluteResponseBased', 'MabsoluteResponseBased'
%   'plotPsychometric' - true/false (default true).  Plot psychometric functions.
%   'plotCSF' - true/false (default true).  Plot results.

%% Parse input
p = inputParser;
p.addParameter('nTrainingSamples',500,@isnumeric);
p.addParameter('cyclesPerDegree',[3 5 10 20 40 50],@isnumeric);
p.addParameter('luminances',[3.4 34 340],@isnumeric);
p.addParameter('pupilDiamMm',2,@isnumeric);
p.addParameter('blur',true,@islogical);
p.addParameter('innerSegmentDiamMicrons', diameterForSquareApertureFromDiameterForCircularAperture(3.0), @isnumeric);   % 3 microns = 0.6 min arc for 300 microns/deg in human retina
p.addParameter('coneSpacingMicrons', 3.0, @isnumeric);
p.addParameter('conePacking', 'hex-regular');                 % choose from 'rect', 'hex-regular' (fixed cone spacing and collecting area), and 'hex' (spatially-varying cone spacing, fixed colleting area)
p.addParameter('imagePixels',400,@isnumeric);
p.addParameter('computeResponses',true,@islogical);
p.addParameter('visualizedResponseNormalization', 'submosaicBasedZscore', @ischar);
p.addParameter('findPerformance',true,@islogical);
p.addParameter('fitPsychometric',true,@islogical);
p.addParameter('generatePlots',true,@islogical);
p.addParameter('plotPsychometric',true,@islogical);
p.addParameter('plotCSF',true,@islogical);
p.parse(varargin{:});

%% Get the parameters we need
%
% Start with default
rParams = responseParamsGenerate;

%% Loop over spatial frequency
for ll = 1:length(p.Results.luminances)
    for cc = 1:length(p.Results.cyclesPerDegree)
        
        % Get stimulus parameters correct
        %
        % The stimulus was half-cosine windowed to contain 7.5 cycles.  We set
        % our half-cosine window to match that and also make the field of view
        % just a tad bigger.
        cyclesPerDegree = p.Results.cyclesPerDegree(cc);
        gaussianFWHMDegs = 3.75*(1/cyclesPerDegree);
        fieldOfViewDegs = 2.1*gaussianFWHMDegs;
        rParams.spatialParams = modifyStructParams(rParams.spatialParams, ...
            'windowType', 'halfcos', ...
            'cyclesPerDegree', cyclesPerDegree, ...
            'gaussianFWHMDegs', gaussianFWHMDegs, ...
            'fieldOfViewDegs', fieldOfViewDegs, ...
            'row', p.Results.imagePixels, ...
            'col', p.Results.imagePixels);
        
        % Blur
        rParams.oiParams = modifyStructParams(rParams.oiParams, ...
        	'blur', p.Results.blur, ...
            'pupilDiamMm', p.Results.pupilDiamMm ...    % 	They used a 2mm artificial pupil
        );
              
        % Set background luminance
        %
        % We start with a base luminance that we know is about mid-gray on the
        % monitor we specify.  To change luminance, we specify a scale factor.
        % This is eventually applied both to the background luminance and to the
        % monitor channel spectra, so that we don't get unintersting out of gamut errors.
        baseLum = 50;
        theLum = p.Results.luminances(ll);
        rParams.backgroundParams = modifyStructParams(rParams.backgroundParams, ...
        	'backgroundxyY', [0.33 0.33 baseLum]',...
        	'monitorFile', 'CRT-MODEL', ...
        	'leakageLum', 1.0, ...
        	'lumFactor', theLum/baseLum);
        
        % Their intervals were 100 msec each.
        stimulusDurationInSeconds = 100/1000;
        
        rParams.temporalParams = modifyStructParams(rParams.temporalParams, ...
            'stimulusDurationInSeconds', stimulusDurationInSeconds, ...
            'stimulusSamplingIntervalInSeconds',  stimulusDurationInSeconds, ... % Equate stimulusSamplingIntervalInSeconds to stimulusDurationInSeconds to generate 1 time point only
            'secondsToInclude', stimulusDurationInSeconds, ...
            'emPathType', 'none' ...        % Their main calculation was without eye movements
        );
        
        % Set up mosaic parameters. Here we integrate for the entire stimulus duration (100/1000)
        rParams.mosaicParams = modifyStructParams(rParams.mosaicParams, ...
            'fieldOfViewDegs', rParams.spatialParams.fieldOfViewDegs, ...  % Keep mosaic size in lock step with stimulus
            'innerSegmentDiamMicrons',p.Results.innerSegmentDiamMicrons, ...
            'coneSpacingMicrons', p.Results.coneSpacingMicrons, ...
            'conePacking', p.Results.conePacking, ...
        	'integrationTimeInSeconds', rParams.temporalParams.stimulusDurationInSeconds, ...
        	'isomerizationNoise', 'frozen',...              % select from {'random', 'frozen', 'none'}
        	'osNoise', 'frozen', ...                        % select from {'random', 'frozen', 'none'}
        	'osModel', 'Linear');
        
        % Parameters that define the LM instances we'll generate here
        %
        % Use default LMPlane.
        testDirectionParams = instanceParamsGenerate;
        testDirectionParams = modifyStructParams(testDirectionParams, ...
            'trialsNum', p.Results.nTrainingSamples, ...
        	'startAngle', 45, ...
        	'deltaAngle', 90, ...
        	'nAngles', 1, ...
            'nContrastsPerDirection', 20, ... % Number of contrasts to run in each color direction
            'lowContrast', 0.0001, ...
        	'highContrast', 0.1, ...
        	'contrastScale', 'log' ...    % choose between 'linear' and 'log'
            );
        
        % Parameters related to how we find thresholds from responses
        % Use default
        thresholdParams = thresholdParamsGenerate;
        
        %% Compute response instances
        if (p.Results.computeResponses)
           t_coneCurrentEyeMovementsResponseInstances(...
               'rParams',rParams,...
               'testDirectionParams',testDirectionParams,...
               'compute',true,...
               'visualizedResponseNormalization', p.Results.visualizedResponseNormalization, ...
               'generatePlots',p.Results.generatePlots);
        end
        
        %% Find performance, template max likeli
        thresholdParams.method = 'mlpt';
        if (p.Results.findPerformance)
            t_colorDetectFindPerformance('rParams',rParams,'testDirectionParams',testDirectionParams,'thresholdParams',thresholdParams,'compute',true,'plotSvmBoundary',false,'plotPsychometric',false);
        end
        
        %% Fit psychometric functions
        if (p.Results.fitPsychometric)
            banksEtAlReplicate.cyclesPerDegree(ll,cc) = p.Results.cyclesPerDegree(cc);
            thresholdParams.method = 'mlpt';
            banksEtAlReplicate.mlptThresholds(ll,cc) = t_plotDetectThresholdsOnLMPlane('rParams',rParams,'instanceParams',testDirectionParams,'thresholdParams',thresholdParams, ...
                'plotPsychometric',p.Results.generatePlots & p.Results.plotPsychometric,'plotEllipse',false);
            %close all;
        end
    end
end

%% Write out the data
%
if (p.Results.fitPsychometric)
    fprintf('Writing performance data ... ');
    paramsList = {rParams.mosaicParams, rParams.oiParams, rParams.spatialParams,  rParams.temporalParams,  rParams.backgroundParams, testDirectionParams};
    rwObject = IBIOColorDetectReadWriteBasic;
    writeProgram = mfilename;
    rwObject.write('banksEtAlReplicate',banksEtAlReplicate,paramsList,writeProgram);
    fprintf('done\n');
end

%% Get performance data
fprintf('Reading performance data ...');
paramsList = {rParams.mosaicParams, rParams.oiParams, rParams.spatialParams,  rParams.temporalParams,  rParams.backgroundParams, testDirectionParams};
rwObject = IBIOColorDetectReadWriteBasic;
writeProgram = mfilename;
banksEtAlReplicate = rwObject.read('banksEtAlReplicate',paramsList,writeProgram);
fprintf('done\n');

%% Output validation data
if (nargout > 0)
    validationData.cyclesPerDegree = banksEtAlReplicate.cyclesPerDegree;
    validationData.mlptThresholds = banksEtAlReplicate.mlptThresholds;
    validationData.luminances = p.Results.luminances;
    extraData.paramsList = paramsList;
    extraData.p.Results = p.Results;
end

%% Make a plot of estimated threshold versus training set size
%
% The way the plot is coded counts on the test contrasts never changing
% across the conditions, which we could explicitly check for here.
if (p.Results.generatePlots & p.Results.plotCSF)  
    hFig = figure; clf; hold on
    fontBump = 4;
    markerBump = -4;
    set(gcf,'Position',[100 100 450 650]);
    set(gca,'FontSize', rParams.plotParams.axisFontSize+fontBump);
    theColors = ['r' 'g' 'b'];
    legendStr = cell(length(p.Results.luminances),1);
    for ll = 1:length(p.Results.luminances)
        theColorIndex = rem(ll,length(theColors)) + 1;
        plot(banksEtAlReplicate.cyclesPerDegree(ll,:),1./[banksEtAlReplicate.mlptThresholds(ll,:).thresholdContrasts]*banksEtAlReplicate.mlptThresholds(1).testConeContrasts(1), ...
            [theColors(theColorIndex) 'o-'],'MarkerSize',rParams.plotParams.markerSize+markerBump,'MarkerFaceColor',theColors(theColorIndex),'LineWidth',rParams.plotParams.lineWidth);  
        legendStr{ll} = sprintf('%0.1f cd/m2',p.Results.luminances(ll));
    end
    set(gca,'XScale','log');
    set(gca,'YScale','log');
    xlabel('Log10 Spatial Frequency (cpd)', 'FontSize' ,rParams.plotParams.labelFontSize+fontBump, 'FontWeight', 'bold');
    ylabel('Log10 Contrast Sensitivity', 'FontSize' ,rParams.plotParams.labelFontSize+fontBump, 'FontWeight', 'bold');
    xlim([1 100]); ylim([10 10000]);
    legend(legendStr,'Location','NorthEast','FontSize',rParams.plotParams.labelFontSize+fontBump);
    box off; grid on
    if (p.Results.blur)
        title(sprintf('Computational Observer CSF - w/ blur',rParams.mosaicParams.fieldOfViewDegs'),'FontSize',rParams.plotParams.titleFontSize+fontBump);
        rwObject.write('banksEtAlReplicateWithBlur',hFig,paramsList,writeProgram,'Type','figure');
    else
        title(sprintf('Computational Observer CSF - no blur',rParams.mosaicParams.fieldOfViewDegs'),'FontSize',rParams.plotParams.titleFontSize+fontBump);
        rwObject.write('banksEtAlReplicateNoBlur',hFig,paramsList,writeProgram,'Type','figure');
    end
end

