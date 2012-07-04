% flevbl.BarRf This object computes one dimensional receptive field using the flashes in the
% flash lag experiment.
% MS 2012-02-04
%{
flevbl.BarRf (computed) # my newest table
-> flevbl.BinnedSpikeSets
-> flevbl.SpikeBinParams
-> flevbl.BarRfParams
-> flevbl.BarGrayLevels
-----
bar_size  : tinyblob # width and height of the flashed bars
flash_centers = Null : mediumblob # center of flashes
base = Null: double # baseline firing rate
map = Null: mediumblob # 1D receptive field map
barrf_ts = CURRENT_TIMESTAMP: timestamp   # importing time stamp
%}

classdef BarRf < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.BarRf')
    end
    
    properties
        popRel = flevbl.BinnedSpikeSets * flevbl.SpikeBinParams * flevbl.BarRfParams * ...
            flevbl.BarGrayLevels;
    end
    
    methods
        function self = BarRf(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            k = fetch(flevbl.StimConstants(key),'bar_size_x','bar_size_y','combined');
            key.bar_size = [k.bar_size_x; k.bar_size_y];
            
            c = fetch(flevbl.StimCond(key),'*');
            
            % Get the relational variables
            subTrialRv = flevbl.SubTrials(key);
            binnedSpikeSetsRv = flevbl.BinnedSpikeSets(key);
            spikesBinnedRv = flevbl.SubTrialSpikesBinned(key);
            
            rf_in_arr = unique(fetchn(flevbl.StimCenProxCond('flash_in_rf=1 and mov_shown = 0',...
                key),'arr_rf_in'));
            if isfield(c,'arrangement') && k.combined
                cond = [c.is_flash] & ~[c.is_moving] & [c.arrangement]==rf_in_arr;
            else % previous version of code/ FLE single type
                cond = [c.is_flash] & ~[c.is_moving];
            end
            cond = find(cond & [c.bar_color_r]==key.bar_gray_level);
            
            
            % Get the same number of trials for all conditions
            trials = getSubTrialsByConditions(subTrialRv,cond);
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
            key.flash_centers = flashCenters;
            
            % spontaneous activity (Hz)
            binIndices = getBinIndicesForInterval(binnedSpikeSetsRv,[-key.base_time 0]);
            sp = getSpikeMatrix(spikesBinnedRv,ttt,binIndices);
            key.base = mean(sp(:)) * 1000/key.bin_width;
            
            % map
            binIndices = getBinIndicesForInterval(binnedSpikeSetsRv,[key.min_lag key.max_lag]);
            sp = getSpikeMatrix(spikesBinnedRv,ttt,binIndices);
            key.map = permute(mean(sp,1),[3 2 1]) * 1000/key.bin_width;
            self.insert(key);
        end
        
        
        
        function [peakInd SNR] = getCenter(self,varargin)
            
            args.nStdForSig = 0.5; % number of standard deviations to cover signal
            args.snrTh = 1.5;
            args.fitPval = 0.2;
            args.fitCenter = true;
            args.resp_win_start = 30;
            args.resp_win_end = 100;
            args.minFr = 5;
            args = parseVarArgs(args,varargin{:});
            
            % Find flash index where the firing rate was maximum
            keys = fetch(self);
            p = fetch(self,'*');
            nUnits = length(p);
            peakInd = nan(1,nUnits);
            SNR = nan(1,nUnits);
           
            fp = fetch(flevbl.BarRfFit(self),'fit_params');
            
            
            for iUnit = 1:nUnits
                
                if args.fitCenter
                    b = fp(iUnit).fit_params;
                    peakInd(iUnit) = round(b(3));                    
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
            end
        end
        
        
        function varargout = plot(self,varargin)
            
            assert(count(self)==1,'Plot works only for single tuple relations!');
            
            args.figure = [];
            args.showFit = true;
            args.showRfCen = true;
            args.showFitRfCen = true;
            args.resp_win_start = 50;
            args.xAxisInDeg = true;
            args.resp_win_end = 120;
            args.twoDim = false;
            args = parseVarArgs(args,varargin{:});
            
            % open new figure window or plot in existing one?
            fig = PlotTools.figure(args.figure);
            if args.twoDim
                set(gcf,'Position',[158,116,950,464])
            end
            % plot space-time map
            if args.twoDim
                mh = PlotTools.subplot(3,2,[1 3]);
            else
                mh = PlotTools.subplot(3,1,[1 2]);
            end
            p = fetch(self,'min_lag','max_lag','bin_width','base',...
                'map','unit_id','flash_centers');
            tau = p.min_lag+p.bin_width/2:p.bin_width:p.max_lag;
            x = 1:size(p.map,2);
            
            imagesc(x,tau,p.map);
            
            colormap(gray)
            ca = caxis;
            
            set(gca,'YDir','normal','CLim',[0 ca(2)])
            PlotTools.xlabel('Location')
            PlotTools.ylabel('Time rel. to flash onset')
            
            sds = fetch1(acq.Sessions(self),'session_datetime');
            PlotTools.title(sprintf('Space-time rf (unit %u)     %s',p.unit_id,sds));
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
            spatMap = getSpatialMap(self);
            
            plot(x,spatMap,'.-k',xx,base,':k')
            PlotTools.xlabel('Location')
            PlotTools.ylabel('Firing rate (Hz)')
            set(colorbar,'Visible','off')
            set(gca,'XLim',xx)
            hold on;
            
            % Change x axis units to degrees
            if args.xAxisInDeg
                % Get the real bar position in degrees
                mp = fetch(flevbl.StimConstants(self),'monitor_distance','resolution_x',...
                    'monitor_center_x','monitor_size_x');
                
                distX = p.flash_centers(1,:)- mp.monitor_center_x;
                xDeg = pixels2degrees(distX, mp.monitor_distance, mp.resolution_x, ...
                    mp.monitor_size_x);
                
                xDeg = round(xDeg * 10)/10;
                
                set(mh,'XTick',x(1:3:end),'XTickLabel',xDeg(1:3:end));
                set(sh,'XTick',x(1:3:end),'XTickLabel',xDeg(1:3:end));
                PlotTools.xlabel(mh,'Location (deg)')
                PlotTools.xlabel(sh,'Location (deg)')
            end
            
            % Show fit
            if args.showFit
                [b,fs] = getFitData(flevbl.BarRfFit(self));
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
                cenUf = getCenter(self,'fitCenter',false);
                cenF = getCenter(self,'fitCenter',true);
                yl = ylim;
                axes(sh);hold on;
                
                plot(cenUf,yl(1),'k.','MarkerSize',20);
                plot(cenF,yl(1),'r.','MarkerSize',20);
                disp([cenUf cenF]);
            end
            
            if args.twoDim
                PlotTools.subplot(3,2,[2 4]);
                k = fetch(self);
                rv = rf.MapSets(sprintf('unit_id=%u',k.unit_id)) & ...
                    ephys.SpikeSet(self);
                if count(rv)==1
                    plot(rf.MapAvg(fetch(rv),'map_type_num=3'));
                    PlotTools.title(sprintf('2D receptive field (unit %u)',p.unit_id));
                end
                
            end
            % return handle?
            if nargout > 0
                varargout{1} = fig;
            end
        end
        
        function [r lags] = getSpatialMap(self)
            % Get spatial receptive field profile by integrating over time.
            % r = getSpatialMap(self);
            % MS 2012-06-24
            assert(count(self)==1,'Supported only for single tuple relations !')
            p = fetch(self,'min_lag','max_lag','bin_width','base','map');
            lags = p.min_lag:p.bin_width:p.max_lag;
            lags = lags(1:end-1);
            
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
            fp = lsqcurvefit(@flevbl.BarRf.gauss,a,x,yi,lb,ub,opt);
            % Test significance
            % ANOVA testing
            % Model: (yi-ym) = (yhat-ym) + (yi - yhat) => SST = SSM + SSE
            yhat = flevbl.BarRf.gauss(fp,x);
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
            % Get spatial map averaged over time
            r = mean(p.map(selLagInd,:),1);
        end
        
        function varargout = plotSpaceTimeRf(self,varargin)
            
            assert(count(self)==1,'Plot works only for single tuple relations!');
            
            args.axes = [];
            args.showFit = true;
            args.showRfCen = true;
            args.showFitRfCen = true;
            args.resp_win_start = 50;
            args.xAxisInDeg = true;
            args.resp_win_end = 120;
            args.FontSize = 14;
            args = parseVarArgs(args,varargin{:});
            
            % open new figure window or plot in existing one?
            %                 fig = PlotTools.figure();
            if ~isempty(args.axes)
                axes(args.axes)
            else
                set(gcf,'Position',[360,437,425,261])
            end
            % plot space-time map
            mh = gca;
            p = fetch(self,'min_lag','max_lag','bin_width','base',...
                'map','unit_id','flash_centers');
            tau = p.min_lag+p.bin_width/2:p.bin_width:p.max_lag;
            x = 1:size(p.map,2);
            w = gausswin(5);
            w = w*w';
            w = w/sum(w(:));
            map = imfilter(p.map,w,'same');
            imagesc(x,tau,map);
            
            colormap(gray)
            ca = caxis;
            
            set(gca,'YDir','normal','CLim',[0 ca(2)])
            c = PlotTools.colorbar;
            set(c,'FontSize',args.FontSize);
            set(gca,'FontSize',args.FontSize);
            
            
            % Change x axis units to degrees
            if args.xAxisInDeg
                % Get the real bar position in degrees
                mp = fetch(flevbl.StimConstants(self),'monitor_distance','resolution_x',...
                    'monitor_center_x','monitor_size_x');
                
                distX = p.flash_centers(1,:)- mp.monitor_center_x;
                distX = distX(1:3:end);
                xDeg = pixels2degrees(distX, mp.monitor_distance, mp.resolution_x, ...
                    mp.monitor_size_x);
                
                xDeg = round(xDeg * 100)/100;
                
                set(mh,'XTick',x(1:3:end),'XTickLabel',xDeg);
            end
            
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