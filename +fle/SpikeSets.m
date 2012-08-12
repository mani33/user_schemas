% fle.SpikeSets -

%{
fle.SpikeSets (computed) # my newest table
-> fle.Phys
-> fle.SpikeWinParams

-----
spikesets_ts = CURRENT_TIMESTAMP:   timestamp # do not edit
%}

classdef SpikeSets < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.SpikeSets')
        popRel = fle.Phys * fle.SpikeWinParams;
    end
    
    methods
        function self = SpikeSets(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % Populate subtables
            makeTuples(fle.SubTrialSpikes,key)
        end
    end
    methods
        function [mfr_dir0 mfr_dir1] = getDirSelResp(self,dx,resp_win_start,resp_win_end)
            % function dsi = getDirSelInd(self,dx,resp_win_start,resp_win_end)
            
            key = fetch(self);
            mfr_dir0 = nan;
            mfr_dir1 = nan;
            
            % Get receptive field center flash location
            rfLocInd = getCenter(fle.FlashRf(key),'fitCenter',false);
            
            if isnan(rfLocInd)
                return;
            end
            
            cond = fetch(fle.StimCond(key),'*');
            meanFr = nan(1,2);
            misAlignTol = 10; % pix - misalignment between flash and moving bar location allowed
            
            for direction = 0:1
                % moving bar condition
                mCond = [cond.is_moving] & ~[cond.is_flash] & [cond.direction]==direction & ...
                    [cond.dx] == dx;
                mc = find(mCond,1);
                rfArr = getStimCenProxArrForCond(fle.TrialGroup(key),mc,'moving');
                mc = find(mCond & [cond.arrangement]==rfArr);
                
                zeroPoint = getTrajRelTimeAtFlashLoc(fle.TrialGroup(key),rfLocInd,dx,direction,...
                    misAlignTol,false);
                if isempty(zeroPoint)
                    fprintf('No matching found between flash and moving bars for speed %u\n',dx);
                    continue;
                end
                win = [resp_win_start resp_win_end] + zeroPoint;
                
                key = fetch(self);
                qs = sprintf('cond_idx = %u',mc);
                spikes = fetchn(fle.SubTrialSpikes(key) & fle.SubTrials(qs), 'spike_times');
                meanFr(direction+1) = 1000 * sum(cellfun(@(x) length(x(x >= win(1) & x < win(2))),spikes))...
                    /diff(win)/length(spikes); % Hz
            end
            mfr_dir0 = meanFr(1);
            mfr_dir1 = meanFr(2);
            
        end
        
        function [mfr_dir0 mfr_dir1] = getRfBoundaryBasedDirSelResp(self,dx,pre_rf_entry_time,post_rf_entry_time)
            % function dsi = getRfBoundaryBasedDirSelResp(self,dx,resp_win_start,resp_win_end)
            
            key = fetch(self);
            mfr_dir0 = nan;
            mfr_dir1 = nan;
            
            rd = fetch(fle.FlashRespStat(key),'is_responsive','cond_idx');
            
            % Get the first and last responsive bar locations
            [condIdx,ind] = sort([rd.cond_idx]);
            is_responsive = [rd(ind).is_responsive];
            rfBoundLeft = condIdx(find(is_responsive,1,'first'));
            rfBoundRight = condIdx(find(is_responsive,1,'last'));
            
            if numel([rfBoundLeft rfBoundRight])==0
                return;
            end
            
            cond = fetch(fle.StimCond(key),'*');
            meanFr = nan(1,2);
            misAlignTol = 10; % pix - misalignment between flash and moving bar location allowed
            
            for direction = 0:1
                % moving bar condition
                mCond = [cond.is_moving] & ~[cond.is_flash] & [cond.direction]==direction & ...
                    [cond.dx] == dx;
                mc = find(mCond,1);
                rfArr = getStimCenProxArrForCond(fle.TrialGroup(key),mc,'moving');
                mc = find(mCond & [cond.arrangement]==rfArr);
                
                entryTimeLeft = getTrajRelTimeAtFlashLoc(fle.TrialGroup(key),rfBoundLeft,dx,direction,...
                    misAlignTol,false);
                
                entryTimeRight = getTrajRelTimeAtFlashLoc(fle.TrialGroup(key),rfBoundRight,dx,direction,...
                    misAlignTol,false);
                
                win = sort([entryTimeLeft entryTimeRight]);
                win = win + [-pre_rf_entry_time post_rf_entry_time];
                
                key = fetch(self);
                qs = sprintf('cond_idx = %u',mc);
                spikes = fetchn(fle.SubTrialSpikes(key) & fle.SubTrials(qs), 'spike_times');
                meanFr(direction+1) = 1000 * sum(cellfun(@(x) length(x(x >= win(1) & x < win(2))),spikes))...
                    /diff(win)/length(spikes); % Hz
            end
            mfr_dir0 = meanFr(1);
            mfr_dir1 = meanFr(2);
        end
        
        function plotRasters(self,varargin)
            
            % rfCond = 0(stim outside rf) or = 1 or = -1(stim inside or outside rf)
            % combinedStim = 1(moving and flashed bars present in subtrial); = 0(single stim only)
            %
            arg.barTypes = {'flash','moving'}; % {'flash','moving'} or 'flash' or 'moving'
            arg.rfCond = true; % stim in the receptive field or not
            arg.combinedStim = false; % plot combined stim?
            arg.plotsPerPage = 20;
            arg.pause = true;
            arg = parseVarArgs(arg,varargin{:});
            argList = struct2argList(arg);
            
            key = fetch(self);
            misAlignTol = 10;
            
            cond = fetch(fle.StimCond(key),'*');
            [condIdx condStr] = getSelCond(fle.TrialGroup(key),argList{:});
            nCond = length(condIdx);
            cc = 0;
            
            for iCond = 1:nCond
                cc = cc + 1;
                currCondIdx = condIdx(iCond);
                if cc==1 || cc > arg.plotsPerPage
                    figure;
                    set(gcf,'Position',[102,101,1124,575])
                end
                if cc > arg.plotsPerPage
                    cc = 1;
                end
                
                ax = subplot(4,5,cc);
                cs = sprintf('cond_idx=%u',currCondIdx);
                stsRv = fle.SubTrialSpikes(key) & fle.SubTrials(cs);
                plotSpikes(stsRv,'axes',ax,'titStr',condStr{iCond});
                
                %                 if cond(currCondIdx).is_moving
                %                     rfLocInd = getCenter(fle.FlashRf(key));
                %                     dx = cond(currCondIdx).dx;
                %                     direction = cond(currCondIdx).direction;
                %                     zeroTimePoint = getTrajRelTimeAtFlashLoc(fle.TrialGroup(key),rfLocInd,dx,direction,misAlignTol);
                %                     plot(zeroTimePoint,0,'b*');
                %                 end
            end
        end
    end
end

