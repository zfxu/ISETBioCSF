function run_paper2InferenceEngine
% Compute and contrast performance via different inference engines.
%
% Syntax:
%   run_paper2InferenceEngine
%
% Description:
%    Compute and contrast performance via different inference engines.
%
%    The computation is done via the ecc-based cone efficiency & macular pigment
%    mosaic and the default Thibos subject. We use a 5 msec integration
%    time but we will examine the effect of shorter integration times. 
%
% Inputs:
%    None.
%
% Outputs:
%    None.
%
% Optional key/value pairs:
%    None.
%

% History
%    01/31/19  npc  Wrote it.

    % How to split the computation
    % 0 (All mosaics), 1; (Largest mosaic), 2 (Second largest), 3 (all but
    % the 2 largest), or some specific spatial frequency, like 16
    computationInstance = 0;
    
    % Whether to make a summary figure with CSF from all examined conditions
    makeSummaryFigure = true;
    
    % Whether to compute responses
    computeMosaic = ~true;
    computeResponses = ~true;
    visualizeResponses = ~true;
    findPerformance = ~true;
    visualizePerformance = true;
    
    % Pupil diameter to be used
    pupilDiamMm = 3.0;
    
    % Integration time to use: Here set to 5.0 ms, but 2.5 ms may be better 
    % for capturing the dynamics of fixationalEM
    integrationTimeMilliseconds = 5.0;
    
    % How long the stimulus is. We might be changing the duration. 100 ms is the default
    stimulusDurationInSeconds = 100/1000;
    % Frame rate in Hz. 10 Hz, so each frame is 100 msec long
    % Will need to change this to study shorter stimulus durations.
    frameRate = 10; 
    
    % Compute photocurrent responses
    computePhotocurrents = true;
    
    performanceSignal =  'photocurrents';
    emPathType = 'randomNoSaccades';
    centeredEMPaths =  'atStimulusModulationMidPoint';
    
    % * * * * * * * * * * * * * * * 
    nTrainingSamples = 1016;        
    opticalImagePadSizeDegs = 0.7;   
    lowContrast = 0.01;
    highContrast = 1.0;
    nContrastsPerDirection = 10;
    parforWorkersNum = 20;
    % * * * * * * * * * * * * * * * 
    
    
    % Assemble conditions list to be examined
    % Init condition index
    condIndex = 0;
    
    if (1==2)
        condIndex = condIndex+1;
        examinedCond(condIndex).label = 'stim-matched, no EM';
        examinedCond(condIndex).minimumMosaicFOVdegs = [];  % no minimum mosaic size, so spatial pooling is matched to stimulus
        examinedCond(condIndex).performanceClassifier = 'svmV1FilterBank';
        examinedCond(condIndex).spatialPoolingKernelParams.type = 'V1QuadraturePair';
        examinedCond(condIndex).spatialPoolingKernelParams.activationFunction = 'energy';
        examinedCond(condIndex).performanceSignal = performanceSignal;
        examinedCond(condIndex).emPathType = 'frozen0';
        examinedCond(condIndex).centeredEMPaths = true;
    end
%    
    

    condIndex = condIndex+1;
    examinedCond(condIndex).label = 'stim-matched, drift';
    examinedCond(condIndex).minimumMosaicFOVdegs = [];  % no minimum mosaic size, so spatial pooling is matched to stimulus
    examinedCond(condIndex).performanceClassifier = 'svmV1FilterBank';
    examinedCond(condIndex).spatialPoolingKernelParams.type = 'V1QuadraturePair';
    examinedCond(condIndex).spatialPoolingKernelParams.activationFunction = 'energy';
    examinedCond(condIndex).performanceSignal = performanceSignal;
    examinedCond(condIndex).emPathType = emPathType;
    examinedCond(condIndex).centeredEMPaths = centeredEMPaths;
    
    
    
    condIndex = condIndex+1;
    examinedCond(condIndex).label = '0.3 degs, drift';
    examinedCond(condIndex).minimumMosaicFOVdegs = 0.328;   % stimuli smaller than this, will use spatial pooling based on this mosaic size
    examinedCond(condIndex).performanceClassifier = 'svmV1FilterBank';
    examinedCond(condIndex).spatialPoolingKernelParams.type = 'V1QuadraturePair';
    examinedCond(condIndex).spatialPoolingKernelParams.activationFunction = 'energy';
    examinedCond(condIndex).performanceSignal = performanceSignal;
    examinedCond(condIndex).emPathType = emPathType;
    examinedCond(condIndex).centeredEMPaths = centeredEMPaths;
    examinedCond(condIndex).ensembleFilterParams = struct(...
                    'spatialPositionsNum',  0, ...   % 1 results in a 3x3 grid, 2 in 5x5
                    'spatialPositionOffsetDegs', 0, ... 
                    'cyclesPerRFs', 0, ...           % each template contains 5 cycles of the stimulus
                    'orientations', 0);
    

    startingCondIndexForEnsemble = condIndex;

%     condIndex = condIndex+1;
%     examinedCond(condIndex).label = '0.5 degs, drift';
%     examinedCond(condIndex).minimumMosaicFOVdegs = 0.492;   % stimuli smaller than this, will use spatial pooling based on this mosaic size
%     examinedCond(condIndex).performanceClassifier = 'svmV1FilterBank';
%     examinedCond(condIndex).spatialPoolingKernelParams.type = 'V1QuadraturePair';
%     examinedCond(condIndex).spatialPoolingKernelParams.activationFunction = 'energy';
%     examinedCond(condIndex).performanceSignal = performanceSignal;
%     examinedCond(condIndex).emPathType = emPathType;
%     examinedCond(condIndex).centeredEMPaths = centeredEMPaths;
%     examinedCond(condIndex).ensembleFilterParams = struct(...
%                     'spatialPositionsNum',  0, ...   % 1 results in a 3x3 grid, 2 in 5x5
%                     'spatialPositionOffsetDegs', 0, ... 
%                     'cyclesPerRFs', 0, ...           % each template contains 5 cycles of the stimulus
%                     'orientations', 0);
                 
    
        
    if (~computeResponses)
    
        defaultCond.label = '';
        defaultCond.performanceClassifier = 'svmV1FilterEnsemble';
        defaultCond.minimumMosaicFOVdegs = -0.328;   % nagative sign means that stimuli smaller than this, will use spatial ensemble pooling based on this mosaic size
        defaultCond.spatialPoolingKernelParams.type = 'V1QuadraturePair';
        defaultCond.spatialPoolingKernelParams.activationFunction = 'energy';
        defaultCond.performanceSignal = performanceSignal;
        defaultCond.emPathType = 'randomNoSaccades';
        defaultCond.centeredEMPaths = centeredEMPaths;

        
        defaultCond.ensembleFilterParams = struct(...
                            'spatialPositionsNum',  1, ...           % 1 results in a 3x3 grid, 2 in 5x5
                            'spatialPositionOffsetDegs', 0.0328, ... % cannot save this variation is different data files - not encoded
                            'cyclesPerRFs', [], ...                   % each template contains 5 cycles of the stimulus
                            'orientations', 0);

        spatialPositionOffsetArcMinList = [0.7 0.9 1.1 1.3 1.5 1.7 1.9 2.1];
        cyclesPerRFsList = [6 5.5 5.0 4.5 4.0]; 
        totalPositions = [1 2 3];
       
        
        for m = 1:numel(totalPositions)
        for l = 1:numel(cyclesPerRFsList)
            for k = 1:numel(spatialPositionOffsetArcMinList)
                condIndex = condIndex+1;
                defaultCond.ensembleFilterParams.spatialPositionsNum = totalPositions(m);
                defaultCond.ensembleFilterParams.spatialPositionOffsetDegs = spatialPositionOffsetArcMinList(k)/60;
                defaultCond.ensembleFilterParams.cyclesPerRFs = cyclesPerRFsList(l)+spatialPositionOffsetArcMinList(k)*0.1;  % encode variation in offset (k) in the cycles
                examinedCond(condIndex) = defaultCond;
                examinedCond(condIndex).label = sprintf('ensemble, drift');
            end
        end
        end
        
    
%         defaultCond.minimumMosaicFOVdegs = -0.492;   % nagative sign means that stimuli smaller than this, will use spatial ensemble pooling based on this mosaic size
%         defaultCond.ensembleFilterParams = struct(...
%                             'spatialPositionsNum',  2, ...   % 1 results in a 3x3 grid, 2 in 5x5
%                             'spatialPositionOffsetDegs', 0.025, ... 
%                             'cyclesPerRFs', 0, ...           % each template contains 5 cycles of the stimulus
%                             'orientations', 0);
%         for i = 1:numel(cyclesPerRFlist)
%             condIndex = condIndex+1;
%             cyclesPerRF = cyclesPerRFlist(i); 
%             posNum = defaultCond.ensembleFilterParams.spatialPositionsNum;
%             examinedCond(condIndex) = defaultCond;
%             examinedCond(condIndex).label = sprintf('%2.1f degs, %2.0fx%2.0f, %2.1f', abs(defaultCond.minimumMosaicFOVdegs), 2*posNum+1, 2*posNum+1, cyclesPerRF);
%             examinedCond(condIndex).ensembleFilterParams.cyclesPerRFs = cyclesPerRF;
%         end                
                               
    end
    
                  
    % Go
    examinedLegends = {};

    for condIndex = 1:numel(examinedCond)
        % Get default params
        params = getCSFPaper2DefaultParams(pupilDiamMm, integrationTimeMilliseconds, frameRate, stimulusDurationInSeconds, computationInstance);
        params.cyclesPerDegreeExamined = [32 40 50 60];
        params.opticalImagePadSizeDegs = opticalImagePadSizeDegs;
        
        params.lowContrast = lowContrast; 
        params.highContrast =  highContrast; 
        params.nContrastsPerDirection = nContrastsPerDirection;
    
        params.parforWorkersNum = parforWorkersNum;
        params.parforWorkersNumForClassification = 20;
        
        % Update params
        cond = examinedCond(condIndex);
        params.performanceClassifier = cond.performanceClassifier;
        params.performanceSignal = cond.performanceSignal;
        params.emPathType = cond.emPathType;
        params.centeredEMPaths = cond.centeredEMPaths;
        params.nTrainingSamples = nTrainingSamples;
        
        examinedLegends{numel(examinedLegends) + 1} = cond.label;
    
        if (strcmp(params.performanceClassifier, 'svmV1FilterBank'))
            params.spatialPoolingKernelParams.type = cond.spatialPoolingKernelParams.type;
            params.spatialPoolingKernelParams.activationFunction = cond.spatialPoolingKernelParams.activationFunction;
            params.minimumMosaicFOVdegs = cond.minimumMosaicFOVdegs;
        elseif (strcmp(params.performanceClassifier, 'svmV1FilterEnsemble'))
            params.spatialPoolingKernelParams.type = cond.spatialPoolingKernelParams.type;
            params.spatialPoolingKernelParams.activationFunction = cond.spatialPoolingKernelParams.activationFunction;
            params.minimumMosaicFOVdegs = cond.minimumMosaicFOVdegs;
            fNames = fieldnames(cond.ensembleFilterParams);
            for fNameIndex = 1:numel(fNames)
                fName = fNames{fNameIndex};
                params.spatialPoolingKernelParams.(fName) = cond.ensembleFilterParams.(fName);
            end
        else
            error('Unknown performance classifier: ''%s''.',params.performanceClassifier);
        end
        
        % Update params
        params = getRemainingDefaultParams(params, ...
            computePhotocurrents, computeResponses, computeMosaic, ...
            visualizeResponses, findPerformance, visualizePerformance); 
        
        % Go !
        [~,~, theFigData{condIndex}] = run_BanksPhotocurrentEyeMovementConditions(params);
        close('all');
    end % condIndex
    
   
    if (makeSummaryFigure)
        variedParamName = performanceSignal;
        theRatioLims = [0.65 1.1];
        theRatioTicks = [0.6 0.7 0.8 0.9 1.0 1.1 1.2];
        formatLabel = 'InferenceEngine';
        
        % ===== Replace all the ensemble data for cond = (startingCondIndexForEnsemble+1) .. end with the minTreshold
        for theCondIndex = (startingCondIndexForEnsemble+1):numel(theFigData)
            d = theFigData{theCondIndex};
            d = d.banksEtAlReplicate.mlptThresholds;
            for k = 1:numel(d)
                t(theCondIndex-startingCondIndexForEnsemble,k) = d(k).thresholdContrasts;
            end
        end
        
        % Save the first 3 figData only, replacing the startingCondIndexForEnsemble+1 one with the max
        % sensitivity over all > startingCondIndexForEnsemble+1 conditions
        if (numel(theFigData)>=startingCondIndexForEnsemble+1)
            for k = 1:(startingCondIndexForEnsemble+1)
                theFigData2{k} = theFigData{k};
            end

            % Replace startingCondIndexForEnsemble+1 figData thresholdContrasts with min
            % thresholdContrasts over all conds
            minThresholdContrasts = min(t,[],1);

            d = theFigData2{startingCondIndexForEnsemble+1};
            condsNum = numel(d.banksEtAlReplicate.mlptThresholds);
            for theCondIndex = 1:condsNum
                d.banksEtAlReplicate.mlptThresholds(theCondIndex).thresholdContrasts = minThresholdContrasts(theCondIndex);
            end
            theFigData2{startingCondIndexForEnsemble+1} = d;
             % ===== Replace all the ensemble data ====
        else
            theFigData2 = theFigData;
        end
        
        
        generateFigureForPaper(theFigData2, examinedLegends, variedParamName, formatLabel, ...
            'figureType', 'CSF_high SF range', ...
            'showSubjectData', ~true, ...
            'showSubjectMeanData', ~true, ...
            'plotFirstConditionInGray', true, ...
            'plotRatiosOfOtherConditionsToFirst', true, ...
            'theRatioLims', theRatioLims, ...
            'theRatioTicks', theRatioTicks, ... 
            'theLegendPosition', [0.48,0.85,0.46,0.08], ...    % custom legend position and size
            'paperDir', 'CSFpaper2', ...                        % sub-directory where figure will be exported
            'figureHasFinalSize', true ...                      % publication-ready size
            );
    end
end

function params = getRemainingDefaultParams(params, computePhotocurrents, computeResponses, computeMosaic, visualizeResponses, findPerformance, visualizePerformance)
                         
    % Simulation steps to perform
    params.computeMosaic = computeMosaic; 
    params.visualizeMosaic = ~true;
    
    params.computeResponses = computeResponses;
    params.computePhotocurrentResponseInstances = computePhotocurrents && computeResponses;
    params.visualizeResponses = visualizeResponses;
    params.visualizeResponsesWithSpatialPoolingSchemeInVideo = ~true;
    params.visualizeOuterSegmentFilters = ~true;
    params.visualizeSpatialScheme = ~true;
    params.visualizeOIsequence = ~true;
    params.visualizeOptics = ~true;
    params.visualizeStimulusAndOpticalImage = ~true;
    params.visualizeMosaicWithFirstEMpath = ~true;
    params.visualizeSpatialPoolingScheme = ~true;
    params.visualizeStimulusAndOpticalImage = ~true;
    params.visualizeDisplay = ~true;
    
    params.visualizeKernelTransformedSignals = ~true;
    params.findPerformance = findPerformance;
    params.visualizePerformance = visualizePerformance;
    params.deleteResponseInstances = ~true;
end
