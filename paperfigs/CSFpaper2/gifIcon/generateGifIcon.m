function generateGifIcon
    [rootPath,~] = fileparts(which(mfilename));

    
    [theMosaic, theIsomerizations, thePhotocurrents, theEMPath, responseTimeAxis] = generateData();
    
    gifFineName = fullfile(rootPath,'Cottaris2020');
    hFig = generateGIFVideo(theMosaic, theIsomerizations, theEMPath, responseTimeAxis, sprintf('%s.gif',gifFineName));
    NicePlot.exportFigToPNG(sprintf('%s.png',gifFineName), hFig, 300);
end

function [coneMosaic, differentialAbsorptions, differentialPhotocurrents, visualizedEMPath, responseTimeAxis] = generateData()
    %% Generate a display for presenting stimuli and place it at a viewing distance of 57 cm
    presentationDisplay = displayCreate('LCD-Apple', 'viewing distance', 0.57);

    %% Specify a Gabor stimulus 
    stimParams = struct(...
    'spatialFrequencyCyclesPerDeg', 12, ...  % 8 cycles/deg
    'orientationDegs', 0, ...               % 0 degrees
    'widthDegs', 0.4, ...                   % 0.5 x 0.5 deg size
    'contrast', 1.0,...                     % 100% Michelson contrast
    'meanLuminanceCdPerM2', 200);           % 200 cd/m2 mean luminance

    %% Generate an ISETBio scene describing this stimulus
    stimulusScene = generateStimulusScene(stimParams, presentationDisplay);

    %% Generate an ISETBio scene describing the background
    stimParams.contrast = 0.0;
    backgroundScene = generateStimulusScene(stimParams, presentationDisplay);


    %% Realize the scenes into the particular LCD display
    realizedStimulusScene = realizeSceneInDisplay(stimulusScene, presentationDisplay);
    realizedBackgroundScene = realizeSceneInDisplay(backgroundScene, presentationDisplay);
    fprintf(' Done !');

    %% Generate wavefront-aberration derived human optics
    fprintf('\n2.Generating optical image ...');
    opticalImage = oiCreate('wvf human');

    %% Compute the retinal images of the stimulus and the background scenes
    stimulusOI = oiCompute(opticalImage, realizedStimulusScene);
    backgroundOI = oiCompute(opticalImage, realizedBackgroundScene);
    fprintf(' Done !');
    
    %% Compute the stimulus temporal modulation function (square wave)
    fprintf('\n3.Generating optical image sequence ...');
    stimulusSamplingIntervalSeconds = 25/1000;     % 50 msec refresh time (20 Hz)
    stimulusDurationSeconds = 100/1000;            % 100 msec duration
    stimulusTimeAxisSeconds = -0.025:stimulusSamplingIntervalSeconds:0.075;   % Compute responses from -100ms to +200ms around the stimulus onset
    stimONbins = stimulusTimeAxisSeconds>=0 & stimulusTimeAxisSeconds <= stimulusDurationSeconds-stimulusSamplingIntervalSeconds;
    stimulusTemporalModulation = zeros(1, numel(stimulusTimeAxisSeconds));
    stimulusTemporalModulation(stimONbins) = 1;


    %% Compute the optical image sequence that simulates the stimulus presentation
    theOIsequence = oiSequence(backgroundOI, stimulusOI, stimulusTimeAxisSeconds, stimulusTemporalModulation, 'composition', 'blend');

    %% Load the cone mosaic
    load('/Users/nicolas/Documents/MATLAB/projects/ISETBioCSF/tutorials/recipes/CSFpaper2/coneMosaic.mat');
    coneMosaic.integrationTime = 2.5/1000;
    
    fprintf('\n5.Generating fixational eye movements ...');
    nTrials = 1;
    eyeMovementsNum = ...
                theOIsequence.maxEyeMovementsNumGivenIntegrationTime(coneMosaic.integrationTime);
    theEMPaths = coneMosaic.emGenSequence(eyeMovementsNum, 'nTrials', nTrials);
    fprintf(' Done !');
    
    %% Response time axis
    responseTimeAxis = (1:eyeMovementsNum)*coneMosaic.integrationTime + theOIsequence.timeAxis(1);

    %% Force eye movement to be at origin at t = 0
    [~,idx] = min(abs(responseTimeAxis));
    theEMPaths = bsxfun(@minus, theEMPaths, theEMPaths(:,idx,:));
    theEMPathsDegs = theEMPaths * coneMosaic.patternSampleSize(1) * 1e6 / coneMosaic.micronsPerDegree;

    %% Compute responses
    fprintf('\n6.Computing responses ...');
    for iTrial = 1:nTrials
            [absorptionsCountSequence(iTrial,:,:), photoCurrentSequence(iTrial,:,:)] = ...
                    coneMosaic.computeForOISequence(theOIsequence, ...
                    'emPaths', theEMPaths(iTrial,:,:), ...
                    'currentFlag', true);
    end
    fprintf(' Done !');

    visualizedTrial = 1;
    visualizedAbsorptions = squeeze(absorptionsCountSequence(visualizedTrial,:,:));
    visualizedPhotocurrents = squeeze(photoCurrentSequence(visualizedTrial,:,:));
    visualizedEMPath = squeeze(theEMPathsDegs(visualizedTrial,:,:));

    % Compute mean responses during the pre-stimulus interval
    nonCausalTimes = find(responseTimeAxis<0);
    meanAbsorptions = mean(visualizedAbsorptions(:, nonCausalTimes), 2);
    meanPhotocurrents = mean(visualizedPhotocurrents(:, nonCausalTimes), 2);
    % Subtract mean responses to compute differential responses (modulations)
    differentialAbsorptions = bsxfun(@minus, visualizedAbsorptions, meanAbsorptions);
    differentialPhotocurrents = bsxfun(@minus, visualizedPhotocurrents, meanPhotocurrents);

end

function renderFrame(axHandle, tBin, theMosaic, theMosaicResponse, theEMPath, responseTimeAxis)
    
    Tcritical = min(responseTimeAxis);% + 0.5*(max(responseTimeAxis)-min(responseTimeAxis));
    if (responseTimeAxis(tBin)<Tcritical)
        zoomInFactor = min([2 0.7+0.4*(abs((responseTimeAxis(tBin)-Tcritical)/Tcritical))]);
    else
        zoomInFactor = min([2 0.7+0.4*(abs((responseTimeAxis(tBin)-Tcritical)/Tcritical))]);
    end

    spaceLims = 0.15/zoomInFactor*[-1 1]*300*1e-6;
    emScale = 300*1e-6;
    signalRange = max(abs(theMosaicResponse(:)))*[-0.8 0.8];
    theResponse = theMosaicResponse(:,tBin);
    theMosaic.renderActivationMap(axHandle, theResponse, ...
        'visualizedConeAperture', 'geometricArea', ...
        'mapType', 'modulated disks', 'signalRange', signalRange, ...
        'tickInc', 0.1);
    set(axHandle, 'XLim', spaceLims, 'YLim', spaceLims);
    hold on;
    to = max([1 tBin-8]);
    plot(theEMPath(to:tBin-1,1)*emScale, -theEMPath(to:tBin-1,2)*emScale, 'r-', 'LineWidth', 2.0);
    plot(theEMPath(to:tBin-1,1)*emScale, -theEMPath(to:tBin-1,2)*emScale, 'y-', 'LineWidth', 1.0);hold on;
    hold off;
end




function hFig = generateGIFVideo(theMosaic, theMosaicResponse, theEMPath, responseTimeAxis, gifFineName)
    
    blurGif = ~true;
    
    % Plot
    hFig = figure(1); clf

    gifSizePixels = 96;
    minFigSize = 160;
    marginPixels = (minFigSize - gifSizePixels)/2;
    
    set(hFig, 'Position', [10 10 minFigSize/2 minFigSize/2], 'Color', [1 1 1], 'MenuBar', 'none', 'ToolBar', 'none', 'DockControls', 'off');
    ax = subplot('Position', [0.00 0.00 1.0 1.0]);
    
    for tBin = 1:numel(responseTimeAxis)
        
        renderFrame(ax, tBin, theMosaic, theMosaicResponse, theEMPath, responseTimeAxis);
        % Capture frame
        frame = getframe(hFig);

        % Smooth with the smoothing kernel
        data = frame.cdata;
        frame.cdata = data(marginPixels+(1:gifSizePixels), marginPixels+(1:gifSizePixels),:);
        
        if (blurGif)
            gaussSigmaPixels = 0.75;
             data = frame.cdata;
             dataGray = squeeze(sum(data,3))/3;
             dataGray = imgaussfilt(dataGray, gaussSigmaPixels);
             maxNow = prctile(dataGray(:), 98);
             dataGray = 256 * dataGray / maxNow;
             dataGray(dataGray>256) = 256;
             
             
             for plane = 1:3
                 data(:,:,plane) = uint8(dataGray);
             end
             data(:,:,2) = data2;
             frame.cdata = data;
        end

        %frame.cdata = uint8(255*SRGBGammaCorrect(double(frame.cdata)/255)); %lin2rgb(uint8(round(255*(double(frame.cdata)/255.0).^1.2)));
        
        im = frame2im(frame); 
        [imind,cm] = rgb2ind(im,256, 'nodither');
        % Write to the GIF File 
          if tBin == 1 
              imwrite(imind,cm,gifFineName,'gif', ...
                  'Loopcount',inf, ...
                  'DelayTime', 0/1000); 
          else 
              imwrite(imind,cm,gifFineName,'gif', ...
                  'WriteMode','append', ...
                  'DelayTime', 0/1000); 
          end 
    end

    
    % view it
    web(gifFineName);
         
end
