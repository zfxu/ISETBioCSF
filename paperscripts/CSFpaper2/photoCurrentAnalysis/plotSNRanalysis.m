function plotSNRanalysis(adaptationLevels, theConeExcitationSNR, thePhotoCurrentSNR, contrastLevels, ...
    SNRLims, SNRTicks, SNRratioLims, SNRratioTicks, pulseDurationSeconds, figNo)

    hFig = figure(figNo); clf;
    set(hFig, 'Position', [10 10 1230 460], 'Color', [1 1 1]);
    
    backgroundConeExcitationRateLims = [400 30000];
    backgroundConeExcitationRateTicks =  [300 1000 3000 10000 30000];
    backgroundConeExcitationRateTickLabels =  {'0.3k', '1k', '3k', '10k', '30k'};
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', numel(contrastLevels)/2, ...
       'rowsNum', 2, ...
       'heightMargin',   0.06, ...
       'widthMargin',    0.013, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.14, ...
       'topMargin',      0.04);

    markerSize = 10;
    for iContrastIndex = 1:(numel(contrastLevels)/2) 
        iContrastIndex2 = find(contrastLevels == -contrastLevels(iContrastIndex));
        
        color = 0.4*[1 1 1];
        subplot('Position', subplotPosVectors(1,iContrastIndex).v);
        plot(adaptationLevels, theConeExcitationSNR(:, iContrastIndex), 'ks-', ...
            'Color', 0.5*color, 'MarkerFaceColor', color, ...
            'MarkerSize', markerSize, 'LineWidth', 1.5);
        hold on;
   
        plot(adaptationLevels, thePhotoCurrentSNR(:, iContrastIndex), 'ko-', ...
            'Color', 0.5*color, 'MarkerFaceColor', color, ...
            'MarkerSize', markerSize, 'LineWidth', 1.5);
        
        color = 0.8*[1 1 1];
        plot(adaptationLevels, theConeExcitationSNR(:, iContrastIndex2), 'ks-', ...
            'Color', 0.5*color, 'MarkerFaceColor', color, ...
            'MarkerSize', markerSize, 'LineWidth', 1.5);
        
        plot(adaptationLevels, thePhotoCurrentSNR(:, iContrastIndex2), 'ko-', ...
            'Color', 0.5*color, 'MarkerFaceColor', color, ...
            'MarkerSize', markerSize, 'LineWidth', 1.5);
        
        grid on
        set(gca, 'FontSize', 14, 'XScale', 'log',  ...
            'XTick',backgroundConeExcitationRateTicks, 'XLim', backgroundConeExcitationRateLims, 'XTickLabel', {}, ...
            'YLim', SNRLims, 'YTick', SNRTicks, 'YScale', 'log');
        if (iContrastIndex == 1)
            legend({'cone exc. (decr.)', 'pCurrent (decr.)', 'cone exc. (incr.)', 'pCurrent (incr.)',}, 'Location', 'NorthWest');
            ylabel('\it SNR');
        else
            set(gca, 'YTickLabel', {});
        end
        
        title(sprintf('contrast: %2.0f%%', contrastLevels(iContrastIndex2)*100)) 
    end
    
    for iContrastIndex = 1:(numel(contrastLevels)/2) 
        legends = {};
        iContrastIndex2 = find(contrastLevels == -contrastLevels(iContrastIndex));
        
        color = 0.4*[1 1 1];
        subplot('Position', subplotPosVectors(2,iContrastIndex).v);
        plot(adaptationLevels, thePhotoCurrentSNR(:, iContrastIndex)./theConeExcitationSNR(:, iContrastIndex), 'ks-', ...
            'Color', 0.5*color, 'MarkerFaceColor', color, ...
            'MarkerSize', markerSize, 'LineWidth', 1.5);
        hold on;

        color = 0.8*[1 1 1];
        plot(adaptationLevels, thePhotoCurrentSNR(:, iContrastIndex2)./theConeExcitationSNR(:, iContrastIndex2), 'ks-', ...
            'Color', 0.5*color, 'MarkerFaceColor', color, ...
            'MarkerSize', markerSize, 'LineWidth', 1.5);

        grid on
        set(gca, 'FontSize', 14, 'XScale', 'log', ...
            'XTick',backgroundConeExcitationRateTicks, 'XLim', backgroundConeExcitationRateLims, ...
            'XTickLabel', backgroundConeExcitationRateTickLabels, ...
            'YLim', SNRratioLims, 'YTick', SNRratioTicks, 'YScale', 'linear');
        
        if (iContrastIndex == 1)
            legend({'decr.', 'incr.'}, 'Location', 'NorthEast');
            ylabel(sprintf('\\it pCurrent/cone excitations \n SNR ratio'));
            xlabel(sprintf('\\it adapting cone \n excitation rate (R*/c/s)'));
        else
            set(gca, 'YTickLabel', {});
        end
    end
    
    pdfFileName = sprintf('SNR_analysis_%2.1fmsec.pdf', pulseDurationSeconds*1000);
    NicePlot.exportFigToPDF(pdfFileName, hFig, 300);
     
end

