% fle.SubTrialSpikes - my newest table
% I will explain what my table does here

%{
fle.SubTrialSpikes (computed) # my newest table
-> fle.SpikeSets
subtrial_num     : int unsigned          # subTrial number

-----
spike_times=null          : longblob                      # The spike timing data
%}

classdef SubTrialSpikes < dj.Relvar
    
    properties(Constant)
        table = dj.Table('fle.SubTrialSpikes')
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
            
            for iSub = 1:nSubTrials
                st = - onsets(iSub) + ...
                    spikeTrain(spikeTrain >= tStart(iSub) & spikeTrain < tEnd(iSub));
                keys(iSub).spike_times = reshape(st,[],1);
                keys(iSub).subtrial_num = subtrialNums(iSub);
            end
            fprintf(' Inserting -->')
            self.insert(keys)
            fprintf(' Done (%0.2f sec)\n\n',toc);
        end
        
        function varargout = plotSpikes(self,varargin)
            
            args.axes = [];
            args.titStr = '';
            args.Position = [836 260 841 660];
            args.rasterType = 'dot'; % 'line' or 'dot'
            args.rasterDotSize = 1;
            args.rasterLineWidth = 1;
            args = parseVarArgs(args,varargin{:});
            
            if isempty(args.axes)
                args.axes = gca;
            end
            
            [spikeTimes  postStimTime] = fetchn(self,'spike_times','post_stim_time');
            nTrials = length(spikeTimes);
            if nTrials > 200
                rp = randperm(nTrials);
                spikeTimes = spikeTimes(rp(1:200));
            end
            
            e = cellfun(@(x) isempty(x),spikeTimes);
            spikeTimes(e) = {[]};
            spikes = cat(1,spikeTimes{:});
            y = 1:length(spikeTimes);
            y = cellfun(@(x,s) x*ones(1,length(s)),num2cell(y),spikeTimes','uni',false);
            y = [y{:}];
            ylim([0 length(spikeTimes)+1]);
            plot(spikes,y,'k.','MarkerSize',1);
            
            keys = fetch(self);
            sub = fetch(fle.SubTrials(keys(1)),'substim_on','substim_off');
            
            stimTime = sub.substim_off - sub.substim_on;
            PlotTools.title(args.titStr)
            PlotTools.xlabel('Time (ms)')
            PlotTools.ylabel('Trial #')
            
            % plot stim on and off
            hold on
            plot(0,0,'*','color',[0 0.5 0])
            plot(stimTime,0,'*r')
            axis tight
            title(args.titStr);
            xlim([-100 stimTime+postStimTime(1)]);
            
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

