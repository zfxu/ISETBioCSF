function GenerateMosaicEffectCSFs

    % Script to generate the slide with the Banks'87 ideal and human observer data
    
    % 0 (All mosaics), 1; (Largest mosaic), 2 (Second largest), 3 (all 2 largest)
    computationInstance = 0;
    
    % Whether to make a summary figure with CSF from all examined conditions
    makeSummaryFigure = true;
    %makeMosaicsFigure = true;
    
    computeResponses = false;
    findPerformance = false;
    
    % Mosaic to use
    examinedMosaicModels = {...
        'originalBanks' ...
        'ISETbioHexEccBasedLMSrealisticEfficiencyCorrection' ...
        };
 
    examinedMosaicLegends = {...
        'constant LM density (Banks ''87)' ...
        'ecc-based LMS density/efficiency' ...
    };

    % Tun the mosaic-vary condition using the Geisler optics
    opticsName = 'Geisler';
    
    %  Only up to 50 c/deg
    cyclesPerDegreeExamined = [2 4 8 16 32 50];
    
    
    condIndex = 0;
    for k = 1:+numel(examinedMosaicModels)
        condIndex = condIndex + 1;
        examinedConds(condIndex).conditionLabel = examinedMosaicLegends{k};
        examinedConds(condIndex).mosaicName = examinedMosaicModels{k};
        examinedConds(condIndex).opticsModel = opticsName;
        examinedConds(condIndex).inferenceEngine = 'mlpt';
        examinedConds(condIndex).signal = 'isomerizations';
        examinedConds(condIndex).emPathType = 'frozen0';
        examinedConds(condIndex).centeredEMPaths = ~true;
        examinedConds(condIndex).frameRate = 10;
        examinedConds(condIndex).responseStabilizationMilliseconds =  40;
        examinedConds(condIndex).responseExtinctionMilliseconds = 40;
    end
    
    % Go
    [examinedLegends, theFigData, pupilDiamMm] = runConditions(...
        examinedConds, computationInstance, cyclesPerDegreeExamined, computeResponses, findPerformance);
    
    if (makeSummaryFigure)
        variedParamName = 'Mosaic';
        theRatioLims = [0.02 2.0];
        theRatioTicks = [0.05  0.1 0.2 0.5 1.0];
        formatLabel = 'Banks_vs_EccBasedEfficiency'; 
        generateFigureForPaper(theFigData, examinedLegends, variedParamName, formatLabel, ...
            'figureType', 'CSF', ...
            'showSubjectData', (pupilDiamMm == 2), ...
            'showSubjectMeanData', false, ...
            'showLegend', ~true, ...
            'plotFirstConditionInGray', true, ...
            'showBanksPaperIOAcurves', true, ...
            'showOnly23CDM2IOAcurve', true, ...
            'plotRatiosOfOtherConditionsToFirst', false, ...
            'theRatioLims', theRatioLims, ...
            'theRatioTicks', theRatioTicks ...
            );
    end
    
end

function [examinedLegends, theFigData, pupilDiamMm] = runConditions(examinedConds, computationInstance, cyclesPerDegreeExamined, computeResponses, findPerformance)
    examinedLegends = {};
    theFigData = {};
    
    for condIndex = 1:numel(examinedConds)
        cond = examinedConds(condIndex);
        mosaicName = cond.mosaicName;
        params = getCSFpaperDefaultParams(mosaicName, computationInstance);
        
        % Update params
        params.opticsModel = cond.opticsModel;
        params.performanceClassifier = cond.inferenceEngine;
        params.performanceSignal = cond.signal;
        params.emPathType = cond.emPathType;
        params.centeredEMPaths = cond.centeredEMPaths;
        params.frameRate = cond.frameRate;
        params.responseStabilizationMilliseconds = cond.responseStabilizationMilliseconds;
        params.responseExtinctionMilliseconds = cond.responseExtinctionMilliseconds;
        
        if (strcmp(params.performanceClassifier, 'svmV1FilterBank'))
            params.spatialPoolingKernelParams.type = cond.spatialPoolingKernelParams.type;
            params.spatialPoolingKernelParams.activationFunction = cond.spatialPoolingKernelParams.activationFunction;
        end
        
        params = getRemainingDefaultParams(params, condIndex, cond.conditionLabel, cyclesPerDegreeExamined, computeResponses, findPerformance);  
        
        % Update returned items
        pupilDiamMm(condIndex) = params.pupilDiamMm;
        examinedLegends{numel(examinedLegends) + 1} = cond.conditionLabel;
        [~,~, theFigData{condIndex}] = run_BanksPhotocurrentEyeMovementConditions(params);
    end
    
    if (any(diff(pupilDiamMm) ~= 0))
        pupilDiamMm
        error('PuliDiamMM are different for different conditions');
    else
        pupilDiamMm = pupilDiamMm(1);
    end
    
end


function params = getRemainingDefaultParams(params, condIndex, conditionLabel, cyclesPerDegreeExamined, computeResponses, findPerformance)
            
    % Chromatic direction params
    params.coneContrastDirection = 'L+M+S';
    
    % Cycles per degree
    params.cyclesPerDegreeExamined = cyclesPerDegreeExamined;

    
    if (strcmp(conditionLabel, 'Banks mosaic/optics, MLPT, 3mm'))
        params.pupilDiamMm = 3.0;
    else
        params.pupilDiamMm = 2.0;
    end
    
    fprintf('>>>>>> \t %d pupil: %f\n', condIndex, params.pupilDiamMm);
    
                
    % Simulation steps to perform
    params.computeMosaic = ~true; 
    params.visualizeMosaic = ~true;
    
    params.computeResponses = computeResponses;
    params.computePhotocurrentResponseInstances = ~true;
    params.visualizeResponses = ~true;
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
    params.visualizePerformance = true;
    params.deleteResponseInstances = ~true;
end
