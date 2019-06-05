function simulateRucciExperiment

    [rootDir,~] = fileparts(which(mfilename));
    resourcesDir = '/media/dropbox_disk/Dropbox (Aguirre-Brainard Lab)/IBIO_analysis/IBIOColorDetect/SideProjects/RucciSimulations';
    cd(rootDir);
    pause(0.1);
    
    generateScenes = true;
    generateOpticalImages = true;
    generateMosaicResponses = true;
    visualizeMosaicResponses = ~true;
    classifyMosaicResponses = ~true;
    
    if (generateMosaicResponses || visualizeMosaicResponses || classifyMosaicResponses)
        % Load the mosaic
        load('ConeMosaic_1.0Degs_Iterations_2000_Tolerance_0.000250.mat', 'theMosaic');
    end
    
    % Contrast levels (exploring ....)
    contrastLevels = [1.0 0.3 0.1 0.03];
    
    
    % Only compute responses for the first instance of noise stimulus    
    analyzedNoiseInstance = 1;
    nTrials = 512;
    fixationDurationSeconds = 0.8;
    
    
    if (generateScenes)
        noiseInstances = 2;         % only computing responses for 1 though
        meanLuminanceCdPerM2 = 21;  % match Rucc 2007 paper
        stimulusSizeDegs = 1.0;     % small enough to allow faster computations
        generateAllScenes(noiseInstances, stimulusSizeDegs, meanLuminanceCdPerM2, contrastLevels, resourcesDir);  
    end
    
    if (generateOpticalImages)
        %Load previously computed scenes
        scenesFile = fullfile(resourcesDir, 'scenes.mat');
        load(scenesFile, 'lowFrequencyScenes', 'highFrequencyScenes', ...
             'lowFrequencyScenesOrtho', 'highFrequencyScenesOrtho', 'contrastLevels', 'noiseInstances');
        % Display scene profiles
        displayLuminanceProfiles(lowFrequencyScenes, highFrequencyScenes, contrastLevels, noiseInstances);
        % Compute ois
        generateAllOpticalImages(lowFrequencyScenes, highFrequencyScenes, lowFrequencyScenesOrtho, highFrequencyScenesOrtho, contrastLevels, noiseInstances, resourcesDir);
    end
    
    if (generateMosaicResponses)
        % Load previously computed optical images
        oisFile = fullfile(resourcesDir, 'ois.mat');
        load(oisFile, 'lowFrequencyOIs', 'highFrequencyOIs', ...
         'lowFrequencyOIsOrtho', 'highFrequencyOIsOrtho', 'contrastLevels');
     
        nTrialsPerBlock = 1;  % for a 16 GB system
        nTrialsPerBlock = 1;  % for a 32 GB system with 4 cores
        nTrialsPerBlock = 1; % for a 256 GB system with 20 cores
        
        generateAllMosaicResponses(theMosaic, lowFrequencyOIs, highFrequencyOIs, ...
                lowFrequencyOIsOrtho, highFrequencyOIsOrtho, ...
                fixationDurationSeconds, contrastLevels, analyzedNoiseInstance, ...
                nTrials, nTrialsPerBlock, resourcesDir);
    end
    
    if (visualizeMosaicResponses)
        contrastLevel = 1.0;
        visualizeTheResponses(theMosaic, contrastLevel, analyzedNoiseInstance);
    end
    
end

function visualizeTheResponses(theMosaic, contrastLevel, theInstance)
    
    fname = sprintf('highFrequency_contrast_%2.4f_instance_%1.0f.mat', contrastLevel, theInstance);
    load(fname, 'coneExcitations'); % , 'photoCurrents');
    
    nBlocks = length(coneExcitations);
    [nTrialsPerBlock,conesNum, timeBinsNum] = size(coneExcitations{1});
    
    nTrials = nBlocks*nTrialsPerBlock;
    theConeExcitations = zeros(nTrials, conesNum, timeBinsNum);
    
    % From cell array to array
    for blockIndex = 1:nBlocks
        % compute responses for this block's trials
        trialIndicesForBlock = (blockIndex-1)*nTrialsPerBlock + (1:nTrialsPerBlock);
        theConeExcitations(trialIndicesForBlock,:,:) = coneExcitations{blockIndex};
    end
    
    visualizeDynamicResponse(theMosaic, theConeExcitations, 'R*/cone/tau');
    %visualizeConeMosaicResponses(theMosaic, photoCurrents, 'pAmps');
            
end

function visualizeDynamicResponse(theMosaic, allTrialResponses, responseSignalName)
    
    instanceNo = 1;
    singleTrialResponse = squeeze(allTrialResponses(instanceNo,:,:));
    responseRange = [min(singleTrialResponse(:)) max(singleTrialResponse(:))];
    
    hFig = figure(9988);
    axHandle = subplot(1,2,1);
    for timeBin = 1:size(singleTrialResponse,2)
        theMosaic.renderActivationMap(axHandle, squeeze(singleTrialResponse(:,timeBin)), ...
                'mapType', 'modulated disks', ...
                'signalRange', responseRange, ...
                'showColorBar', true, ...
                'labelColorBarTicks', true, ...
                'titleForColorBar', responseSignalName);
        drawnow;
    end
end

function findPerformance()
    
end

function generateAllMosaicResponses(theMosaic, lowFrequencyOIs, highFrequencyOIs, ...
                lowFrequencyOIsOrtho, highFrequencyOIsOrtho, fixationDurationSeconds, ...
                contrastLevels, analyzedNoiseInstances, nTrials, nTrialsPerBlock, resourcesDir)

    % Set mosaic integration time and fixation duration
    theMosaic.integrationTime = 2.5/1000;
    eyeMovementsNum = ceil(fixationDurationSeconds/theMosaic.integrationTime);


    % Compute fixational eye movements for desired number of trials
    [emPaths, fixEMOBJ] = theMosaic.emGenSequence(eyeMovementsNum, ...
        'nTrials', nTrials, 'centerPaths', true);
    visualizeConeMosaicAndEMPath(theMosaic, fixEMOBJ);


    % Split in blocks to fit in memory
    nBlocks = round(nTrials/nTrialsPerBlock);

    % Compute mosaic responses for all ois
    nContrasts = numel(contrastLevels);
    for theContrastLevel = 1:nContrasts
        for theInstance = 1:analyzedNoiseInstances

            fname = fullfile(resourcesDir, sprintf('highFrequency_contrast_%2.4f_instance_%1.0f.mat', contrastLevels(theContrastLevel), theInstance));
            [coneExcitations, photoCurrents, eyeMovementPaths] = ...
                computeResponses(theMosaic, emPaths, highFrequencyOIs{theContrastLevel, theInstance}, nBlocks, nTrialsPerBlock);
            fprintf('Saving mosaic responses from %d trials to %s\n', size(coneExcitations,1), fname);
            save(fname, 'coneExcitations', 'photoCurrents', 'eyeMovementPaths',  'contrastLevels', 'theContrastLevel', '-v7.3');
            
            fname = fullfile(resourcesDir, sprintf('highFrequencyOrtho_contrast_%2.4f_instance_%1.0f.mat', contrastLevels(theContrastLevel), theInstance));
            [coneExcitations, photoCurrents, eyeMovementPaths] = ...
                computeResponses(theMosaic, emPaths, highFrequencyOIsOrtho{theContrastLevel, theInstance}, nBlocks, nTrialsPerBlock);
            fprintf('Saving mosaic responses from %d trials to %s\n', size(coneExcitations,1), fname);
            save(fname, 'coneExcitations', 'photoCurrents', 'eyeMovementPaths', 'contrastLevels', 'theContrastLevel', '-v7.3');
            
            fname = fullfile(resourcesDir, sprintf('lowFrequency_contrast_%2.4f_instance_%1.0f.mat', contrastLevels(theContrastLevel), theInstance));
            [coneExcitations, photoCurrents, eyeMovementPaths] = ...
                computeResponses(theMosaic, emPaths, lowFrequencyOIs{theContrastLevel, theInstance}, nBlocks, nTrialsPerBlock);
            fprintf('Saving mosaic responses from %d trials to %s\n', size(coneExcitations,1), fname);
            save(fname, 'coneExcitations', 'photoCurrents', 'eyeMovementPaths', 'contrastLevels', 'theContrastLevel','-v7.3');
            
            fname = fullfile(resourcesDir, sprintf('lowFrequencyOrtho_contrast_%2.4f_instance_%1.0f.mat', contrastLevels(theContrastLevel), theInstance));
            [coneExcitations, photoCurrents, eyeMovementPaths] = ...
                computeResponses(theMosaic, emPaths, lowFrequencyOIsOrtho{theContrastLevel, theInstance}, nBlocks, nTrialsPerBlock);
            fprintf('Saving mosaic responses from %d trials to %s\n', size(coneExcitations,1), fname);
            save(fname, 'coneExcitations', 'photoCurrents', 'eyeMovementPaths', 'contrastLevels', 'theContrastLevel', '-v7.3');
        end
    end
        
end

function [theConeExcitations, thePhotoCurrents, theEyeMovementsPaths] = computeResponses(theMosaic, emPaths, theOI, nBlocks, nTrialsPerBlock)
            
    % Find the non-null cone indices
    nonNullConeIndices = find(theMosaic.pattern > 1);

    coneExcitations = cell(1,nBlocks);
    photoCurrents = cell(1,nBlocks);
    eyeMovementPaths = cell(1, nBlocks);
    
    parfor blockIndex = 1:nBlocks
        % compute responses for this block's trials
        trialIndicesForBlock = (blockIndex-1)*nTrialsPerBlock + (1:nTrialsPerBlock);
        fprintf('Computing trials %d-%d of %d\n', trialIndicesForBlock(1), trialIndicesForBlock(end), nBlocks*nTrialsPerBlock);
        [theConeExcitations, thePhotocurrents] = ...
            theMosaic.compute(theOI, ...
                'emPath', emPaths(trialIndicesForBlock,:,:), ...
                'currentFlag', true);

        % store to cell array
        coneExcitations{blockIndex} = reformatAllTrialsMatrix(theConeExcitations, nonNullConeIndices);
        photoCurrents{blockIndex} = reformatAllTrialsMatrix(thePhotocurrents, nonNullConeIndices);
        eyeMovementPaths{blockIndex} = emPaths(trialIndicesForBlock,:,:);
    end
    
    % From cell array to array
    nTrials = nBlocks*nTrialsPerBlock;
    conesNum = numel(nonNullConeIndices);
    timeBinsNum = size(emPaths,2);
    
    % Preallocate memory
    theConeExcitations = zeros(nTrials, conesNum, timeBinsNum);
    thePhotoCurrents = theConeExcitations;
    theEyeMovementsPaths = emPaths*0;
    size(theConeExcitations)
    for blockIndex = 1:nBlocks
        % compute responses for this block's trials
        trialIndicesForBlock = (blockIndex-1)*nTrialsPerBlock + (1:nTrialsPerBlock);
        theConeExcitations(trialIndicesForBlock,:,:) = coneExcitations{blockIndex}; coneExcitations{blockIndex} = [];
        thePhotoCurrents(trialIndicesForBlock,:,:) = photoCurrents{blockIndex}; photoCurrents{blockIndex} = [];
        theEyeMovementsPaths(trialIndicesForBlock,:,:) = eyeMovementPaths{blockIndex}; eyeMovementPaths{blockIndex} = [];
    end
    size(theConeExcitations)

    
end

function allTrialsMatrix = reformatAllTrialsMatrix(allTrialsMatrix, nonNullConesIndices)

    [trialsNum, coneRows, coneCols, timePointsNum] = size(allTrialsMatrix);

    allTrialsMatrix = permute(allTrialsMatrix, [2 3 1 4]);
    allTrialsMatrix = reshape(allTrialsMatrix, ...
        [coneRows * coneCols, trialsNum, timePointsNum]);

    % Only get the absorptions for the non-null cones
    allTrialsMatrix = allTrialsMatrix(nonNullConesIndices, :, :);

    % Reshape to [instances x cones x timePoints]
    allTrialsMatrix = permute(allTrialsMatrix, [2 1 3]);
end
    
function generateAllOpticalImages(lowFrequencyScenes, highFrequencyScenes, lowFrequencyScenesOrtho, highFrequencyScenesOrtho, contrastLevels, noiseInstances, resourcesDir)
    nContrasts = numel(contrastLevels);
    theOI = oiCreate('wvf human');
    
    for theContrastLevel = 1:nContrasts
        for theInstance = 1:noiseInstances       
            lowFrequencyOIs{theContrastLevel, theInstance} = oiCompute(theOI, ...
            lowFrequencyScenes{theContrastLevel, theInstance});
        
            lowFrequencyOIsOrtho{theContrastLevel, theInstance} = oiCompute(theOI, ...
            lowFrequencyScenesOrtho{theContrastLevel, theInstance});
        
            highFrequencyOIs{theContrastLevel, theInstance} = oiCompute(theOI, ...
            highFrequencyScenes{theContrastLevel, theInstance});
        
            highFrequencyOIsOrtho{theContrastLevel, theInstance} = oiCompute(theOI, ...
            highFrequencyScenesOrtho{theContrastLevel, theInstance});
        end
    end
    
    fName = fullfile(resourcesDir, 'ois.mat');
    save(fName, 'lowFrequencyOIs', 'highFrequencyOIs', ...
         'lowFrequencyOIsOrtho', 'highFrequencyOIsOrtho', 'contrastLevels', 'noiseInstances', '-v7.3');        
end

function generateAllScenes(noiseInstances, stimulusSizeDegs, meanLuminanceCdPerM2, contrastLevels, resourcesDir)
   
    viewingDistance = 75/100;
    
    % Generate stimulus spatial modulations
    noiseNorm = nan;
    
    
    nContrasts = numel(contrastLevels);
    oriDegs = 0;
    
    
    [lowFrequencySpatialModulations, lowFrequencySpatialModulationsOrtho, spatialSupportDegs, noiseNorm] = ...
        generateStimulusSpatialModulation(stimulusSizeDegs, noiseNorm, 'low frequency', oriDegs, contrastLevels, noiseInstances);
    [highFrequencySpatialModulations, highFrequencySpatialModulationsOrtho, spatialSupportDegs, noiseNorm] = ...
        generateStimulusSpatialModulation(stimulusSizeDegs, noiseNorm, 'high frequency', oriDegs, contrastLevels, noiseInstances);
 
    % Display spatial modulations
    displaySpatialModulations(lowFrequencySpatialModulations, lowFrequencySpatialModulationsOrtho, ...
                    highFrequencySpatialModulations, highFrequencySpatialModulationsOrtho);
                
    
    % Generate ISETBio display
    presentationDisplay = generateDisplay(viewingDistance, 4*meanLuminanceCdPerM2);
    
    % Generate ISETBio scenes from spatial modulations
    for theContrastLevel = 1:nContrasts
        for theInstance = 1:noiseInstances 
            
            lowFrequencyScenes{theContrastLevel, theInstance} = generateScene(...
                squeeze(lowFrequencySpatialModulations(theInstance, theContrastLevel,:,:,:)), ...
                presentationDisplay,stimulusSizeDegs, meanLuminanceCdPerM2);
            
            lowFrequencyScenesOrtho{theContrastLevel, theInstance} = generateScene(...
                squeeze(lowFrequencySpatialModulationsOrtho(theInstance, theContrastLevel,:,:,:)), ...
                presentationDisplay,stimulusSizeDegs, meanLuminanceCdPerM2);
             
            highFrequencyScenes{theContrastLevel, theInstance} = generateScene(...
                squeeze(highFrequencySpatialModulations(theInstance, theContrastLevel,:,:,:)), ...
                presentationDisplay,stimulusSizeDegs, meanLuminanceCdPerM2);
 
            highFrequencyScenesOrtho{theContrastLevel, theInstance} = generateScene(...
                squeeze(highFrequencySpatialModulationsOrtho(theInstance, theContrastLevel,:,:,:)), ...
                presentationDisplay,stimulusSizeDegs, meanLuminanceCdPerM2);
        end
    end
   
    fName = fullfile(resourcesDir, 'scenes.mat');
    save(fName, 'lowFrequencyScenes', 'highFrequencyScenes', ...
         'lowFrequencyScenesOrtho', 'highFrequencyScenesOrtho', 'contrastLevels', 'noiseInstances', '-v7.3');
end


function realizedScene = generateScene(theStimulusSpatialModulation,presentationDisplay,stimulusSizeDegs, meanLuminanceCdPerM2)
    realizedScene = sceneFromFile(theStimulusSpatialModulation, 'rgb', ...
                meanLuminanceCdPerM2, presentationDisplay);
    realizedScene = sceneSet(realizedScene, 'fov', stimulusSizeDegs);
end

function displaySpatialModulations(lowFrequencySpatialModulations, lowFrequencySpatialModulationsOrtho, ...
                    highFrequencySpatialModulations, highFrequencySpatialModulationsOrtho)

    nContrasts = size(lowFrequencySpatialModulations,2);
    
    showAllStimuli = ~true;
    if (showAllStimuli)
        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'colsNum', 4, ...
           'rowsNum', nContrasts, ...
           'heightMargin',  0.03, ...
           'widthMargin',    0.03, ...
           'leftMargin',     0.03, ...
           'rightMargin',    0.03, ...
           'bottomMargin',   0.03, ...
           'topMargin',      0.04);
   
        for theNoiseInstance = 1:noiseInstances
            hFig = figure(1000 + theNoiseInstance); clf;
            set(hFig, 'Position', [10 10 1000 760]);

            for iContrast = 1:nContrasts
            subplot('Position', subplotPosVectors(iContrast,1).v);
            imshow(squeeze(lowFrequencySpatialModulations(theNoiseInstance, iContrast,:,:,:)), [0 1]);
            axis 'image'

            subplot('Position', subplotPosVectors(iContrast,2).v);
            imshow(squeeze(lowFrequencySpatialModulationsOrtho(theNoiseInstance, iContrast,:,:,:)), [0 1]);
            axis 'image'

            subplot('Position', subplotPosVectors(iContrast,3).v);
            imshow(squeeze(highFrequencySpatialModulations(theNoiseInstance, iContrast,:,:,:)), [0 1]);
            axis 'image'

            subplot('Position', subplotPosVectors(iContrast,4).v);
            imshow(squeeze(highFrequencySpatialModulationsOrtho(theNoiseInstance, iContrast,:,:,:)), [0 1]);
            axis 'image'
            end
        end

        colormap(gray(1024));
    end
end

function displayLuminanceProfiles(lowFrequencyScenes, highFrequencyScenes, contrastLevels, noiseInstances)

    nContrasts = numel(contrastLevels);
    for theContrastLevel = 1:nContrasts
        for theInstance = 1:noiseInstances 
            realizedScene = lowFrequencyScenes{theContrastLevel, theInstance};
            lumMap1(theInstance, theContrastLevel,:,:) = sceneGet(realizedScene, 'luminance');

            realizedScene = highFrequencyScenes{theContrastLevel, theInstance};
            lumMap2(theInstance, theContrastLevel,:,:) = sceneGet(realizedScene, 'luminance');
        end
    end


    fovDegs = sceneGet(realizedScene, 'horizontal fov');
    cols = sceneGet(realizedScene, 'cols');

    sampleSpacing = fovDegs / cols;
    spatialSupportDegs = (1:cols)*sampleSpacing;
    spatialSupportDegs = spatialSupportDegs - mean(spatialSupportDegs);
        
    nContrasts = size(lumMap1,2);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', nContrasts, ...
       'colsNum', 2, ...
       'heightMargin',  0.03, ...
       'widthMargin',    0.03, ...
       'leftMargin',     0.03, ...
       'rightMargin',    0.03, ...
       'bottomMargin',   0.03, ...
       'topMargin',      0.04);
   
    
    N = round(size(lumMap1,3)/2);
    CLim = [0 max([max(lumMap1(:)) max(lumMap2(:))])];
    

    figure(555);
    colormap(gray);
    for theContrastLevel = 1:nContrasts 
        subplot('Position', subplotPosVectors(theContrastLevel,1).v);
        imagesc(spatialSupportDegs, spatialSupportDegs, squeeze(lumMap1(1,theContrastLevel,:,:)));
        set(gca, 'CLim', CLim);
        axis 'image';
        
        
        subplot('Position', subplotPosVectors(theContrastLevel,2).v);
        meanSpatialProfile = mean(squeeze(lumMap1(:, theContrastLevel, N, :)),1);
        
        plot(spatialSupportDegs, meanSpatialProfile, 'rs-');
        axis 'square'
        set(gca, 'YLim', CLim);
        drawnow
    end
    
    figure(666);
    colormap(gray);
    for theContrastLevel = 1:nContrasts 
        subplot('Position', subplotPosVectors(theContrastLevel,1).v);
        imagesc(spatialSupportDegs, spatialSupportDegs, squeeze(lumMap2(1,theContrastLevel,:,:)));
        set(gca, 'CLim', CLim);
        axis 'image';
        
        subplot('Position', subplotPosVectors(theContrastLevel,2).v);
        meanSpatialProfile = mean(squeeze(lumMap2(:, theContrastLevel, N, :)),1);
        plot(spatialSupportDegs, meanSpatialProfile, 'rs-');
        axis 'square'
        set(gca, 'YLim', CLim);
        drawnow
    end
    
end

function [stimulusSpatialModulation, stimulusSpatialModulationOrtho, spatialSupportDegs, noiseNorm] = ...
    generateStimulusSpatialModulation(stimulusSizeDegs, noiseNorm, stimulusType, oriDegs, contrastLevels, noiseInstances)

    coneApertureMicrons = 2; micronsPerDegree = 300;
    stimulusPixelSizeArcMin = 0.75*coneApertureMicrons / micronsPerDegree * 60;
    stimulusWidthArcMin = stimulusSizeDegs * 60;
    
    % Grating params
    gratingParams.oriDegs = oriDegs;
    gratingParams.sigmaArcMin = stimulusSizeDegs/7*60;
    gratingParams.contrastLevels = contrastLevels;
    % Noise params
    noiseParams.steepness = 100;

    switch (stimulusType)
        case 'low frequency'
            gratingParams.sfCPD = 4;
            noiseParams.spectrumShape = 'highPassCornerFreq';
            noiseParams.cornerFrequencyCPD = 10;
        case 'high frequency'
            gratingParams.sfCPD = 11;
            noiseParams.spectrumShape = 'lowPassCornerFreq';
            noiseParams.cornerFrequencyCPD = 5;
        otherwise
            error('Unknown stimulus type: ''%s''.', stimulusType);
    end
    
    
    figNo = 1;
    [stimStruct, noiseNorm] = ...
        generateGratingInNoiseSpatialModulationPattern(...
        stimulusWidthArcMin, stimulusPixelSizeArcMin,  ...
        gratingParams, noiseParams, noiseNorm, noiseInstances, figNo);
    
    spatialSupportDegs = stimStruct.spatialSupportDegs;
    
    % Normalize to [0 .. 1]
    stimulusSpatialModulation(:,:,:,:,1) = (squeeze(stimStruct.image(:,:,:,:)) + 1)/2;
    stimulusSpatialModulation(:,:,:,:,2) = stimulusSpatialModulation(:,:,:,:,1);
    stimulusSpatialModulation(:,:,:,:,3) = stimulusSpatialModulation(:,:,:,:,1);
    
    stimulusSpatialModulationOrtho(:,:,:,:,1) = (squeeze(stimStruct.imageOrtho(:,:,:,:)) + 1)/2;
    stimulusSpatialModulationOrtho(:,:,:,:,2) = stimulusSpatialModulationOrtho(:,:,:,:,1);
    stimulusSpatialModulationOrtho(:,:,:,:,3) = stimulusSpatialModulationOrtho(:,:,:,:,1);
end


function d = generateDisplay(viewingDistance, maxLuminance)
    d = displayCreate('LCD-Apple', 'viewing distance', viewingDistance);
    d = displaySet(d, 'gTable', 'linear');
    
    scaleFactor = maxLuminance/displayGet(d,'peak luminance');
    if (scaleFactor > 1)
        spd = displayGet(d,'spd');
        spd = spd * scaleFactor;
        d = displaySet(d, 'spd', spd);
    end
    
    peakLum = displayGet(d,'peak luminance');
    
end
