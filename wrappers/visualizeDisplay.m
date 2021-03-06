function visualizeDisplay(display, figNo)
    % Retrieve wavelength support and spectral power distribution of the
    % primaries
    wave = displayGet(display, 'wave');
    spds = displayGet(display, 'spd primaries');
    % Retrieve resolution in dots/inch
    resolutionDPI = displayGet(display, 'dpi');
    hFig = figure(figNo); clf;
    set(hFig, 'Position', [10 10 1000 400], 'Color', [1 1 1]);
    subplot(1,2,1);
    plot(wave, spds(:,1)*1e3, 'ro-'); hold on;
    plot(wave, spds(:,2)*1e3, 'go-'); 
    plot(wave, spds(:,3)*1e3, 'bo-'); 
    set(gca, 'XLim', [380 780]); 
    grid on; axis 'square';
    xlabel('wavelength (nm)'); ylabel('energy (mWatts)');
    title('Spectral Power Distributions');
    set(gca, 'FontSize', 14);
    
    subplot(1,2,2);
    gammaTable = displayGet(display, 'gamma table');
    plot(1:size(gammaTable,1), gammaTable(:,1), 'r-', 'LineWidth', 1.5); hold on;
    plot(1:size(gammaTable,1), gammaTable(:,2), 'g-', 'LineWidth', 1.5); hold on;
    plot(1:size(gammaTable,1), gammaTable(:,3), 'b-', 'LineWidth', 1.5); hold on;
    set(gca, 'XLim', [0 1023], 'YLim', [0 1]);
    grid on; axis 'square';
    xlabel('RGB primary value');
    ylabel('RGB settings value');
    title('Gamma Functions');
    set(gca, 'FontSize', 14);
    drawnow;
end

