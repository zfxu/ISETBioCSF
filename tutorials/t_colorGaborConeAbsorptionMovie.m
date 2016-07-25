function t_colorGaborConeAbsorptionsMovie(rParams)
% t_colorGaborConeAbsorptionsMovie(rParams)
%
% Create scene sequence for a Gaussian windowed color gabor and then from
% it generate an optical image sequence and finally a cone reponse
% movie.
%
% The scene sequence generation logic illustrated here is encapsulated in a
% fancier manner in colorGaborSceneSequenceCreate.
%
% The output goes into a place determined by
%   colorGaborDetectOutputDir
% which itself checks for a preference set by
%   ISETColorDetectPreferencesTemplate
% which you may want to edit before running this and other scripts that
% produce substantial output.  The output within the main output directory
% is sorted by directories whose names are computed from parameters.  This
% naming is done in routine
%   paramsToDirName.
%
% See also t_colorGaborScene, colorGaborSceneSequenceCreate
%
% 7/8/16  dhb  Wrote it.

%% Initialize
ieInit; clear; close all;

%% Get the parameters we need
if (nargin < 1 | isempty(rParams))
    rParams = t_colorGaborResponseGenerationParams;
end

%% Set up the rw object for this program
rwObject = IBIOColorDetectReadWriteBasic;
rwObject.parentParamsList = {};
rwObject.currentParamsList = {rParams, rParams.colorModulationParams};

%% Plot the Gaussian temporal window, just to make sure it looks right
gaussianFigure = figure; clf;
plot(rParams.temporalParams.sampleTimes,rParams.temporalParams.gaussianTemporalWindow,'r');
xlabel('Time (seconds)');
ylabel('Window Amplitude');
title('Stimulus Temporal Window');

%% Loop over time and build a cell array of scenes
gaborScene = cell(rParams.temporalParams.nSampleTimes,1);
for ii = 1:rParams.temporalParams.nSampleTimes
    % Make the scene for this time
    rParamsTemp = rParams;
    rParamsTemp.colorModulationParams.contrast = rParams.colorModulationParams.contrast*rParams.temporalParams.gaussianTemporalWindow(ii);
    fprintf('Computing scene %d of %d, time %0.3f, windowVal %0.3f\n',ii,rParamsTemp.temporalParams.nSampleTimes,rParamsTemp.temporalParams.sampleTimes(ii),rParamsTemp.temporalParams.gaussianTemporalWindow(ii));
    gaborScene{ii} = colorGaborSceneCreate(rParamsTemp.gaborParams,rParamsTemp.colorModulationParams);
end
clearvars('rParamsTemp');

% Make a movie of the stimulus sequence
showLuminanceMap = false;
visualizeSceneOrOpticalImageSequence(rwObject, 'scene', gaborScene, rParams.temporalParams.sampleTimes, showLuminanceMap, 'gaborStimulusMovie');

%% Create the OI object we'll use to compute the retinal images from the scenes
%
% Then loop over scenes and compute the optical image for each one 
theBaseOI = colorDetectOpticalImageConstruct(rParams.oiParams);
theOI = cell(rParams.temporalParams.nSampleTimes,1);
for ii = 1:rParams.temporalParams.nSampleTimes
    % Compute retinal image
    fprintf('Computing optical image %d of %d, time %0.3f\n',ii,rParams.temporalParams.nSampleTimes,rParams.temporalParams.sampleTimes(ii));
    theOI{ii} = oiCompute(theBaseOI,gaborScene{ii});
end

% Make a movie of the optical image sequence
showLuminanceMap = false;
visualizeSceneOrOpticalImageSequence(rwObject,'optical image', theOI, rParams.temporalParams.sampleTimes, showLuminanceMap, 'gaborOpticalImageMovie');

%% Create the coneMosaic object we'll use to compute cone respones
theMosaic = colorDetectConeMosaicConstruct(rParams.mosaicParams);
for ii = 1:rParams.temporalParams.nSampleTimes      
    % Compute mosaic response for each stimulus frame
    % For a real calculation, we would save these so that we could use them
    % to do something.  But here we just (see next line) compute the
    % contrast seen by each class of cone in the mosaic, just to show we
    % can do something.
    fprintf('Computing absorptions %d of %d, time %0.3f\n',ii,rParams.temporalParams.nSampleTimes,rParams.temporalParams.sampleTimes(ii));
    gaborConeAbsorptions(:,:,ii) = theMosaic.compute(theOI{ii},'currentFlag',false);
end

% Make a movie of the isomerizations
eyeMovementSequence = [];
visualizeMosaicResponseSequence(rwObject, 'isomerizations (R*/cone)', gaborConeAbsorptions, eyeMovementSequence, theMosaic.pattern, rParams.temporalParams.sampleTimes, [theMosaic.width theMosaic.height], theMosaic.fov, rParams.mosaicParams.integrationTimeInSeconds, 'gaborIsomerizations');

%% Plot cone contrasts as a function of time, as a check
%
% We are not quite sure why they have the scalloped look that they do.
% Maybe monitor quantization?
for ii = 1:rParams.temporalParams.nSampleTimes      
    LMSContrasts(:,ii) = mosaicUnsignedConeContrasts(gaborConeAbsorptions(:,:,ii),theMosaic);
end
vcNewGraphWin; hold on;
plot(rParams.temporalParams.sampleTimes,LMSContrasts(1,:)','r');
plot(rParams.temporalParams.sampleTimes,LMSContrasts(2,:)','g');
plot(rParams.temporalParams.sampleTimes,LMSContrasts(3,:)','b');
xlabel('Time (seconds)');
ylabel('Contrast');
title('LMS Cone Contrasts');

