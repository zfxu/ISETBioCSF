function run_GeislerOpticsBanksMosaicConditions(computationInstance)
    
    % 'WvfHuman', 'Geisler'
    opticsModel = 'Geisler';
    imagePixels = 1024;
    
    % 'random'; 'frozen0';
    emPathType = 'frozen0'; %random'; %'random';     
    centeredEMPaths = false;
   
    % Use a subset of the trials. Specify [] to use all available trials
    nTrainingSamples = 1024;
  
    % Mosaic params
    coneSpacingMicrons = 3.0;
    innerSegmentDiameter = 3.0;    % for a circular sensor
    conePacking = 'hexReg';
    LMSRatio = [0.67 0.33 0];
    mosaicRotationDegs = 30;
    integrationTimeMilliseconds =  5.0;
    
    % response params
    responseStabilizationMilliseconds = 10;
    responseExtinctionMilliseconds = 50;
    
    % Conditions 
    lowContrast = 0.0001;
    highContrast = 0.3;
    nContrastsPerDirection =  18;
    luminancesExamined =  [34];
    
    % 'isomerizations', 'photocurrents'
    performanceSignal = 'isomerizations';
    
     %'mlpt'% 'svmV1FilterBank';
    performanceClassifier = 'mlpt';
    
    % Freeze noise for repeatable results
    freezeNoise = true;
    
    % What to do ?
    computeMosaic = true; 
    visualizeMosaic = ~true;
    
    computeResponses = true;
    computePhotocurrentResponseInstances = ~true;
    visualizeResponses = ~true;
    visualizeSpatialScheme = ~true;
    
    visualizeKernelTransformedSignals = ~true;
    findPerformance = true;
    visualizePerformance = true;
    
    % If we do not need the response instances, set this to true
    deleteResponseInstances = ~true;
    
    
    % Split computations and specify RAM memory
    if (computationInstance == 0)
        % All conditions in 1 MATLAB session
        ramPercentageEmployed = 1.0;  % use all the RAM
        cyclesPerDegreeExamined =  [2.5 5 10 20 40 50];
    elseif (computationInstance  == 1)
        % First half of the conditions in session 1 of 2 parallel MATLAB sessions
        ramPercentageEmployed = 0.9;  % use 90% of the RAM
        cyclesPerDegreeExamined =  [2.5];
    elseif (computationInstance  == 2)
        % Second half of the conditions in session 2 of 2 parallel MATLAB sessions
        ramPercentageEmployed = 0.5;  % use 1/2 the RAM
        cyclesPerDegreeExamined =  [5.0];
    elseif (computationInstance  == 3)
        % Second half of the conditions in session 2 of 2 parallel MATLAB sessions
        ramPercentageEmployed = 0.5;  % use 1/2 the RAM
        cyclesPerDegreeExamined =  [10 20 40 50];
    end
    
    
    if (deleteResponseInstances)
        c_BanksEtAlPhotocurrentAndEyeMovements(...
            'opticsModel', opticsModel, ...
            'imagePixels', imagePixels, ...
            'cyclesPerDegree', cyclesPerDegreeExamined, ...
            'luminances', luminancesExamined, ...
            'nTrainingSamples', nTrainingSamples, ...
            'lowContrast', lowContrast, ...
            'highContrast', highContrast, ...
            'nContrastsPerDirection', nContrastsPerDirection, ...
            'ramPercentageEmployed', ramPercentageEmployed, ...
            'emPathType', emPathType, ...
            'centeredEMPaths', centeredEMPaths, ...
            'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
            'freezeNoise', freezeNoise, ...
            'integrationTime', integrationTimeMilliseconds/1000, ...
            'coneSpacingMicrons', coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', sizeForSquareApertureFromDiameterForCircularAperture(innerSegmentDiameter), ...
            'conePacking', conePacking, ...
            'LMSRatio', LMSRatio, ...
            'mosaicRotationDegs', mosaicRotationDegs, ...
            'computeMosaic', false, ...
            'visualizeMosaic', false, ...
            'computeResponses', false, ...
            'computePhotocurrentResponseInstances', false, ...
            'visualizeResponses', false, ...
            'visualizeSpatialScheme', false, ...
            'findPerformance', false, ...
            'visualizePerformance', false, ...
            'deleteResponseInstances', true);
        return;
    end
    
    if (computeResponses) || (visualizeResponses) || (visualizeMosaic)
        c_BanksEtAlPhotocurrentAndEyeMovements(...
            'opticsModel', opticsModel, ...
            'imagePixels', imagePixels, ...
            'cyclesPerDegree', cyclesPerDegreeExamined, ...
            'luminances', luminancesExamined, ...
            'nTrainingSamples', nTrainingSamples, ...
            'lowContrast', lowContrast, ...
            'highContrast', highContrast, ...
            'nContrastsPerDirection', nContrastsPerDirection, ...
            'ramPercentageEmployed', ramPercentageEmployed, ...
            'emPathType', emPathType, ...
            'centeredEMPaths', centeredEMPaths, ...
            'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
            'freezeNoise', freezeNoise, ...
            'integrationTime', integrationTimeMilliseconds/1000, ...
            'coneSpacingMicrons', coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', sizeForSquareApertureFromDiameterForCircularAperture(innerSegmentDiameter), ...
            'conePacking', conePacking, ...
            'LMSRatio', LMSRatio, ...
            'mosaicRotationDegs', mosaicRotationDegs, ...
            'computeMosaic',computeMosaic, ...
            'visualizeMosaic', visualizeMosaic, ...
            'computeResponses', computeResponses, ...
            'computePhotocurrentResponseInstances', computePhotocurrentResponseInstances, ...
            'visualizeResponses', visualizeResponses, ...
            'visualizeSpatialScheme', visualizeSpatialScheme, ...
            'findPerformance', false, ...
            'visualizePerformance', false, ...
            'performanceSignal' , performanceSignal, ...
            'performanceClassifier', performanceClassifier ...
        );
    end
    
    
    if (findPerformance) || (visualizePerformance)
            perfData = c_BanksEtAlPhotocurrentAndEyeMovements(...
                'opticsModel', opticsModel, ...
                'imagePixels', imagePixels, ...
                'cyclesPerDegree', cyclesPerDegreeExamined, ...
                'luminances', luminancesExamined, ...
                'nTrainingSamples', nTrainingSamples, ...
                'nContrastsPerDirection', nContrastsPerDirection, ...
                'lowContrast', lowContrast, ...
                'highContrast', highContrast, ...
                'ramPercentageEmployed', ramPercentageEmployed, ...
                'emPathType', emPathType, ...
                'centeredEMPaths', centeredEMPaths, ...
                'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
                'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
                'freezeNoise', freezeNoise, ...
                'integrationTime', integrationTimeMilliseconds/1000, ...
                'coneSpacingMicrons', coneSpacingMicrons, ...
                'innerSegmentSizeMicrons', sizeForSquareApertureFromDiameterForCircularAperture(innerSegmentDiameter), ...
                'conePacking', conePacking, ...
                'LMSRatio', LMSRatio, ...
                'mosaicRotationDegs', mosaicRotationDegs, ...
                'computeMosaic', false, ...
                'visualizeMosaic', false, ...
                'computeResponses', false, ...
                'visualizeResponses', false, ...
                'visualizeSpatialScheme', visualizeSpatialScheme, ...
                'findPerformance', findPerformance, ...
                'visualizePerformance', visualizePerformance, ...
                'visualizeKernelTransformedSignals', visualizeKernelTransformedSignals, ...
                'parforWorkersNumForClassification', 4, ...
                'performanceSignal' , performanceSignal, ...
                'performanceClassifier', performanceClassifier, ...
                'performanceTrialsUsed', nTrainingSamples ...
                );
            thresholds = perfData.mlptThresholds.thresholdContrasts
    end
end

