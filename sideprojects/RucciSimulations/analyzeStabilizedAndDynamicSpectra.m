function analyzeStabilizedAndDynamicSpectra(stimulusTypes, stimulusSizeDegs, fixationDurationSeconds, noiseInstances, reComputeSpectralAnalyses)
    noiseNorm = nan;
    oriDegs = 0;
    contrastLevels = [1];
    
    if (reComputeSpectralAnalyses)
        % Generate fixational eye movmeents
        nTrials = noiseInstances;
        [emPosArcMin, timeAxis] = generateFEMs(nTrials, fixationDurationSeconds);
        emPosArcMin = emPosArcMin * 0.5;
    end
    
    
    figNo = 1000;
    
    for stimIndex = 1:numel(stimulusTypes)
        
        if (reComputeSpectralAnalyses)
            % Retrieve stimulus params
            [gratingParams, noiseParams, stimulusPixelSizeArcMin] = ...
                RucciStimulusParams(stimulusTypes{stimIndex}, stimulusSizeDegs, oriDegs, contrastLevels);

            % Generate stimulus
            [stimStruct, noiseNorm] = ...
                generateGratingInNoiseSpatialModulationPattern(...
                    stimulusSizeDegs*60, stimulusPixelSizeArcMin,  ...
                    gratingParams, noiseParams, noiseNorm, noiseInstances, figNo);

            % Only one contrast level so squeeze it out
            stimStruct.image = squeeze(stimStruct.image(:,1,:,:));
            
            % Generate spatiotemporal stimulus sequence and spectra due to fixational EM
            fprintf('Computing spatiotemporal analysis for DYNAMIC ''%s'' stimulus.\n', stimulusTypes{stimIndex});
            xtStimStructFEM = generateSpatiotemporalStimulusSequenceDueToFixationalEM(...
                timeAxis, emPosArcMin, stimStruct);
            
            fName = spectralAnalysisFileName(stimulusTypes{stimIndex}, stimulusSizeDegs);
            fprintf('Saving DYNAMIC spatiotemporal analysis to %s\n', fName);
            save(fName, 'xtStimStructFEM', '-v7.3');
            clear 'xtStimStructFEM';
            
            fprintf('Computing spatiotemporal analysis for STABILIZED ''%s'' stimulus.\n', stimulusTypes{stimIndex});
            xtStimStructStabilized = generateSpatiotemporalStimulusSequenceDueToFixationalEM(timeAxis, emPosArcMin*0, stimStruct);
            fprintf('Saving STABILIZED spatiotemporal analysis to %s\n', fName);
            save(fName, 'xtStimStructStabilized', '-append');
        else
            fName = spectralAnalysisFileName(stimulusTypes{stimIndex}, stimulusSizeDegs);
            load(fName, 'xtStimStructStabilized');
            
            [xtSpectralDensityStabilized, sfSupport, tfSupport] = xtSpectrumFromXYTspectrum(...
                xtStimStructStabilized.meanSpatioTemporalPowerSpectalDensity, ...
                xtStimStructStabilized.spatialFrequencySupport, ...
                xtStimStructStabilized.tfSupport);
            clear 'xtStimStructStabilized'
            
            load(fName, 'xtStimStructFEM');
            [xtSpectralDensityDynamic, sfSupport, tfSupport] = xtSpectrumFromXYTspectrum(...
                xtStimStructFEM.meanSpatioTemporalPowerSpectalDensity, ...
                xtStimStructFEM.spatialFrequencySupport, ...
                xtStimStructFEM.tfSupport);
            clear 'xtStimStructFEM';
            
            % Visualize spatiomporal spectra
            figNo = 1000 + stimIndex*1000;
            visualizeStabilizedAndDynamicsSpectra(xtSpectralDensityStabilized, xtSpectralDensityDynamic, sfSupport, tfSupport, figNo);
        end
        
        
    end
    
end

function fName = spectralAnalysisFileName(stimulusType,stimulusSizeDegs)
    fName = sprintf('SpectralAnalyses_%s_%2.1fdegs.mat', strrep(stimulusType, ' ', '_'), stimulusSizeDegs);
    fName = fullfile('SpectralAnalyses', fName);
end


function [emPosArcMin, timeAxis] = generateFEMs(nTrials, emDurationSeconds)
    sampleTimeSeconds = 2.0 / 1000;

    microSaccadeType = 'none'; % , 'heatmap/fixation based', 'none'
    fixEMobj = fixationalEM();
    fixEMobj.randomSeed = 1;
    fixEMobj.microSaccadeType = microSaccadeType;
    
    computeVelocity = ~true;
    fixEMobj.compute(emDurationSeconds, sampleTimeSeconds, ...
            nTrials, computeVelocity, 'useParfor', true);
        
    timeAxis = fixEMobj.timeAxis;
    emPosArcMin = fixEMobj.emPosArcMin;
    
    % Center at (0,0)
    meanEMPos = mean(emPosArcMin,2);
    for iTrial = 1:nTrials
        emPosArcMin(iTrial,:,1) = emPosArcMin(iTrial,:,1) - meanEMPos(iTrial,1,1);
        emPosArcMin(iTrial,:,2) = emPosArcMin(iTrial,:,2) - meanEMPos(iTrial,1,2);
    end

    % Plot the eye movements
    plotFEM(emPosArcMin, timeAxis);

end

function plotFEM(emPosArcMin, timeAxis)
    trialNo = 1;
    xPosArcMin = squeeze(emPosArcMin(trialNo,:,1));
    yPosArcMin = squeeze(emPosArcMin(trialNo,:,2));
    
    maxPos = 20; % max(abs(emPosArcMin(:)));
    if (maxPos == 0)
        maxPos = 1;
    end
    posRange = maxPos*[-1 1];
    
    hFig = figure(1000); clf;
    set(hFig, 'Position', [10 10 900 400], 'Color', [1 1 1]);
    subplot(1,2,1);
    plot(timeAxis*1000, xPosArcMin, 'r-', 'LineWidth', 1.5); hold on
    plot(timeAxis*1000, yPosArcMin, 'b-', 'LineWidth', 1.5);
    set(gca, 'YLim', posRange, 'FontSize', 14, 'XTick', 0:200:1000, 'YTick', -20:5:20);
    grid on
    xlabel('time (msec)');
    ylabel('space (arc min)');
    axis 'square';
    
    subplot(1,2,2);
    plot(xPosArcMin, yPosArcMin, 'k-', 'LineWidth', 1.5);
    set(gca, 'XLim', posRange, 'YLim', posRange, 'FontSize', 14, 'XTick', -20:5:20, 'YTick', -20:5:20);
    grid on
    axis 'square';
    xlabel('space (arc min)');
end
