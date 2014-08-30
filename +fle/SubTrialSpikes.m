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
            [onsets, offsets, subtrialNums] = fetchn(fle.SubTrials(key),'substim_on','substim_off',...
                'subtrial_num');
            onsets = double(onsets);
            offsets = double(offsets);
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
        
        function varargout = plot(self,varargin)
            
            args.axes = [];
            args.titStr = '';
            args.rasterType = 'dot'; % 'line' or 'dot'
            args.rasterDotSize = 1;
            args.rasterLineWidth = 1;
            args.resp_start_time = -100;
            args.resp_end_time = [];
            args.LineWidth = 0.5;
            args.bin_width = 10;
            args.axis_col = [1 1 1];
            args.FontSize = 8;
            args.t0 = 0;
            args.manuscript = true;
            args.FontName = 'Arial';
            args.show_events = true;
            args.plot_size_centimeters = [];
            args.plot_type = 'raster'; % can be 'raster','sdf','hist' or 'raster-sdf'
            args = parseVarArgs(args,varargin{:});
            
            if isempty(args.axes)
                args.axes = gca;
            end
            
            [spikeTimes,  postStimTime] = fetchn(self,'spike_times','post_stim_time');
            nTrials = length(spikeTimes);
%             if nTrials > 200
%                 rp = randperm(nTrials);
%                 spikeTimes = spikeTimes(rp(1:200));
%             end
            
            e = cellfun(@(x) isempty(x),spikeTimes);
            spikeTimes(e) = {[]};
            if args.t0
                spikeTimes = cellfun(@(x) x-args.t0, spikeTimes,'uni',false);
%                 spikes = spikes - args.t0;
            end
            spikes = cat(1,spikeTimes{:});
            
            
            
            y = 1:length(spikeTimes);
            y = cellfun(@(x,s) x*ones(1,length(s)),num2cell(y),spikeTimes','uni',false);
            y = [y{:}];
            
            keys = fetch(self);
            sub = fetch(fle.SubTrials(keys(1)),'substim_on','substim_off');
            stimTime = sub.substim_off - sub.substim_on;
            
            if any(strcmp(args.plot_type,{'sdf','hist','raster-sdf'}))
                tot_time = double(-args.resp_start_time + stimTime + postStimTime(1)-args.t0);
                bin_edges = args.resp_start_time:args.bin_width:tot_time;
                bin_cen = bin_edges(1:end-1) + args.bin_width/2;
                hc = histc(spikes,bin_edges);
                fr_hz = hc * 1000/(nTrials*args.bin_width);
                fr_hz = fr_hz(1:end-1);
                gw = getGausswin(20,args.bin_width);
                fr_hz_sm = conv(fr_hz,gw,'same');
            end
            switch args.plot_type
                case 'raster'
                    switch args.rasterType
                        case 'dot'
                            plot(spikes,y,'k.','MarkerSize',args.rasterDotSize);
                            ylim([-2 nTrials+1]);
                        case 'line'
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
                        otherwise
                            error('unknown raster type')
                    end
                    if args.manuscript
                        mtitle(args.titStr)
                        mxlabel('Time (ms)')
                        mylabel('Trial number')
                    else
                    PlotTools.title(args.titStr)
                    PlotTools.xlabel('Time (ms)','FontSize',args.FontSize,'FontName',args.FontName)
                    PlotTools.ylabel('Trial number','FontSize',args.FontSize,'FontName',args.FontName)
                    set(gca,'FontName',args.FontName)
                    end
                case 'sdf'
                    plot(bin_cen,fr_hz_sm,'k','Linewidth',args.LineWidth)
                case 'hist'
                    bar(bin_cen,fr_hz,1,'FaceColor','k')
                case 'raster-sdf'
                    ylim([0 nTrials+1]);
                    plot(spikes,y,'k.','MarkerSize',args.rasterDotSize);
                    hold on
                    if args.manuscript
                        mtitle(args.titStr)
                        mxlabel('Time (ms)')
                        mylabel('Trial number')
                    else
                        PlotTools.title(args.titStr)
                        PlotTools.xlabel('Time (ms)','FontSize',args.FontSize,'FontName',args.FontName)
                        PlotTools.ylabel('Trial number','FontSize',args.FontSize,'FontName',args.FontName)
                        set(gca,'FontName',args.FontName)
                    end
                    plot(bin_cen,fr_hz_sm * nTrials/max(fr_hz_sm),'r','Linewidth',args.LineWidth)
                otherwise
                    error('plot_type should be one of "raster","sdf","hist"')
            end
            
            axis tight
            title(args.titStr,'fontsize',7);
            if isempty(args.resp_end_time)
                et = stimTime+postStimTime(1)-args.t0;
            else
                et = args.resp_end_time;
            end
            
            xlim([args.resp_start_time et]);
            % plot stim on and off
            hold on
            
            %
            if args.show_events
                plot(0,0,'*','color',[0 0.5 0])
                plot(stimTime,0,'*r')
            end
            set(gca,'FontSize',args.FontSize,'FontName','Arial','Box','Off',...
                'Color',args.axis_col)
            
            if ~isempty(args.plot_size_centimeters)
                set(gca,'Units','centimeters');
                p = get(gca,'Position');
                p([3 4]) = args.plot_size_centimeters;
                set(gca,'Position',p);
                box off
            end
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

