%{
fle.BarRfMov (computed) # Bar receptive field when another bar moved outside rf
-> fle.BarGrayLevels
-> fle.BarRfParams
-> fle.BinnedSpikeSets
-> fle.SpikeBinParams
direction : boolean # motion direction
-----
bar_size  : tinyblob # width and height of the flashed bars
flash_centers = Null : mediumblob # center of flashes
base = Null: double # baseline firing rate
map = Null: mediumblob # 1D receptive field map
barrf_ts = CURRENT_TIMESTAMP: timestamp   # importing time stamp
%}

classdef BarRfMov < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.BarRfMov')
        popRel = ((fle.BarGrayLevels*fle.BarRfParams*fle.BinnedSpikeSets*...
            fle.SpikeBinParams)&fle.StimConstants('combined=1'))& fle.CombinedFlashOnset  % !!! update the populate relation
    end
    methods
        function self = BarRfMov(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            tuple = key;
            k = fetch(fle.StimConstants(key),'bar_size_x','bar_size_y','combined');
            tuple.bar_size = [k.bar_size_x; k.bar_size_y];
            
            c = fetch(fle.StimCond(key),'*');
            
            % Get the relational variables
            subTrialRv = fle.SubTrials(key);
            binnedSpikeSetsRv = fle.BinnedSpikeSets(key);
            for iDir = 1:2
                mov_dir = iDir-1;
                tuple.direction = mov_dir;
                
                rf_in_arr = unique(fetchn(fle.StimCenProxCond(sprintf('flash_in_rf=1 and mov_shown = 1 and direction = %u',...
                    mov_dir),key),'arr_rf_in'));
                if isfield(c,'arrangement')
                    cond = [c.is_flash] & [c.direction] == mov_dir & [c.is_moving] & ...
                        [c.arrangement]==rf_in_arr & [c.bar_color_r]==key.bar_gray_level;
                else % previous version of code/ FLE single type
                    cond = [c.is_flash] & [c.direction]== mov_dir & [c.is_moving] & ...
                        [c.bar_color_r]==key.bar_gray_level;
                end
                cond_idx = [c(cond).cond_idx];
                
                
                % Get the same number of trials for all conditions
                trials = getSubTrialsByConditions(subTrialRv,cond_idx);
                nT = cellfun(@length,trials);
                mT = min(nT);
                trials = cellfun(@(x) x(1:mT),trials,'UniformOutput',false);
                ttt = [trials{:}];
                
                flashCenters = getParamsBySubTrials(subTrialRv,ttt(1,:),'flash_centers');
                cells = true;
                
                % Hack! hack! hack! Don't do this!
                while cells
                    flashCenters = [flashCenters{:}];
                    if ~iscell(flashCenters)
                        cells = false;
                    end
                end
                tuple.flash_centers = flashCenters;
                
                % spontaneous activity (Hz)
                % Adjust spike window because stimulus onset times in the combined case
                % corresponds to the onset of motion, not onset of flash.
                % For each flash location, the relative flash onset time will differ. So
                % we need to compute it for each flash location.
                nLoc = size(ttt,2);
                maxFlashOnsetJitter = 1.5; % ms jitter on flash onset between subtrials
                for iLoc = 1:nLoc
                    qs = sprintf('subtrial_num in %s',util.array2csvStr(ttt(:,iLoc)));
                    flash_onsets = fetchn(fle.CombinedFlashOnset(key,qs),'t');
                    mov_onsets = fetchn(fle.SubTrials(key,qs),'substim_on');
                    delay = flash_onsets - mov_onsets;
                    assert(range(delay) < maxFlashOnsetJitter, 'subtrials differ by more than 1 ms in  event times')
                    mdelay = median(delay);
                    
                    % Get spike counts
                    sc = fetchn(fle.SubTrialSpikesBinned(key, qs),'spike_counts');
                    b_len = cellfun(@length,sc);
                    assert(range(b_len)<2,'the difference in total bins between subtrials is more than 1')
                    
                    % Get a baseline
                    adjustedWin = [-key.base_time 0] + mdelay;
                    binIndices = getBinIndicesForInterval(binnedSpikeSetsRv,adjustedWin);
                    
                    scb = cellfun(@(x) x(binIndices), sc,'uni',false);
                    scb = [scb{:}];
                    scdata.base(iLoc) = mean(mean(scb));
                    
                    % Bar map
                    adjustedWin = [key.min_lag key.max_lag] + mdelay;
                    [binIndices, scdata.binCenTimes{iLoc}] = getBinIndicesForInterval(binnedSpikeSetsRv,adjustedWin);
                    scm = cellfun(@(x) x(binIndices), sc,'uni',false);
                    scm = [scm{:}];
                    scdata.map{iLoc} = mean(scm,2) * 1000/key.bin_width;
                end
                tuple.base = mean(scdata.base(:)) * 1000/key.bin_width;
                % Map
                bt = cellfun(@length,scdata.binCenTimes);
                mbt = min(bt);
                map = cellfun(@(x) x(1:mbt),scdata.map,'uni',false);
                tuple.map = [map{:}];
                self.insert(tuple);
            end
        end
    end
    
    methods
        function [peakInd SNR] = getCenter(self,varargin)
            
            args.nStdForSig = 0.5; % number of standard deviations to cover signal
            args.snrTh = 1.5;
            args.fitPval = 0.2;
            args.fitCenter = true;
            args.resp_win_start = 30;
            args.resp_win_end = 100;
            args.interpCenter = false;
            args.minFr = 20;
            
            args = parseVarArgs(args,varargin{:});
            
            % Find flash index where the firing rate was maximum
            keys = fetch(self);
            p = fetch(self,'*');
            nUnits = length(p);
            peakInd = nan(1,nUnits);
            SNR = nan(1,nUnits);
            
            fp = fetch(fle.BarRfMovFit*self ,'*');
            
            
            for iUnit = 1:nUnits
                y = getSpatialMap(self & keys(iUnit));
                
                if args.fitCenter
                    b = fp(iUnit).fit_params;
                    if args.interpCenter
                        peakInd(iUnit) = b(3);
                    else
                        peakInd(iUnit) = round(b(3));
                    end
                else
                    y = getSpatialMap(self & keys(iUnit));
                    [~,peakInd(iUnit)] = max(y);
                    peaks = find(y==peakInd);
                    nPeaks = length(peaks);
                    if nPeaks > 1
                        rp = randperm(nPeaks);
                        peakInd(iUnit) = peaks(rp(1));
                        fprintf('%u peaks found; choosing peak number %u',nPeaks,rp(1));
                    end
                end
                % If the peakInd is outside the flash locations, set it to NaN
                nfl = size(fp(iUnit).flash_centers,2);
                if peakInd(iUnit) < 1 || peakInd(iUnit) > nfl
                    peakInd(iUnit) = NaN;
                end
                
                % Apply minimum firing rate filter
                if ~isnan(peakInd)
                    s = max(round(peakInd)-2,1);
                    e = min(round(peakInd)+2,size(y,2));
                    pk = y(:,s:e);
                    if mean(pk(:)) < args.minFr
                        peakInd(iUnit) = NaN;
                    end
                end
            end
            
        end
        
        
        function varargout = plot(self,varargin)
            
            args.figure = [];
            args.showFit = true;
            args.showRfCen = true;
            args.showFitRfCen = true;
            args.resp_win_start = 50;
            args.xAxisInDeg = true;
            args.resp_win_end = 120;
            args.twoDim = true;
            args.pause = true;
            args = parseVarArgs(args,varargin{:});
            keys = fetch(self);
            nKeys = length(keys);
            for iKey = 1:nKeys
                disp(iKey)
                key = keys(iKey);
                % open new figure window or plot in existing one?
                fig = PlotTools.figure(args.figure);
                if args.twoDim
                    %                     set(gcf,'Position',[158,116,950,464])
                end
                % plot space-time map
                if args.twoDim
                    mh = PlotTools.subplot(3,2,[1 3]);
                else
                    mh = PlotTools.subplot(3,1,[1 2]);
                end
                p = fetch(self & key,'min_lag','max_lag','bin_width','base',...
                    'map','unit_id','flash_centers');
                tau = p.min_lag+p.bin_width/2:p.bin_width:p.max_lag;
                x = 1:size(p.map,2);
                
                imagesc(x,tau,p.map);
                
                colormap(gray)
                ca = caxis;
                
                set(gca,'YDir','normal','CLim',[0 ca(2)])
                PlotTools.xlabel('Location')
                PlotTools.ylabel('Time rel. to flash onset')
                
                sds = fetch1(acq.Sessions(self & key),'session_datetime');
                elec_num = fetch1(ephys.Spikes(key),'electrode_num');
                titStr = sprintf('Space-time rf (unit %u  elec num %u)     %s',p.unit_id,elec_num,sds);
                PlotTools.title(titStr);
                c = PlotTools.colorbar;
                PlotTools.ylabel(c,'Firing rate (Hz)')
                
                % plot spatial profile
                dx = diff(x(1:2)) / 2;
                xx = [x(1)-dx x(end)+dx];
                base = repmat(p.base,1,2);
                if args.twoDim
                    sh = PlotTools.subplot(3,2,5);
                else
                    sh = PlotTools.subplot(3,1,3);
                end
                spatMap = getSpatialMap(self & key);
                
                plot(x,spatMap,'.-k',xx,base,':k')
                PlotTools.xlabel('Location')
                PlotTools.ylabel('Firing rate (Hz)')
                set(colorbar,'Visible','off')
                set(gca,'XLim',xx)
                hold on;
                
                % Change x axis units to degrees
                if args.xAxisInDeg
                    % Get the real bar position in degrees
                    mp = fetch(fle.StimConstants(self & key),'monitor_distance','resolution_x',...
                        'monitor_center_x','monitor_size_x');
                    
                    distX = p.flash_centers(1,:)- mp.monitor_center_x;
                    xDeg = distX/fetch1(vstim.PixPerDeg(key),'pix_per_deg',1);
                    
                    xDeg = round(xDeg * 100)/100;
                    
                    set(mh,'XTick',x(1:3:end),'XTickLabel',xDeg(1:3:end));
                    set(sh,'XTick',x(1:3:end),'XTickLabel',xDeg(1:3:end));
                    PlotTools.xlabel(mh,'Location (deg)')
                    PlotTools.xlabel(sh,'Location (deg)')
                end
                
                % Show fit
                if args.showFit
                    [b,fs] = getFitData(fle.BarRfMovFit(self & key));
                    xi = linspace(x(1),x(end),25);
                    fn = str2func(fs);
                    yi = fn(b,xi);
                    plot(xi,yi,'r--');
                    stdMarks = 1*[-b(4) b(4)] + b(3);
                    plot(round(stdMarks),[0 0],'y*');
                    axes(mh);hold on;
                    plot(mh,round(stdMarks),[0 0],'y*');
                end
                if args.showRfCen
                    cenUf = getCenter(self & key,'fitCenter',false);
                    cenF = getCenter(self & key,'fitCenter',true);
                    yl = ylim;
                    axes(sh);hold on;
                    
                    plot(cenUf,yl(1),'k.','MarkerSize',20);
                    plot(cenF,yl(1),'r.','MarkerSize',20);
                    disp([cenUf cenF]);
                end
                
                if args.twoDim
                    PlotTools.subplot(3,2,[2 4]);
                    k = fetch(self & key);
                    rv = rf.MapSets(sprintf('unit_id=%u',k.unit_id)) & ...
                        ephys.SpikeSet(self & key);
                    if count(rv)==1
                        plot(rf.MapAvg(fetch(rv),'map_type_num=3'));
                        PlotTools.title(sprintf('2D receptive field (unit %u)',p.unit_id));
                    end
                end
                
                if nKeys > 1 && args.pause
                    pause
                    close
                end
                % return handle?
                if nargout > 0
                    varargout{1} = fig;
                end
            end
        end
        
        function [r lags] = getSpatialMap(self)
            % Get spatial receptive field profile by integrating over time.
            % r = getSpatialMap(self);
            % MS 2012-06-24
            assert(count(self)==1,'Supported only for single tuple relations !')
            p = fetch(self,'min_lag','max_lag','bin_width','base','map');
            
            %             lags = p.min_lag:p.bin_width:p.max_lag;
            %             lags = lags(1:size(p.map,1));
            lags = linspace(p.min_lag, p.max_lag, size(p.map,1));
            % First find the peak in time and decide the response time window around it.
            spaceAvg = mean(p.map,2);
            opt = optimset('display','off');
            a(1) = p.base;
            [a(2),a(3)] = max(spaceAvg);
            a(2) = a(2) - a(1);
            a(4) = 1;
            yi = spaceAvg;
            n = length(yi);
            x = (1:n)';
            lb = [0 0 0 0];
            ub = [1000 100 max(lags) max(lags)];
            fp = lsqcurvefit(@fle.BarRfMov.gauss,a,x,yi,lb,ub,opt);
            selLagInd = 1:length(lags);
            if fp(3) >= 1 && fp(3) <= length(lags)
                % Test significance
                % ANOVA testing
                % Model: (yi-ym) = (yhat-ym) + (yi - yhat) => SST = SSM + SSE
                yhat = fle.BarRfMov.gauss(fp,x);
                SSerror= sum((yi - yhat).^2);
                SSmodel = sum((yhat - mean(yi)).^2);
                dfm = length(fp)-1; % parameters
                dfe = n - dfm;
                
                MSerror = SSerror / dfe;
                MSmodel = SSmodel / dfm;
                
                F = MSmodel / MSerror;
                
                pValue = 1 - fcdf(F,dfm,dfe);
                if F > 10  && pValue < 0.001
                    % y = b(1) + b(2) * exp(-(x - b(3)).^2 / (2*(b(4)^2)));
                    lagIndEnd = round(fp(3) + fp(4)*3); % 2.5 std boundary
                    lagIndStart = round(fp(3) - fp(4)*3);
                    if lagIndStart < 1
                        lagIndStart = 1;
                    end
                    if lagIndEnd > length(yi)
                        lagIndEnd = length(yi);
                    end
                    selLagInd = lags > lags(lagIndStart) & lags < lags(lagIndEnd);
                else
                    selLagInd = 1:length(lags);
                end
            end
            % Get spatial map averaged over time
            r = mean(p.map(selLagInd,:),1);
        end
        
        function varargout = plotSpaceTimeRf(self,varargin)
            
            assert(count(self)==1,'Plot works only for single tuple relations!');
            
            args.axes = [];
            args.showFit = false;
            args.showRfCen = false;
            args.showFitRfCen = false;
            args.resp_win_start = 50;
            args.xAxisInDeg = true;
            args.resp_win_end = 120;
            args.FontSize = 7;
            args.smooth = false;
            args = parseVarArgs(args,varargin{:});
            
            % open new figure window or plot in existing one?
            %                 fig = PlotTools.figure();
            if ~isempty(args.axes)
                axes(args.axes)
            else
                set(gcf,'Position',[360,437,425,261])
            end
            % plot space-time map
            key = fetch(self);
            mh = gca;
            p = fetch(self,'min_lag','max_lag','bin_width','base',...
                'map','unit_id','flash_centers');
            tau = p.min_lag+p.bin_width/2:p.bin_width:p.max_lag;
            x = 1:size(p.map,2);
            map = p.map;
            if args.smooth
                w = gausswin(5);
                w = w*w';
                w = w/sum(w(:));
                map = imfilter(p.map,w,'same');
            end
            imagesc(x,tau,map);
            
            colormap(gray)
            ca = caxis;
            
            set(gca,'YDir','normal','CLim',[0 ca(2)])
            %             c = PlotTools.colorbar;
            %             set(c,'FontSize',args.FontSize);
            set(gca,'FontSize',args.FontSize);
            
            
            % Change x axis units to degrees
            if args.xAxisInDeg
                % Get the real bar position in degrees
                mp = fetch(fle.StimConstants(self),'monitor_distance','resolution_x',...
                    'monitor_center_x','monitor_size_x');
                
                distX = p.flash_centers(1,:)- mp.monitor_center_x;
                distX = distX(1:3:end);
                xDeg = pixels2degrees(distX, mp.monitor_distance, mp.resolution_x, ...
                    mp.monitor_size_x);
                
                xDeg = round(xDeg * 100)/100;
                
                set(mh,'XTick',x(1:3:end),'XTickLabel',xDeg);
            end
            elec_num = fetch1(ephys.Spikes(key),'electrode_num');
            titStr = sprintf('electrode num: %u',elec_num);
            title(titStr)
            % return handle?
            if nargout > 0
                varargout{1} = fig;
            end
        end
    end
    methods(Static)
        function y = gauss(b,x)
            y = b(1) + b(2) * exp(-(x - b(3)).^2 / (2*(b(4)^2)));
        end
    end
end