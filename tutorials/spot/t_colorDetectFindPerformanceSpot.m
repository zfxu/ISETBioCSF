function validationData = t_colorDetectFindPerformanceSpot(rParams)
% validationData = tt_colorDetectFindPerformanceSpot(rParams)
%
% This is a call into t_colorDetectFindPerformance that demonstates its
% ability to handle AO spots as well as Gabor modulations on monitors.
%
% Optional key/value pairs
%  'generatePlots' - true/fale (default true).  Make plots?

%% Parse vargin for options passed here
p = inputParser;
p.addParameter('generatePlots',true,@islogical);
p.parse(varargin{:});

%% Clear
if (nargin == 0)
    ieInit; close all;
end

%% Fix random number generator so we can validate output exactly
rng(1);

%% Get the parameters we need
%
% responseParamsGenerate returns a hierarchical struct of
% parameters used by a number of tutorials and functions in this project.
if (nargin < 1 | isempty(rParams))
    rParams = responseParamsGenerate('spatialType','spot','backgroundType','AO','modulationType','AO');
    
    % Override some defult parameters
    %
    % Set duration equal to sampling interval to do just one frame.
    rParams.temporalParams.simulationTimeStepSecs = 200/1000;
    rParams.temporalParams.stimulusDurationInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.stimulusSamplingIntervalInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.secondsToInclude = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.eyesDoNotMove = true;
    
    rParams.mosaicParams.timeStepInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.mosaicParams.integrationTimeInSeconds = rParams.mosaicParams.timeStepInSeconds;
    rParams.mosaicParams.isomerizationNoise = true;
    rParams.mosaicParams.osNoise = true;
    rParams.mosaicParams.osModel = 'Linear';
    
    rParams.oiParams.pupilDiamMm = 7;
end

%% Call into t_colorDetectFindPerformance with spot parameters
contrastParams = instanceParamsGenerate('instanceType','contrasts');
thresholdParams = thresholdParamsGenerate;
thresholdParams.method = 'mlpt';
validationData = t_colorDetectFindPerformance('rParams',rParams,'testDirectionParams',contrastParams,'thresholdParams',thresholdParams,'plotPsychometric',true,'generatePlots',p.Results.generatePlots);

