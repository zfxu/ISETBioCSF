function dirname = paramsToTemporalDirName(obj,temporalParams)
% dirname = paramsToTemporalDirName(obj,temporalParams)
% 
% Generate a directory names that captures the temporal parameters used to
% generate the responses.

if (~strcmp(temporalParams.type,'Temporal')) && (~strcmp(temporalParams.type,'Temporal_v2'))
    error('Incorrect parameter type passed');
end

if (strcmp(temporalParams.type,'Temporal'))
    dirname = sprintf('tau%0.3f_dur%0.2f_nem%0.0f_use%0.0f_off%0.0f',...
        temporalParams.windowTauInSeconds, ...
        temporalParams.stimulusDurationInSeconds, ...
        temporalParams.eyesDoNotMove, ...
        temporalParams.secondsToInclude, ...
        temporalParams.secondsToIncludeOffset);
else
    dirname = sprintf('[STIM_TEMPORAL]_rampDur%0.3f_rampTau%0.3f',...
        temporalParams.rampDurationSecs, ...
        temporalParams.rampTauSecs ...
        );
end

