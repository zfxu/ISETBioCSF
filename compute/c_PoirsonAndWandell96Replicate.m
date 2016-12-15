function [validationData, extraData] = c_PoirsonAndWandell96Replicate(varargin)
%% Parse input
p = inputParser;
p.addParameter('nTrainingSamples',10,@isnumeric);
p.addParameter('imagePixels',500, @isnumeric);
p.addParameter('computeResponses',true,@islogical);
p.addParameter('computeMosaic',false,@islogical);
p.addParameter('visualizedResponseNormalization', 'submosaicBasedZscore', @ischar);
p.addParameter('findPerformance',true,@islogical);
p.addParameter('fitPsychometric',true,@islogical);
p.addParameter('generatePlots',true,@islogical);
p.parse(varargin{:});

% Start with default
rParams = responseParamsGenerate;

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
stimulusDurationInSeconds = 2.0*windowTauInSeconds;
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
    'fieldOfViewDegs', rParams.spatialParams.fieldOfViewDegs*0.05, ... 
    'integrationTimeInSeconds', 10/1000, ...
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
    'nContrastsPerDirection', 1, ...
    'lowContrast', 1.0, ...
    'highContrast', 1.0, ...
    'contrastScale', 'log' ...    % choose between 'linear' and 'log'  
);

% Parameters related to how we find thresholds from responses
% Use default
thresholdParams = thresholdParamsGenerate;
   
%% Compute response instances
t_coneCurrentEyeMovementsResponseInstances(...
      'rParams',rParams,...
      'testDirectionParams',testDirectionParams,...
      'compute',p.Results.computeResponses, ...
      'computeMosaic', p.Results.computeMosaic, ... 
      'visualizedResponseNormalization', p.Results.visualizedResponseNormalization, ...
      'generatePlots',p.Results.generatePlots, ...
      'workerID', []);
        
end

