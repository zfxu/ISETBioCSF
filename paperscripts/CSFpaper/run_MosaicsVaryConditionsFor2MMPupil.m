function run_MosaicsVaryConditionsFor2MMPupil
% This is the script used to assess the impact of different mosaic models on the CSF
%  
    % How to split the computation
    % 0 (All mosaics), 1; (Largest mosaic), 2 (Second largest), 3 (all 2 largest)
    computationInstance = 0;
    
    % Whether to make a summary figure with CSF from all examined conditions
    makeSummaryFigure = true;
    makeMosaicsFigure = true;
    
    % Mosaic to use
    examinedMosaicModels = {...
        'originalBanks' ...
        'ISETbioHexEccBasedLMSrealisticEfficiencyCorrection' ...
        };
 
    examinedMosaicLegends = {...
        'constant LM density (Banks ''87)' ...
        'ecc-based LMS density and efficiency' ...
    };

    examinedMosaicLegends = {...
        'constant LM density (Banks ''87)' ...
        'ecc-based LMS density/efficiency' ...
    };
     
    idx = 2:2;
    examinedMosaicModels = {examinedMosaicModels{idx}};
    
    % Tun the mosaic-vary condition using the Geisler optics
    opticsName = 'Geisler';
      
    theMosaicTypesAtSpecificSF = {};
    
    % Go !
    for mosaicIndex = 1:numel(examinedMosaicModels)
        mosaicName = examinedMosaicModels{mosaicIndex};
        params = getCSFpaperDefaultParams(mosaicName, computationInstance);
        
        params.opticsModel = opticsName;
        
        % 2 mm pupil
        params.pupilDiamMm = 2.0;
        
        params.coneContrastDirection = 'L+M+S';
        params.cyclesPerDegreeExamined = [2 4 8 16 32 50];
    
        % Response duration params
        params.frameRate = 10; %(1 frames)
        params.responseStabilizationMilliseconds = 40;
        params.responseExtinctionMilliseconds = 40;

        % Eye movement params
        params.emPathType = 'frozen0';
        params.centeredEMpaths = ~true;

        % Simulation steps to perform
        params.computeMosaic = ~true; 
        params.visualizeMosaic = ~true;

        params.computeResponses = ~true;
        params.computePhotocurrentResponseInstances = ~true;
        params.visualizeMosaic = makeMosaicsFigure;
        params.visualizeResponses = ~true;
        params.visualizeSpatialScheme = ~true;
        params.visualizeOIsequence = ~true;
        params.visualizeOptics = ~true;
        params.visualizeMosaicWithFirstEMpath = ~true;
        params.visualizeSpatialPoolingScheme = ~true;
        params.visualizeStimulusAndOpticalImage = ~true;
        params.visualizeDisplay = ~true;
    
        params.visualizeKernelTransformedSignals = ~true;
        params.findPerformance = ~true;
        params.visualizePerformance = makeSummaryFigure;
        params.deleteResponseInstances = ~true;

        [theMosaicTypes, thePsychometricFunctions{mosaicIndex}, theFigData{mosaicIndex}] = ...
            run_BanksPhotocurrentEyeMovementConditions(params);
        
        if (makeMosaicsFigure)
            sfIndex = 4;
            theCurrentMosaic = theMosaicTypes.theMosaics{sfIndex};
            theMosaicTypesAtSpecificSF{numel(theMosaicTypesAtSpecificSF) + 1} = theCurrentMosaic;
            theCurrentMosaic.displayInfo();
        end
    end
    
    if (makeSummaryFigure)
        variedParamName = 'Mosaic';
        if (params.pupilDiamMm == 2)
            theRatioLims = [0.02 1.0];
            theRatioTicks = [0.02 0.05 0.1 0.2 0.5 1.0 2.0];
        else
            theRatioLims = [0.3 1.0];
            theRatioTicks = [0.3 0.5 0.7 1.0];
        end
        generateFigureForPaper(theFigData, examinedMosaicLegends, variedParamName, opticsName, ...
            'figureType', 'CSF', ...
            'inGraphText', '', ...
            'plotFirstConditionInGray', true, ...
            'showSubjectData', (params.pupilDiamMm == 2), ...
            'plotRatiosOfOtherConditionsToFirst', true, ...
            'theRatioLims', theRatioLims, ...
            'theRatioTicks', theRatioTicks ...
            );
    end

    if (makeMosaicsFigure)
        generateMosaicsFigure(theMosaicTypesAtSpecificSF, examinedMosaicLegends,  ...
            'inGraphTexts', {}, ...
            'visualizedFOV', 0.5/2);
    end
end

function generateMosaicsFigure(theMosaics, examinedMosaicLegends,  varargin)
    p = inputParser;
    p.addParameter('inGraphTexts', '', @iscell);
    p.addParameter('visualizedFOV', 0.5, @isnumeric);
    p.parse(varargin{:});
    
    inGraphTexts = p.Results.inGraphTexts;
    visualizedFOV = p.Results.visualizedFOV;
    
    % Initialize figure
    hFig = figure(1); clf;
    formatFigureForPaper(hFig, 'figureType', 'MOSAICS2');
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 1, ...
       'colsNum', 2, ...
       'heightMargin',  0.01, ...
       'widthMargin',    0.01, ...
       'leftMargin',     0.01, ...
       'rightMargin',    0.0001, ...
       'bottomMargin',   0.06, ...
       'topMargin',      0.0001);
    
    for mosaicIndex = 1:numel(theMosaics)
        cm = theMosaics{mosaicIndex};
        posRangeY = visualizedFOV*cm.micronsPerDegree * 1e-6 * [-1 1];
        posRangeX = posRangeY;
        mosaicName = examinedMosaicLegends{mosaicIndex};
        
        switch (mosaicIndex)
            case 1
                subplotRow = 1; subplotCol = 1;
            case 2
                subplotRow = 1; subplotCol = 2;
            case 3
                subplotRow = 2; subplotCol = 1;
            case 4
                subplotRow = 2; subplotCol = 2;
        end
        
        ax = subplot('Position', subplotPosVectors(subplotRow,subplotCol).v);
        cm.visualizeGrid(...
            'axesHandle', ax, ...
            'apertureShape', 'disks', ...
            'visualizedConeAperture', 'geometricArea', ...
            'labelConeTypes', true, ...
            'overlayHexMesh', false, ...
            'backgroundcolor', [1 1 1]);
        
        set(ax, 'XLim', posRangeX, 'YLim', posRangeY);
        
        inGraphTextPos = [-0.25 0.21]*cm.micronsPerDegree * 1e-6;
        if (numel(inGraphTexts) > 0)
            t = text(ax, inGraphTextPos(1), inGraphTextPos(2), inGraphTexts{mosaicIndex});
        else 
            t = [];
        end
        
        formatFigureForPaper(hFig, ...
            'figureType', 'MOSAICS2', ...
            'theAxes', ax, ...
            'theText', t, ...
            'theTextFontSize', [], ...
            'theFigureTitle', '');
        
        tickDegs = -0.5:0.1:0.5;
        ticks = tickDegs*cm.micronsPerDegree * 1e-6;
        tickLabels = sprintf('%2.2f\n', tickDegs);
        set(ax, 'XTick', ticks, 'XTickLabel', tickLabels, 'YTick', ticks, 'YTickLabel', tickLabels);
        
        switch (mosaicIndex)
            case 1
                set(ax, 'XTickLabel', {});
                set(ax, 'YTickLabel', {});
            case 2
                set(ax, 'XTickLabel', {});
                set(ax, 'YTickLabel', {});
            case 3
                xlabel(ax, 'retinal position (deg)', 'FontWeight', 'bold');
                set(ax, 'YTickLabel', {});
            case 4
                xlabel(ax, 'retinal position (deg)', 'FontWeight', 'bold');
                set(ax, 'YTickLabel', {});
        end
    end
    
    exportsDir = strrep(isetRootPath(), 'toolboxes/isetbio/isettools', 'projects/IBIOColorDetect/paperfigs/CSFpaper/exports');
    figureName = fullfile(exportsDir, sprintf('MosaicsEmployed.pdf'));
    NicePlot.exportFigToPDF(figureName, hFig, 300);
end

