%{
rf.Map (computed) # my newest table
-> rf.MapSets
-> rf.Lags
-> rf.MapTypes
-----
map: longblob # rf map 2d
%}

classdef Map < dj.Relvar
    
    properties(Constant)
        table = dj.Table('rf.Map')
    end
    
    methods
        function self = Map(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            keys = fetch(rf.MapSets(key) * rf.Lags * rf.MapTypes);
            
            % constant parameter
            key = keys(1);
            dotColors = fetch1(rf.StimConstants(key),'dot_color');
            dotColorBright = max(dotColors);
            dotColorDark = min(dotColors);
            T = fetch1(vstim.RefreshPeriod(key),'refresh_period_msec');
            stimCenter = [fetch1(rf.StimConstants(key),'stim_center_x') ...
                fetch1(rf.StimConstants(key),'stim_center_y')];
            [dot_num_x dot_num_y] = fetchn(rf.StimConstants(key),'dot_num_x','dot_num_y');
            [dotSize stimFrames] = fetchn(rf.StimConstants(key),'dot_size','stim_frames');
            dotNum = [dot_num_x dot_num_y];
            mapSize = [dot_num_y dot_num_x];
            
            % Trial by trial data
            td = fetch(rf.Trials(key),'stim_on','stim_off','swap_times','dot_colors','dot_locations');
            
            % Hacking after much frustration with being unable to delete this stim session
            if key.stim_start_time == 3.381410572663000e+12 && ...
                    key.session_start_time == 3.381410209000000e+12
                td = td(16:end); % in the first 15 valid trials, the dotNumX was set to 15 while
                % the rest of the trials had dotNumX=16.
            end
            nTrials = length(td);
            
            
            for key = keys'
                lag = key.lag;
                
                % Spikes for each trial
                sdata = fetch(rf.TrialSpikes(key),'spike_times');
                
                % preprocessing to obtain spikes, locations and swap times
                spikes = cell(nTrials,1);
                times = cell(nTrials,1);
                stimTime = zeros(nTrials,1);
                frameDropTrial = false(nTrials,1);
                
                % default
                map.Bright = zeros(mapSize);
                map.Dark = zeros(mapSize);
                map.Sum = zeros(mapSize);
                map.Diff = zeros(mapSize);
                
                for iTrial = 1:nTrials
                    ctd = td(iTrial);
                    % stim event times are stored as bigint so we round the swap times which
                    % are stored as doubles.
                    ctd.swap_times = round(ctd.swap_times);
                    % get spikes
                    interval = [lag, ctd.stim_off-ctd.stim_on + lag];
                    spkTimes = sdata([sdata.trial_num]==ctd.trial_num).spike_times;
                    spkTimes = spkTimes(spkTimes > interval(1) & spkTimes <= interval(2)) + ctd.stim_on;
                    spikes{iTrial} = reshape(spkTimes-lag,1,[]);
                    
                    % extract swap times
                    firstSwap = find(ctd.swap_times == ctd.stim_on);
                    lastSwap = find(ctd.swap_times <= ctd.stim_off,1,'last');
                    times{iTrial} = reshape(ctd.swap_times(firstSwap:lastSwap),1,[]);
                    nSwaps = lastSwap-firstSwap+1;
                    nSwaps = floor(nSwaps/stimFrames);
                    td(iTrial).dot_locations = td(iTrial).dot_locations(1:nSwaps);
                    td(iTrial).dot_colors = td(iTrial).dot_colors(1:nSwaps);
                    
                    % find out if some frames were missed
                    nFrames = round(diff(times{iTrial}) / T);
                    if any(nFrames > 1)
                        frameDropTrial(iTrial) = true;
                    end
                    
                    % discard buffer swaps where nothing happened
                    times{iTrial} = times{iTrial}((0:nSwaps-1)*stimFrames+1);
                    
                    % find trial length
                    stimTime(iTrial) = times{iTrial}(end)-times{iTrial}(1);
                end
                
                % get rid of trials that have skipped buffer swaps
                spikes = spikes(~frameDropTrial);
                colors = [td(~frameDropTrial).dot_colors];
                locations = [td(~frameDropTrial).dot_locations];
                times = times(~frameDropTrial);
                stimTime = stimTime(~frameDropTrial);
                
                % reformat data for mapping
                spikes = [spikes{:}];
                times = [times{:}];
                
                
                % count spikes in stimulus frames
                counts = histc(spikes,times);
                spkFrameIdx = find(counts>0);
                spkFrameCounts = counts(spkFrameIdx);
                
                % convert location to points on the grid
                spkFrameLocs = locations(spkFrameIdx);
                spkFrameLocs = [spkFrameLocs{:}];
                
                if ~isempty(spkFrameLocs)
                    
                    spkFrameLocs = bsxfun(@plus,bsxfun(@minus,spkFrameLocs,stimCenter')/dotSize,(dotNum'+1)/2);
                    
                    % deal with color
                    spkFrameColor = colors(spkFrameIdx);
                    spkFrameColor = [spkFrameColor{:}];
                    
                    brightIdx = find(spkFrameColor==dotColorBright);
                    darkIdx = find(spkFrameColor==dotColorDark);
                    
                    % seperate data accoring to color
                    xLocBright = spkFrameLocs(1,brightIdx);
                    yLocBright = spkFrameLocs(2,brightIdx);
                    xLocDark = spkFrameLocs(1,darkIdx);
                    yLocDark = spkFrameLocs(2,darkIdx);
                    
                    spkBright = spkFrameCounts(brightIdx);
                    spkDark = spkFrameCounts(darkIdx);
                    
                    % subscripts
                    subBright = {yLocBright xLocBright};
                    subDark = {yLocDark xLocDark};
                    
                    % perform mapping
                    if ~any(cellfun(@isempty,subBright))
                        mapBright = accumarray(subBright,spkBright,mapSize);
                    else
                        mapBright = zeros(mapSize);
                    end
                    
                    if ~any(cellfun(@isempty,subDark))
                        mapDark = accumarray(subDark,spkDark,mapSize);
                    else
                        mapDark = zeros(mapSize);
                    end
                    
                    % normalization
                    locations =  bsxfun(@plus,bsxfun(@minus,[locations{:}],stimCenter')/dotSize,(dotNum'+1)/2);
                    locations = sub2ind(dotNum,locations(1,:),locations(2,:));
                    pbin = mean(hist(locations,1:prod(dotNum))/length(locations));
                    expTime = sum(stimTime)/1000;           % total experiment time
                    
                    % normalize dark/bright map independently
                    vs = (1-pbin/2)*pbin/2;                     % variance of stimulus
                    mapBright = (mapBright - mean(mapBright(:))) / vs / expTime;
                    mapDark = (mapDark - mean(mapDark(:))) / vs / expTime;
                    
                    mapDiff = mapBright - mapDark;
                    mapSum = 0.5 * (mapBright + mapDark);
                    
                    % save results
                    map.Bright = mapBright;
                    map.Dark = mapDark;
                    map.Sum = mapSum;
                    map.Diff = mapDiff;
                end
                mapType = fetch1(rf.MapTypes(key),'map_type');
                key.map = map.(mapType);
                self.insert(key)
                
            end
        end
        
        
        
        function [xGrid yGrid] = getGrid(self,gridUnit)
            %   [xGrid yGrid] = getGrid(self,'pix')
            %   [xGrid yGrid] = getGrid(self,'deg')
            
            d = fetch(rf.StimConstants(fetch(self)),'*');
%             pixPerDeg = tan(pi / 180) * d.monitor_distance / d.monitor_size_x * d.resolution_x;
            pixPerDeg = fetch1(vstim.PixPerDeg(fetch(self)),'pix_per_deg');
            xGrid = d.stim_center_x +((1:d.dot_num_x) - ceil(d.dot_num_x/2)) * d.dot_size;
            yGrid = d.stim_center_y +((1:d.dot_num_y) - ceil(d.dot_num_y/2)) * d.dot_size;
            
            if strcmp(gridUnit,'deg')
                xGrid = (xGrid - d.monitor_center_x)/pixPerDeg;
                yGrid = (yGrid - d.monitor_center_y)/pixPerDeg;
            end
        end
        
        function varargout = plot(self,varargin)
            
            arg.smooth = 5;
            arg.axis = [];
            arg.units = 'deg'; % deg or pix
            arg = parseVarArgs(arg,varargin{:});
            
            % get all map data
            md = fetch(self,'*');
            
            % get grid
            [x y] = getGrid(self,arg.units);
            
            if ~isempty(arg.axis)
                axes(arg.axis)
            end
            
            % smooth map
            w = gausswin(arg.smooth);
            w = w*w';
            w = w/sum(w(:));
            map = imfilter(md.map,w,'same');
            
            % plot map
            h = imagesc(x,y,map);
            hold on
            if size(map,1)==size(map,2)
                PlotTools.sqAx;
            end
            axis image
            set(gca,'YDir','reverse','FontSize',7)
            
            if nargout
                varargout{1} = h;
            end
            % plot meridians
            plot(xlim,[0 0],'w');
            plot([0 0],ylim,'w');
        end
    end
end
