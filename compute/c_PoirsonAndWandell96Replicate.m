function [validationData, extraData] = c_PoirsonAndWandell96Replicate(varargin)

% Key/value pairs
%   'useScratchTopLevelDirName'- true/false (default false). 
%      When true, the top level output directory is [scratch]. 
%      When false, it is the name of this script.


%% Parse input
p = inputParser;
p.addParameter('useScratchTopLevelDirName', false, @islogical);
p.addParameter('nTrainingSamples',500,@isnumeric);
p.addParameter('imagePixels',500, @isnumeric);
p.addParameter('computeResponses',true,@islogical);
p.addParameter('computeMosaic',false,@islogical);
p.addParameter('visualizeResponses',true,@islogical);
p.addParameter('freezeNoise',true,@islogical);
p.addParameter('visualizedResponseNormalization', 'submosaicBasedZscore', @ischar);
p.addParameter('findPerformance',true,@islogical);
p.addParameter('fitPsychometric',true,@islogical);
p.addParameter('generatePlots',true,@islogical);
p.parse(varargin{:});

% Start with default
rParams = responseParamsGenerate;

%% Set the  topLevelDir name
if (~p.Results.useScratchTopLevelDirName)
    rParams.topLevelDirParams.name = mfilename;
end

% Modify spatial params to match P&W '96
rParams.spatialParams = modifyStructParams(rParams.spatialParams, ...
        'windowType', 'Gaussian', ...
        'cyclesPerDegree', 4.0, ...
        'gaussianFWHMDegs', 1.9, ...
        'fieldOfViewDegs', 10.0, ...             % In P&W 1996, in the constant cycle condition, this was 10 deg (Section 2.2, p 517)
        'viewingDistance', 0.75, ...            % vd in meters
        'ang', 0,  ...                          % orientation in radians
        'ph', 0, ...                         % spatial phase in radians
        'row', p.Results.imagePixels, ...
        'col', p.Results.imagePixels);
  
% Modify background params to match P&W '96
luminancePW96 = 536.2;
luminancePW96 = 200.0;  % limit to 200 for now because the photocurrent model is validated up to this luminance level
baseLum = 50;
rParams.backgroundParams = modifyStructParams(rParams.backgroundParams, ...
    'backgroundxyY', [0.38 0.39 baseLum]',...
    'monitorFile', 'CRT-MODEL', ...
    'leakageLum', 1.0, ...
    'lumFactor', luminancePW96/baseLum);
 
% Modify temporal params to match P&W'96
frameRate = 87;                                     % their CRT had 87 Hz refresh rate
windowTauInSeconds = 165/1000;
stimulusSamplingIntervalInSeconds = 1/frameRate;
stimulusDurationInSeconds = 1.5*windowTauInSeconds;
rParams.temporalParams = modifyStructParams(rParams.temporalParams, ...
    'frameRate', frameRate, ...
    'windowTauInSeconds', windowTauInSeconds, ...
    'stimulusSamplingIntervalInSeconds', stimulusSamplingIntervalInSeconds, ...
    'stimulusDurationInSeconds', stimulusDurationInSeconds, ...
    'secondsToInclude', 300/1000, ...
    'secondsToIncludeOffset', 0/1000, ...         % account for latency in photocurrent
    'emPathType', 'frozen' ...
);


% Modify mosaic parameters
conePacking = 'hex';        % Hexagonal mosaic
%conePacking = 'rect';       % Rectangular mosaic
rParams.mosaicParams = modifyStructParams(rParams.mosaicParams, ...
    'conePacking', conePacking, ...                       
    'fieldOfViewDegs', rParams.spatialParams.fieldOfViewDegs*0.125, ... 
    'integrationTimeInSeconds', 6/1000, ...
    'isomerizationNoise', 'frozen',...              % select from {'random', 'frozen', 'none'}
    'osNoise', 'frozen', ...                        % select from {'random', 'frozen', 'none'}
    'osModel', 'Linear');
        
% Parameters that define the LM instances we'll generate
% Here, we are generating an L-only grating (azimuth = 0, elevation = 0);
testDirectionParams = instanceParamsGenerate('instanceType', 'LMSPlane');
testDirectionParams = modifyStructParams(testDirectionParams, ...
    'trialsNum', p.Results.nTrainingSamples, ...
    'startAzimuthAngle', 45, ...
    'nAzimuthAngles', 1, ...
    'startElevationAngle', 0, ...
    'nElevationAngles', 1, ...
    'nContrastsPerDirection', 12, ...
    'lowContrast', 0.01, ...
    'highContrast', 1.0, ...
    'contrastScale', 'log' ...    % choose between 'linear' and 'log'  
);


% Let the colorDetectResponseInstanceArrayFastConstruct decide how many
% blocks to split the trials in, depending on the size of the mosaic,
% the cores available and the system RAM.
trialBlocks = -1;

% Parameters related to how we find thresholds from responses
% Use default
thresholdParams = thresholdParamsGenerate;
   

%% Compute response instances
if (p.Results.computeResponses)
    tBegin = clock;
    t_coneCurrentEyeMovementsResponseInstances(...
          'rParams',rParams,...
          'testDirectionParams',testDirectionParams,...
          'compute',p.Results.computeResponses, ...
          'computeMosaic', p.Results.computeMosaic, ... 
          'visualizedResponseNormalization', p.Results.visualizedResponseNormalization, ...
          'trialBlocks', trialBlocks, ...
          'freezeNoise',p.Results.freezeNoise, ...
          'generatePlots',p.Results.generatePlots, ...
          'visualizeResponses', false, ...
          'workerID', 1);
    tEnd = clock;
    timeLapsed = etime(tEnd,tBegin);
    fprintf('Compute took %f minutes \n', timeLapsed/60);
end

%% Compute response instances
if (p.Results.visualizeResponses)

    % How many istances to visualize
    instancesToVisualize = 5;
    
    % Load the mosaic
    coneParamsList = {rParams.topLevelDirParams, rParams.mosaicParams};
    theMosaic = rwObject.read('coneMosaic', coneParamsList, theProgram, 'type', 'mat');
         
    % Load the response and ancillary data
    paramsList = constantParamsList;
    paramsList{numel(paramsList)+1} = colorModulationParamsNull;    
    noStimData = rwObject.read('responseInstances',paramsList,theProgram);
    ancillaryData = rwObject.read('ancillaryData',paramsList,theProgram);
    
    rParams = ancillaryData.rParams;
    parforConditionStructs = ancillaryData.parforConditionStructs;
    nParforConditions = length(parforConditionStructs); 
    for kk = 1:nParforConditions 
         thisConditionStruct = parforConditionStructs{kk};
         colorModulationParamsTemp = rParams.colorModulationParams;
         colorModulationParamsTemp.coneContrasts = thisConditionStruct.testConeContrasts;
         colorModulationParamsTemp.contrast = thisConditionStruct.contrast;

         paramsList = constantParamsList;
         paramsList{numel(paramsList)+1} = colorModulationParamsTemp;    
         stimData = rwObject.read('responseInstances',paramsList,theProgram);
         visualizeResponseInstances(theMosaic, stimData, noStimData, p.Results.visualizedResponseNormalization, kk, nParforConditions, instancesToVisualize, p.Results.visualizationFormat);
    end
end % visualizeResponses

%% Find performance, template max likeli
thresholdParams.method = 'mlpt';
if (p.Results.findPerformance)
    t_colorDetectFindPerformance(...
        'rParams',rParams, ...
        'testDirectionParams',testDirectionParams,...
        'thresholdParams',thresholdParams, ...
        'compute',true, ...
        'plotSvmBoundary',false, ...
        'plotPsychometric',false ...
        );
end
        
end

