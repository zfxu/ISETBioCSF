function V1filterBank = generateV1FilterBank(spatialParams, mosaicParams, topLevelDirParams, visualizeSpatialScheme, v1FilterBankType)
    % Filter width
    filterWidthInDegrees = 0.5*spatialParams.fieldOfViewDegs;
    
    % Load the mosaic
    coneParamsList = {topLevelDirParams, mosaicParams};
    theProgram = 't_coneCurrentEyeMovementsResponseInstances';
    rwObject = IBIOColorDetectReadWriteBasic;
    theMosaic = rwObject.read('coneMosaic', coneParamsList, theProgram, 'type', 'mat');
    
    % Get the cone locs in degrees
    if (strcmp(mosaicParams.conePacking,'rect'))
        coneLocsInMeters = theMosaic.coneLocs;
    else
        coneLocsInMeters = theMosaic.coneLocsHexGrid;
    end
    coneLocsInDegs(:,1) = coneLocsInMeters(:,1) / theMosaic.width * theMosaic.fov(1);
    coneLocsInDegs(:,2) = coneLocsInMeters(:,2) / theMosaic.height * theMosaic.fov(2);
       
    % Find the density map around each cone
    eccInMeters = sqrt(sum(coneLocsInMeters.^2, 2));
    ang = atan2(squeeze(coneLocsInMeters(:,2)), squeeze(coneLocsInMeters(:,1)))/pi*180;
    [~, ~, coneDensity] = coneSize(eccInMeters(:),ang(:));
    
    switch(spatialParams.spatialType)
        case 'Gabor'  
            % Make the stimulus spatial modulation
            spatialPattern = imageHarmonic(imageHarmonicParamsFromGaborParams(spatialParams, 1.0));
            spatialModulation = spatialPattern-1;
            spatialModulation = spatialModulation/max(abs(spatialModulation(:)));
            
        otherwise
            error('Currently generating V1 filter banks for Gabor stimuli only.');
    end  % switch
    
    xaxis = (0:(size(spatialModulation,2)-1))/size(spatialModulation,2) * spatialParams.fieldOfViewDegs;
    xaxis = xaxis - mean(xaxis);
    yaxis = (0:(size(spatialModulation,1)-1))/size(spatialModulation,1) * spatialParams.fieldOfViewDegs;
    yaxis = yaxis - mean(yaxis);
            
    % Generate the V1 filter bank        
    V1filterBank = makeV1filters(spatialParams, filterWidthInDegrees, coneLocsInDegs, xaxis, yaxis, coneDensity, v1FilterBankType);

    if (visualizeSpatialScheme)
        hFig = visualizeSpatialPoolingScheme(xaxis, yaxis, spatialModulation, ...
            V1filterBank, coneLocsInDegs, mosaicParams.fieldOfViewDegs, spatialParams.fieldOfViewDegs);
    end % visualizeSpatialScheme      
end


function V1filterBank = makeV1filters(spatialParams, filterWidthDegs, coneLocsDegs, xaxisDegs, yaxisDegs, coneDensity, v1FilterBankType)

    % filter width
    spatialParams.gaussianFWHMDegs = filterWidthDegs/2.0;
    
    % make the cos-phase filter
    spatialParams.ph = 0;
    cosPhaseFilter = imageHarmonic(imageHarmonicParamsFromGaborParams(spatialParams, 1.0));
    V1filterBank.cosPhasePoolingProfile = cosPhaseFilter-1;
    
    % make the sin-phase filter
    spatialParams.ph = pi/2;
    sinPhaseFilter = imageHarmonic(imageHarmonicParamsFromGaborParams(spatialParams, 1.0));
    V1filterBank.sinPhasePoolingProfile = sinPhaseFilter-1;

    % Compute energy envelope
    RFprofile = sqrt(V1filterBank.cosPhasePoolingProfile.^2 + V1filterBank.sinPhasePoolingProfile.^2);
    V1filterBank.RFprofile = RFprofile / max(abs(RFprofile(:)));
    
    % Find pooling weights
    [X,Y] = meshgrid(xaxisDegs, yaxisDegs);
    rfCoordsDegs = [X(:) Y(:)];
    
    [~, idx] = pdist2(rfCoordsDegs, coneLocsDegs, 'euclidean', 'Smallest', 1);
    V1filterBank.cosPhasePoolingWeights = V1filterBank.cosPhasePoolingProfile(idx);
    V1filterBank.sinPhasePoolingWeights = V1filterBank.sinPhasePoolingProfile(idx);
    
    % Adjust weights by the inverse of the coneDensity
    maxCos = max(abs(V1filterBank.cosPhasePoolingWeights(:)));
    maxSin = max(abs(V1filterBank.sinPhasePoolingWeights(:)));
    V1filterBank.cosPhasePoolingWeights = V1filterBank.cosPhasePoolingWeights ./ coneDensity;
    V1filterBank.sinPhasePoolingWeights = V1filterBank.sinPhasePoolingWeights ./ coneDensity;
    
    V1filterBank.cosPhasePoolingWeights = V1filterBank.cosPhasePoolingWeights / max(abs(V1filterBank.cosPhasePoolingWeights(:))) * maxCos;
    V1filterBank.sinPhasePoolingWeights = V1filterBank.sinPhasePoolingWeights / max(abs(V1filterBank.sinPhasePoolingWeights(:))) * maxSin;
    
    % Normalize with respect to total energy over space
    netWeight = 1/sqrt(2.0) * sqrt(sum(V1filterBank.cosPhasePoolingWeights(:).^2) + sum(V1filterBank.sinPhasePoolingWeights(:).^2));
    V1filterBank.cosPhasePoolingWeights = V1filterBank.cosPhasePoolingWeights/netWeight;
    V1filterBank.sinPhasePoolingWeights = V1filterBank.sinPhasePoolingWeights/netWeight;
    
    if (strcmp(v1FilterBankType, 'svmV1FilterBank'))
        V1filterBank.activationFunction = 'energy';
    elseif (strcmp(v1FilterBankType, 'svmV1FilterBankFullWaveRectAF'))
        V1filterBank.activationFunction = 'fullWaveRectifier';
    end
    
end

