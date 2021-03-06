function run_ConditionToVisualizeMosaic
% This is the script used to just visualize responses

    % How to split the computation
    % 0 (All mosaics), 1; (Largest mosaic), 2 (Second largest), 3 (all 2 largest)
    computationInstance = 8;
    
    % Mosaic to use (ecc-based cone density AND cone efficiency)
    mosaicName = 'ISETbioHexEccBasedLMSrealisticEfficiencyCorrection'; 
    
    % Optics to use
    opticsName = 'ThibosDefaultSubject3MMPupil';
    
    params = getCSFpaperDefaultParams(mosaicName, computationInstance);
    
    % Adjust any params we want to change from their default values
    params.opticsModel = opticsName;
    params.coneContrastDirection = 'L+M+S';
    
    % Simulation steps to perform
    params.computeResponses = ~true;
    params.computeMosaic = ~true; 
    params.visualizeMosaic = true;
    
    params.computePhotocurrentResponseInstances = ~true;
    params.visualizeDisplay = ~true;
    params.visualizeResponses = ~true;
    params.visualizeSpatialScheme = true;
    params.visualizeOIsequence = ~true;
    params.visualizeOptics = ~true;
    params.visualizeStimulusAndOpticalImage = true;
    params.visualizeSpatialPoolingScheme = true;
    params.visualizeMosaicWithFirstEMpath = ~true;
    
    params.visualizeKernelTransformedSignals = true;
    params.findPerformance = ~true;
    params.visualizePerformance = ~true;
    params.deleteResponseInstances = ~true;

    params.performanceClassifier = 'svmV1FilterBank';
    params.performanceClassifier = 'svmV1FilterEnsemble';
    params.parforWorkersNumForClassification = 1;
    
    if (strcmp(params.performanceClassifier,'svmV1FilterEnsemble'))
        params.spatialPoolingKernelParams.spatialPositionsNum = 9;
        params.spatialPoolingKernelParams.cyclesPerRFs =  [1.5 2.5];
        params.spatialPoolingKernelParams.orientations =  [0];
    else
        params.spatialPoolingKernelParams.type = 'V1CosUnit';
        params.spatialPoolingKernelParams.activationFunction = 'fullWaveRectifier';
    end

    
    % Go
    run_BanksPhotocurrentEyeMovementConditions(params);
end