function hFigs = visualizeGaussianPooledSignals(spatialPoolingKernel, timeAxis, noStimResponseInstances, stimResponseInstances, signalSource, stimContrast, spatialFilterName)
    
    if (strcmp(signalSource, 'isomerizations'))
        plotType = 'density';
    else
        plotType = 'line';
    end
            
    responseRange = [...
        min([min(noStimResponseInstances(:)) min(stimResponseInstances(:))]) ...
        max([max(noStimResponseInstances(:)) max(stimResponseInstances(:))]) ...
        ];
    
    responseQuantizationLevelsNum = 1024;
    
    hFigs = visualizeGaussPooledResponses(spatialPoolingKernel, ...
        timeAxis, noStimResponseInstances, stimResponseInstances,  ...
        responseRange, responseQuantizationLevelsNum, plotType, signalSource, ...
        sprintf('%s (%s)', spatialFilterName, signalSource), 5003+sum(signalSource-'a'));

end

function hFigs = visualizeGaussPooledResponses(spatialPoolingKernel, timeAxis, ...
    noStimResponseInstances, stimResponseInstances, responseRange, responseLevelsNum, ...
    plotType, signalSource, figureName, figNo)

    coneTarget1Pos = [0. 0.];
    coneTarget2Pos = [0.17 0.17];
    [~,coneIndex1] = min(sum((bsxfun(@minus, spatialPoolingKernel.coneLocsDegs, coneTarget1Pos)).^2,2));
    [~,coneIndex2] = min(sum((bsxfun(@minus, spatialPoolingKernel.coneLocsDegs, coneTarget2Pos)).^2,2));
    noStimResponseInstances = (noStimResponseInstances - responseRange(1))/(responseRange(2)-responseRange(1));
    stimResponseInstances = (stimResponseInstances - responseRange(1))/(responseRange(2)-responseRange(1));
    
    xRange = (max(abs(spatialPoolingKernel.coneLocsDegs(:)))+0.5/60)*[-1 1];
    responseLevels = linspace(responseRange(1), responseRange(2), responseLevelsNum);
    responseInstancesNum = size(noStimResponseInstances,1);
    unitsNums = size(noStimResponseInstances,2);
    tBins = size(noStimResponseInstances,3);
    
    
    timeAxis = timeAxis*1000;
    hFigs = figure(1); clf;
    set(hFigs, 'Position', [10 10 1500 1000]);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 3, ...
           'heightMargin',   0.04, ...
           'widthMargin',    0.03, ...
           'leftMargin',     0.09, ...
           'rightMargin',    0.001, ...
           'bottomMargin',   0.05, ...
           'topMargin',      0.02);
       
    ax1 = subplot('Position', subplotPosVectors(1,1).v);
    ax2 = subplot('Position', subplotPosVectors(1,2).v);
    ax3 = subplot('Position', subplotPosVectors(2,1).v);
    ax4 = subplot('Position', subplotPosVectors(2,2).v);
    ax5 = subplot('Position', subplotPosVectors(2,3).v);

   
    cMap = brewermap(1024, '*RdBu');
    plotQuantizedWeights(ax1, squeeze(spatialPoolingKernel.poolingWeights(coneIndex1,:)), responseLevelsNum, ...
            spatialPoolingKernel.coneLocsDegs, spatialPoolingKernel.coneApertureOutlines);
    hold(ax1, 'on');
    sigmaDegs = spatialPoolingKernel.sigmaArcMin/60;
    plotCircle(ax1, spatialPoolingKernel.coneLocsDegs(coneIndex1,1), spatialPoolingKernel.coneLocsDegs(coneIndex1,2), 2.355*sigmaDegs);
    hold(ax1, 'off');
    set(ax1, 'FontSize', 14, 'XLim', xRange, 'YLim', xRange, 'XTickLabel', {}, 'CLim', [0 1]);
    ylabel(ax1, '\it position (degs)');
    box(ax1, 'on');
    colormap(ax1, cMap);
    
    plotQuantizedWeights(ax2, squeeze(spatialPoolingKernel.poolingWeights(coneIndex2,:)), responseLevelsNum, ...
            spatialPoolingKernel.coneLocsDegs, spatialPoolingKernel.coneApertureOutlines);
    hold(ax2, 'on');
    plotCircle(ax2,spatialPoolingKernel.coneLocsDegs(coneIndex2,1), spatialPoolingKernel.coneLocsDegs(coneIndex2,2), 2.355*sigmaDegs);
    hold(ax2, 'off');
    set(ax2, 'FontSize', 14, 'XLim', xRange, 'YLim', xRange, 'YTickLabel', {}, 'XTickLabel', {}, 'CLim', [0 1]);
    box(ax2, 'on');
    colormap(ax2, cMap);
    
    instanceNo = 1;
    [~,tBinDisplayed] = min(abs(timeAxis-90));
    
    cmap = brewermap(responseLevelsNum, '*greys');
    
    
    for tBin = tBinDisplayed:tBinDisplayed
        
        plotQuantizedWeights(ax3, squeeze(noStimResponseInstances(instanceNo,:,tBin)), responseLevelsNum, ...
            spatialPoolingKernel.coneLocsDegs, spatialPoolingKernel.coneApertureOutlines);
        set(ax3, 'Color', [0 0 0], 'FontSize', 14, 'XLim', xRange, 'YLim', xRange);
        box(ax3, 'on');
        colormap(ax3, cmap);
        title(ax3, sprintf('null (%2.0f ms)', timeAxis(tBin)));
        xlabel(ax3, '\it position (degs)');
        ylabel(ax3, '\it position (degs)');
        
        plotQuantizedWeights(ax4, squeeze(stimResponseInstances(instanceNo,:,tBin)), responseLevelsNum, ...
            spatialPoolingKernel.coneLocsDegs, spatialPoolingKernel.coneApertureOutlines);
        set(ax4, 'Color', [0 0 0], 'FontSize', 14, 'XLim', xRange, 'YLim', xRange, 'YTickLabel', {});
        box(ax4, 'on');
        colormap(ax4, cmap);
        title(ax4, sprintf('test (%2.0f ms)', timeAxis(tBin)));
        xlabel(ax4, '\it position (degs)');
        
        diff = squeeze(stimResponseInstances(instanceNo,:,tBin) - noStimResponseInstances(instanceNo,:,tBin));
        diff = (diff - min(diff(:))) / (max(diff(:)) - min(diff(:)));
        plotQuantizedWeights(ax5, diff, responseLevelsNum, ...
            spatialPoolingKernel.coneLocsDegs, spatialPoolingKernel.coneApertureOutlines);
        set(ax5, 'Color', [0 0 0], 'FontSize', 14, 'XLim', xRange, 'YLim', xRange, 'YTickLabel', {});
        box(ax5, 'on');
        colormap(ax5, cmap);
        title(ax5, sprintf('test - null (%2.0f ms)', timeAxis(tBin)));
        xlabel(ax5, '\it position (degs)');
        
    end
    
    drawnow;
end

function plotCircle(ax,xo,yo,diam)
    angles=1:360;
    x=diam/2*cosd(angles);
    y=diam/2*sind(angles);
    plot(ax, xo+x,yo+y,'b-', 'LineWidth', 1.5)
end