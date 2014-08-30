%{
imc.TrialSpikes (computed) # my newest table
-> imc.SpikeSets
trial_num     : int unsigned          # trial number

-----
spike_times=null          : longblob                      # The spike timing data
%}

classdef TrialSpikes < dj.Relvar
    
    properties(Constant)
        table = dj.Table('imc.TrialSpikes')
    end
    
    methods
        function self = TrialSpikes(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            % Get spikes for a single/multi unit for the whole session
            spikeTrain = fetch1(ephys.Spikes(key),'spike_times');
            
            % Find stim on/off times for all trials in the given session (=key)
            [onsets, offsets, trialNums] = fetchn(imc.Trials(key),'stim_on','stim_off',...
                'trial_num');
            onsets = double(onsets);
            offsets = double(offsets);
            ntrials = length(onsets);
            keys = repmat(key,1,ntrials);
            tStart = onsets - key.pre_stim_time;
            tEnd = offsets + key.post_stim_time;
            
            % Go to each trial and pick spikes
            tic
            fprintf('Computing tuples -->')
            
            for i = 1:ntrials
                st = - onsets(i) + ...
                    spikeTrain(spikeTrain >= tStart(i) & spikeTrain < tEnd(i));
                keys(i).spike_times = reshape(st,[],1);
                keys(i).trial_num = trialNums(i);
            end
            fprintf(' Inserting -->')
            self.insert(keys)
            fprintf(' Done (%0.2f sec)\n\n',toc);
        end
        function varargout = plot(self,varargin)
            
            args.axes = [];
            args.titStr = '';
            args.FontSize = 8;
            args.FontName = 'Arial';
            
            args = parseVarArgs(args,varargin{:});
            
            if isempty(args.axes)
                args.axes = gca;
            end
            
            [spikeTimes,  postStimTime] = fetchn(self,'spike_times','post_stim_time');            
            e = cellfun(@(x) isempty(x),spikeTimes);
            spikeTimes(e) = {NaN};    % To plot trials with no spikes
            
            keys = fetch(self);
            sub = fetch(imc.Trials & keys,'stim_on','stim_off');
            stimTimes = double(([sub.stim_off] - [sub.stim_on]));
            xmax = max(stimTimes+postStimTime');
            
            
            nTrials = length(spikeTimes);
            for iTrial = 1:nTrials
                st = spikeTimes{iTrial};
                if ~isempty(st)
                    X = repmat(st,1,2)';
                    ns = length(st);
                    Y = repmat(iTrial,1,ns);
                    Y = [Y-0.45; Y+0.45];
                    line(X,Y,'Color','k')
                    hold on
                end
            end
          
            xlabel('Time (ms)')
            ylabel('Trial number')            
            title(args.titStr,'fontsize',args.FontSize);
            xlim([-300 xmax])
            
            
            % return figure handle
            if nargout > 0
                varargout{1} = h;
            end
        end
        
        function spikes = getSpikesInInterval(self,win)
            % Get spike cell array for the given restricted relation in the supplied window
            d = fetch(self,'spike_times');
            spikes = {d.spike_times};
            spikes = cellfun(@(x) x(x > win(1) & x < win(2)),spikes,'uni',false);
        end
    end
end
