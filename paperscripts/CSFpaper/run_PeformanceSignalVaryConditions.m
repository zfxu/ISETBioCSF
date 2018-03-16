function run_PeformanceSignalVaryConditions
% This is the script used to assess the impact of different types of eye movements on the CSF
%  
    % How to split the computation
    % 0 (All mosaics), 1; (Largest mosaic), 2 (Second largest), 3 (all 2 largest)
    computationInstance = 1;
    
    % Whether to make a summary figure with CSF from all examined conditions
    makeSummaryFigure = ~true;
    
    % Mosaic to use
    mosaicName = 'ISETbioHexEccBasedLMSrealistic'; 
    
    % Optics to use
    opticsName = 'ThibosBestPSFSubject3MMPupil';
    
    params = getCSFpaperDefaultParams(mosaicName, computationInstance);
    
    % Adjust any params we want to change from their default values
    params.opticsModel = opticsName;
    
    % Response duration params
    params.frameRate = 20; %(2 frames)
    params.responseStabilizationMilliseconds = 100;
    params.responseExtinctionMilliseconds = 50;
    
    % Eye movement setup
    params.emPathType = 'random';
    params.centeredEMPaths = true;
    
    % Performance classifier
    params.performanceClassifier = 'svmV1FilterBank';
    
    examinedSignals = {...
        'isomerizations' ...
        'photocurrents' ...
    };
    examinedSignals = {examinedSignals{1}};
    
    examinedSignalLabels = {...
        'isomerizations' ...
        'photocurrents' ...
    };
    
    % Simulation steps to perform
    params.computeMosaic = ~true; 
    params.visualizeMosaic = ~true;
    
    params.computeResponses = true;
    params.computePhotocurrentResponseInstances = true;
    params.visualizeResponses = true;
    params.visualizeSpatialScheme = ~true;
    params.visualizeOIsequence = ~true;
    params.visualizeOptics = ~true;
    params.visualizeMosaicWithFirstEMpath = true;
    
    params.visualizeKernelTransformedSignals = true;
    params.findPerformance = true;
    params.visualizePerformance = true;
    params.deleteResponseInstances = ~true;
    
    % Go
  	for signalIndex = 1:numel(examinedSignals)
        params.performanceSignal = examinedSignals{signalIndex};
        [~,~, theFigData{signalIndex}] = run_BanksPhotocurrentEyeMovementConditions(params);
    end
end