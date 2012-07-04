%{
rf.TrialSpikes (computed) # my newest table

-> rf.SpikeSets
trial_num       : int unsigned          # subTrial number
---
spike_times                 : longblob                      # no comment
%}

classdef TrialSpikes < dj.Relvar
    
    properties(Constant)
        table = dj.Table('rf.TrialSpikes')
    end
    
    methods
        function self = TrialSpikes(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            % Get spikes for a single/multi unit for the whole session
            spikeTrain = fetch1(ephys.Spikes(key),'spike_times');
            
            % Find stim on/off times for all subtrials in the given session (=key)
            [onsets offsets trialNums] = fetchn(rf.Trials(key),'stim_on','stim_off',...
                'trial_num');
            
            nTrials = length(onsets);
            keys = repmat(key,1,nTrials);
            tStart = onsets - key.pre_stim_time;
            tEnd = offsets + key.post_stim_time;
            
            % Go to each subtrial and pick spikes
            tic
            fprintf('Computing tuples -->')
            
            for iTrial = 1:nTrials
                st = - onsets(iTrial) + ...
                    spikeTrain(spikeTrain >= tStart(iTrial) & spikeTrain < tEnd(iTrial));
                if isempty(st)
                    st = NaN;
                else
                    st = reshape(st,[],1);
                end
                keys(iTrial).spike_times = st;
                keys(iTrial).trial_num = trialNums(iTrial);
            end
            
            fprintf(' Inserting -->')
            self.insert(keys)
            fprintf(' Done (%0.2f sec)\n\n',toc);
        end
    end
end

