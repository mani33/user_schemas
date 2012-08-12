% fle.BarRf This object computes one dimensional receptive field using the flashes in the
% flash lag experiment.
% MS 2012-02-04
%{
fle.BarRf (computed) # my newest table
-> fle.BinnedSpikeSets
-> fle.SpikeBinParams
-> fle.BarRfParams
-----
bar_size  : tinyblob # width and height of the flashed bars
flash_centers = Null : mediumblob # center of flashes
base = Null: double # baseline firing rate
map = Null: mediumblob # 1D receptive field map
barrf_ts = CURRENT_TIMESTAMP: timestamp   # importing time stamp
%}

classdef BarRf < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.BarRf')
        popRel = fle.BinnedSpikeSets * fle.SpikeBinParams * fle.BarRfParams;
    end
    
    methods
        function self = BarRf(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            k = fetch(fle.StimConstants(key),'bar_size_x','bar_size_y','stim_center_x',...
                'stim_center_y','combined');
            key.bar_size = [k.bar_size_x; k.bar_size_y];
            stimCen = [k.stim_center_x; k.stim_center_y];
            
            c = fetch(fle.StimCond(key),'*');
            
            % Get the relational variables
            subTrialRv = fle.SubTrials(key);
            binnedSpikeSetsRv = fle.BinnedSpikeSets(key);
            spikesBinnedRv = fle.SubTrialSpikesBinned(key);
            
            if isfield(c,'arrangement') && k.combined
                % Find the correct arrangement in which the flash was in the
                % receptive field
                arr0 = find([c.is_flash] & ~[c.is_moving] & [c.arrangement]==0);
                arr1 = find([c.is_flash] & ~[c.is_moving] & [c.arrangement]==1);
                
                flashCen0 = fetchn((subTrialRv & sprintf('cond_idx = %u',arr0(1))),'flash_centers');
                flashCen1 = fetchn((subTrialRv & sprintf('cond_idx = %u',arr1(1))),'flash_centers');
                
                % Get flash centers for both arrangements to determine which
                % one was in the receptive field
                flashCen0 = flashCen0{1}{:};
                flashCen1 = flashCen1{1}{:};
                d = [flashCen0(2) flashCen1(2)]-stimCen(2);
                [~,ind] = min(abs(d));
                inRfArrInd = ind-1;
                cond = find([c.is_flash] & ~[c.is_moving] & [c.arrangement]==inRfArrInd);
            else % previous version of code/ FLE single type
                cond = find([c.is_flash] & ~[c.is_moving]);
            end
            
            
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
    end
    
    methods
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
            qs = sprintf('resp_win_start = %u and resp_win_end = %u',args.resp_win_start,...
                args.resp_win_end);
            fp = fetch(fle.BarRfFit(self,qs),'fit_params');
            
            
            for iUnit = 1:nUnits
                
                %                 y = getSpatialMap(self & keys(iUnit),args.resp_win_start,args.resp_win_end);
                %                 % Compute SNR
                %                 nFlash = length(p(iUnit).flash_centers);
                %                 flashInd = 1:nFlash;
                
                if args.fitCenter
                    b = fp(iUnit).fit_params;
                    peakInd(iUnit) = round(b(3));
                    %                     % Apply a series of filters to get rid of spurious receptive fields
                    %                     pVal = getSignificanceOfFit(fle.BarRfFit(self & keys(iUnit)));
                    %                     if pVal > args.fitPval || b(3) < 1 || b(3) > nFlash
                    %                         continue;
                    %                     end
                    %                     %                     sr = [(b(3)-b(4)*args.nStdForSig) b(3)+b(4)*args.nStdForSig];
                    %                     sr = [(b(3)-b(4)*args.nStdForSig) b(3)+b(4)*args.nStdForSig];
                    %                     lowEnd = floor(sr(1));
                    %                     highEnd = ceil(sr(2));
                    %                     signalInd = (flashInd >= lowEnd) & (flashInd <= highEnd);
                    %
                    %                     % Minimum firing rate criterion
                    %                     if mean(y(signalInd)) < args.minFr
                    %                         continue;
                    %                     end
                    %
                    %                     if length(find(signalInd))==nFlash
                    %                         signalInd([1 end]) = false;
                    %                     end
                    %                     noiseInd = ~signalInd;
                    %                     SNR(iUnit) = mean(y(signalInd))/mean(y(noiseInd));
                    %
                    %                     if SNR(iUnit) > args.snrTh
                    %                         peakInd(iUnit) = round(b(3));
                    %                     end
                else
                    y = getSpatialMap(self & keys(iUnit),args.resp_win_start,args.resp_win_end);
                    
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
            spatMap = getSpatialMap(self,args.resp_win_start,args.resp_win_end);
            
            plot(x,spatMap,'.-k',xx,base,':k')
            PlotTools.xlabel('Location')
            PlotTools.ylabel('Firing rate (Hz)')
            set(colorbar,'Visible','off')
            set(gca,'XLim',xx)
            hold on;
            
            % Change x axis units to degrees
            if args.xAxisInDeg
                % Get the real bar position in degrees
                mp = fetch(fle.StimConstants(self),'monitor_distance','resolution_x',...
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
                [b,fs] = getFitData(fle.BarRfFit(self));
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
        
        function r = getSpatialMap(self,resp_win_start,resp_win_end)
            % Get spatial receptive field profile by integrating over time.
            %   r = getSpatialMap(self);
            % MS 2012-02-08
            assert(count(self)==1,'Supported only for single tuple relations !')
            p = fetch(self,'min_lag','max_lag','bin_width','base','map');
            lags = p.min_lag:p.bin_width:p.max_lag;
            selLagInd = lags > resp_win_start & lags <= resp_win_end;
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
            args.FontSize = 8;
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
            
            pixPerDeg = fetch1(vstim.PixPerDeg(self),'pix_per_deg');
            % Change x axis units to degrees
            if args.xAxisInDeg
                % Get the real bar position in degrees
                mp = fetch(fle.StimConstants(self),'monitor_distance','resolution_x',...
                    'monitor_center_x','monitor_size_x');
                
                distX = p.flash_centers(1,:)- mp.monitor_center_x;
                distX = distX(1:3:end);
%                 xDeg = pixels2degrees(distX, mp.monitor_distance, mp.resolution_x, ...
%                     mp.monitor_size_x);
                xDeg = distX/pixPerDeg;
                xDeg = arrayfun(@(x) sprintf('%0.1f',x),xDeg,'uni',false);
                dis = round(length(x)/5);
                set(mh,'XTick',x(1:dis:end),'XTickLabel',xDeg);
            end
            
            % return handle?
            if nargout > 0
                varargout{1} = fig;
            end
        end
    end
end