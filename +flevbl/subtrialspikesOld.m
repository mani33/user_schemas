% fle.SubTrialSpikes - Spike times for subTrials
% Subtrial spike times for FlePhysEffExperiment

%{
fle.SubTrialSpikes (computed) # my newest table
-> fle.Phys
-> fle.SubTrials
-> fle.SpikeAlignedCond
-----
spike_times=null          : longblob                      # The spike timing data
subtrialspikes_ts=CURRENT_TIMESTAMP: timestamp              # automatic timestamp. Do not edit
%}
% MS 2012-02-02
classdef SubTrialSpikes < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.SubTrialSpikes')
    end
    properties
        % Populate for each unit_id for each spike aligning condition for each subTrial.
        popRel = fle.Phys(fle.SubTrials) * fle.SpikeAlignedCond;
    end
    
    methods
        function self = SubTrialSpikes(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            % Get spikes for a single/multi unit for the whole session
            spikeTrain = fetch1(ephys.Spikes(key),'spike_times');
            
            % Find stim on/off times for all subtrials in the given session (=key)
            [onsets offsets subtrialNums] = fetchn(fle.SubTrials(key),'substim_on','substim_off',...
                'subtrial_num');
            
            nSubTrials = length(onsets);
            keys = repmat(key,1,nSubTrials);
            tStart = onsets - key.pre_stim_time;
            tEnd = offsets + key.post_stim_time;
            
            % Go to each subtrial and pick spikes
            tic
            fprintf('Computing tuples -->')
            
            parfor iSub = 1:nSubTrials
                keys(iSub).spike_times = - onsets(iSub) + ...
                    spikeTrain(spikeTrain >= tStart(iSub) & spikeTrain < tEnd(iSub)); %#ok
                keys(iSub).subtrial_num = subtrialNums(iSub);
            end
            fprintf(' Inserting -->')
            self.insert(keys)
            fprintf(' Done (%0.2f sec)\n\n',toc);
        end
    end
end
