function generateLargeMosaicInSteps
    mosaicFOV = 30;
    minPositionChangeToTriggerTriangularization = nan; 
    visualizationUpdateIterations = 1;

    mosaicParams = struct(...
        'resamplingFactor', 5, ...
        'fovDegs', mosaicFOV, ...
        'LMSRatio', [0.60 0.30 0.10], ...
        'sConeMinDistanceFactor', 3, ...
        'sConeFreeRadiusMicrons', 45, ...
        'latticeAdjustmentPositionalToleranceF', minPositionChangeToTriggerTriangularization, ...
        'latticeAdjustmentDelaunayToleranceF', 1e-3, ...
        'queryGridAdjustmentIterations', Inf, ...           % Pass Inf, to avoid querying
        'queryAdditionnalPassBatch', true, ...
        'visualizationUpdateIterations', visualizationUpdateIterations, ...
        'maxGridAdjustmentIterations', 50, ...
        'marginF',[]....
        );

    theMosaic = coneMosaicHex(mosaicParams.resamplingFactor, ...
        'fovDegs',                       mosaicParams.fovDegs, ...
        'spatialDensity',                [0 mosaicParams.LMSRatio]', ...
        'sConeMinDistanceFactor',        mosaicParams.sConeMinDistanceFactor, ...
        'sConeFreeRadiusMicrons',        mosaicParams.sConeFreeRadiusMicrons, ...
        'eccBasedConeDensity',           true, ...                                  % cone density varies with eccentricity
        'eccBasedConeQuantalEfficiency', true, ...                                  % cone quantal efficiency varies with eccentricity
        'latticeAdjustmentPositionalToleranceF',mosaicParams.latticeAdjustmentPositionalToleranceF, ...
        'latticeAdjustmentDelaunayToleranceF',  mosaicParams.latticeAdjustmentDelaunayToleranceF, ...
        'marginF',                              mosaicParams.marginF, ...
        'queryGridAdjustmentIterations',        mosaicParams.queryGridAdjustmentIterations, ...
        'queryAdditionnalPassBatch',            mosaicParams.queryAdditionnalPassBatch, ...
        'visualizationUpdateIterations',        mosaicParams.visualizationUpdateIterations, ...
        'maxGridAdjustmentIterations',          mosaicParams.maxGridAdjustmentIterations, ...
        'useParfor', true);
    
    
    theMosaic.visualizeGrid('ticksInVisualDegs', true);
    mosaicFileName = sprintf('ConeMosaic_%2.1fDegs_PosTolerance%2.2f', mosaicFOV, mosaicParams.latticeAdjustmentPositionalToleranceF);
    
    % Print final figure
    hFig = figure(111);
    NicePlot.exportFigToPDF(sprintf('%s.pdf',mosaicFileName), hFig, 300);
    
    % Save mosaic
    mosaicFileName = sprintf('%s.mat',mosaicFileName);
    version = '-v7.3';
    save(mosaicFileName, 'theMosaic', version);
    fprintf('Mosaic saved in ''%s''.\n', mosaicFileName);
    
end

