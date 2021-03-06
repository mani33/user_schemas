% fle.TrialGroup - Subset of FlePhysEffExperiment sessions

%{
fle.TrialGroup (computed) # my newest table
-> stimulation.StimTrialGroup
-----

%}

classdef TrialGroup < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.TrialGroup')
        popRel = (stimulation.StimTrialGroup - acq.StimulationIgnore) &...
            acq.Stimulation('exp_type like "FlePhys%Experiment" and correct_trials >= 300')...
            - acq.SessionsIgnore
    end
    
    methods
        function self = TrialGroup(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % Populate subtables
%             makeTuples(fle.Phys,key)
            makeTuples(fle.StimCond,key)
            makeTuples(fle.StimConstants,key)
            makeTuples(fle.DxVals,key)
            makeTuples(fle.BarGrayLevels,key)
            makeTuples(fle.SubTrials,key)
            
        end
    end
    methods
        function [zeroTimePoint, misAlignPixUsed, movCond] = getTrajRelTimeAtFlashLoc(self,flashLocation,...
                dx,direction,barLum,motionType)
            %             function [zeroTimePoint misAlignPixUsed] = getTrajRelTimeAtFlashLoc(self,flashLocation,...
            %                     dx,direction,barLum,motionType)
            % input 'motionType' should be 'cont','init' or 'stop'.
            
            if isnan(flashLocation)
                zeroTimePoint = NaN;
                return;
            end
            misAlignTol = 0;
            movCond = [];
            misAlignPixUsed = 0;
            zeroTimePoint = nan;
            
            % Get the condition index for the moving bar
            key = fetch(self);
            c = fetch(fle.StimCond(key),'*');
            
            if ~any([c.dx]==dx)
                return
            end
            T = fetch1(vstim.RefreshPeriod(self),'refresh_period_msec');
            sc = fetch(fle.StimConstants(key), 'stim_center_x');
            flashCond = find([c.bar_color_r]==barLum & [c.is_flash] & [c.flash_location]== flashLocation,1);
            
            switch motionType
                case 'cont'
                    allMovCond = find([c.bar_color_r]==barLum & ~[c.is_flash] & [c.is_moving]...
                        & [c.dx]==dx & [c.direction]==direction & ~[c.is_init] & ~[c.is_stop]);
                case 'init'
                    % All the init conditions - there will be many of them
                    allMovCond = find([c.bar_color_r]==barLum & ~[c.is_flash] & [c.is_moving]...
                        & [c.dx]==dx & [c.direction]==direction & [c.is_init] & ~[c.is_stop]);
                case 'stop'
                    allMovCond = find([c.bar_color_r]==barLum & ~[c.is_flash] & [c.is_moving]...
                        & [c.dx]==dx & [c.direction]==direction & ~[c.is_init] & [c.is_stop]);
                otherwise
                    error('unknown motion type')
            end
            
            fd = fetch(fle.SubTrials(key,sprintf('cond_idx = %u',flashCond)),'flash_centers',1);
            % Choose the condition where motion started from or ended at the rf center
            % location
            nMovCond = length(allMovCond);
            for iMovCond = 1:nMovCond
                movCond = allMovCond(iMovCond);
                % Get one subTrial with this condition
                md = fetch(fle.SubTrials(key,sprintf('cond_idx = %u',movCond)),'bar_locations',1);
                movBarLoc = md.bar_locations{:};
                flashLoc = fd.flash_centers{:}(1) - sc.stim_center_x;
                switch motionType
                    case 'cont'
                        alignFrameInd = find(movBarLoc==flashLoc);
                    case 'init'
                        alignFrameInd = find(movBarLoc(1)==flashLoc);
                    case 'stop'
                        alignFrameInd = find(movBarLoc(end)==flashLoc);
                    otherwise
                        error('Unknown motion type !')
                end
                if ~isempty(alignFrameInd)
                    break
                end
            end
            
            if isempty(alignFrameInd)
                if strcmp(motionType,'cont') && misAlignTol > 0                    
                    % randomly choose a moving location closest to the flashed location
                    r = rand(1);
                    if r < 0.5
                        cand = movBarLoc(movBarLoc >= flashLoc & movBarLoc <= (flashLoc + misAlignTol));
                    else
                        cand = movBarLoc(movBarLoc <= flashLoc & movBarLoc >= (flashLoc - misAlignTol));
                    end
                    offsets = cand-flashLoc;
                    [~,ind] = min(abs(offsets));
                    misAlignPixUsed = offsets(ind);
                    c = cand(ind);
                    alignFrameInd = find(movBarLoc==c);
                    if isempty(alignFrameInd)
                        es = sprintf('The misAlignTol used did not find a close match between flash and moving bar\n');
                        disp(es);
                        return
                    end
                else
                    return
                end
            end
            zeroTimePoint = (alignFrameInd - 1) * T;
        end
        
        function arr = getStimCenProxArrForCond(self,condIdx1Array,barType)
            % function arr = getStimCenProxArrForCond(self,condIdx1Array,barType)
            %   getStimCenProxArrForCond(self,condIdx1Array,'moving')
            %   getStimCenProxArrForCond(self,condIdx1Array,'flash')
            % For a flash or moving bar condition, find the arrangement where the given stimulus was
            % close to the stim center
            
            assert(count(self)==1,'One session at a time!');
            
            key = fetch(self);
            condFull = fetch(stimulation.StimConditions(key),'*');
            cond = [condFull.condition_info];
            
            % Is it single or combined?
            cp = fetch(fle.StimConstants(key),'combined');
            
            if ~cp.combined
                arr = [cond(condIdx1Array).arrangement];
                return
            end
            
            nCond1 = length(condIdx1Array);
            arr = nan(1,nCond1);
            
            for iCond1 = 1:nCond1
                condIdx1 = condIdx1Array(iCond1);
                % Find the arrangement for the given condition and find the other arrangement and compare
                % both
                ct = cond(condIdx1);
                
                % Look for the other arrangement
                ct.arrangement = ~ct.arrangement;
                
                fn = fieldnames(ct);
                notFound = true;
                nCond = length(cond);
                nField = length(fn);
                cInd = 0;
                
                while notFound && cInd <= nCond
                    cInd = cInd + 1;
                    ma = false(1,nField);
                    for iField = 1:nField
                        currField = fn{iField};
                        val1 = ct.(currField);
                        val2 = cond(cInd).(currField);
                        if isnan(val1)
                            val1 = -1;
                        end
                        if isnan(val2)
                            val2 = -1;
                        end
                        ma(iField) = all(val1==val2);
                    end
                    if all(ma)
                        notFound = false;
                    end
                end
                if cInd == 0
                    error('The other arrangement was not found');
                end
                condIdx2 = condFull(cInd).condition_num;
                stimCenY = fetch1(fle.StimConstants(key),'stim_center_y');
                switch barType
                    case 'moving'
                        param = 'bar_centers';
                    case 'flash'
                        param = 'flash_centers';
                end
                bd = fetch(fle.SubTrials(key,sprintf('cond_idx=%u',condIdx2)),param,1);
                xy = bd.(param){:};
                y2 = xy(2,1);
                bd = fetch(fle.SubTrials(key,sprintf('cond_idx=%u',condIdx1)),param,1);
                xy = bd.(param){:};
                y1 = xy(2,1);
                [~,closer] = min(abs([y1 y2]-stimCenY));
                bothArr = [cond(condIdx1).arrangement cond(condIdx2).arrangement];
                arr(iCond1) = bothArr(closer);
            end
        end
        
        function [condIdx condStr] = getSelCond(self,varargin)
            args.direction = [0 1];
            args.dx = [];
            args.bar_gray_level = 255;
            args.is_init = false;
            args.is_stop = false;
            args.barTypes = {'flash','moving'};
            args.rfCond = true;
            
            args = parseVarArgs(args,varargin{:});
            
            key = fetch(self);
            qs = sprintf('is_init = %u and is_stop = %u and bar_color_r = %u',args.is_init,args.is_stop,args.bar_gray_level);
            cond = fetch(fle.StimCond(key,qs),'*');
            
            % Need to add flash conditions separately
            flashOnlyCond = [];
            if args.is_init || args.is_stop
                qs = sprintf('is_flash = 1 and bar_color_r = %u',args.bar_gray_level);
                flashOnlyCond = fetch(fle.StimCond(key,qs),'*');
            end
            cond = cat(1,cond,flashOnlyCond);
            
            if isempty(args.dx)
                dx = unique([cond.dx]);
                args.dx = dx(~isnan(dx));
            end
            
            if ischar(args.barTypes)
                args.barTypes = {args.barTypes};
            end
            stimTypes = {'flash','moving'};
            
            comb = fetch1(fle.StimConstants(key),'combined');
            if args.combinedStim && comb==0
                args.combinedStim = false;
                fprintf('The requested session is not a combined session; using single stim conditions instead!\n');
            end
            
            if  args.combinedStim == 0 % single stimulus in subtrial condition
                
                % Flashes
                allFlashOnlyCond = [cond.is_flash] & ~[cond.is_moving];
                rfInArr = fetch1(fle.StimCenProxCond(fetch(self),sprintf('cond_idx = %u',cond(find(allFlashOnlyCond,1)).cond_idx)),'arr_rf_in');
                rfInCond = [cond(allFlashOnlyCond & [cond.arrangement]==rfInArr).cond_idx];
                rfOutCond = [cond(allFlashOnlyCond & [cond.arrangement]~=rfInArr).cond_idx];
                flashCond = [rfInCond rfOutCond];
                flashCondStr = [ repmat({'flash-inRf-single'},1,length(rfInCond)),...
                    repmat({'flash-outRf-single'},1,length(rfOutCond))];
                
                % Moving bars
                allMovOnlyCond = ~[cond.is_flash] & [cond.is_moving] & ...
                    ismember([cond.dx],args.dx) & ismember([cond.direction],args.direction);
                rfInArr = fetch1(fle.StimCenProxCond(fetch(self),sprintf('cond_idx = %u',cond(find(allMovOnlyCond,1)).cond_idx)),'arr_rf_in');
                rfInCond0 = [cond(allMovOnlyCond & [cond.arrangement]==rfInArr & [cond.direction]==0).cond_idx];
                rfInCond1 = [cond(allMovOnlyCond & [cond.arrangement]==rfInArr & [cond.direction]==1).cond_idx];
                rfOutCond0 = [cond(allMovOnlyCond & [cond.arrangement]~=rfInArr & [cond.direction]==0).cond_idx];
                rfOutCond1 = [cond(allMovOnlyCond & [cond.arrangement]~=rfInArr & [cond.direction]==1).cond_idx];
                movCond = [rfInCond0 rfInCond1 rfOutCond0 rfOutCond1];
                movCondStr = [ repmat({'mov-inRf-single-LR'},1,length(rfInCond0)),repmat({'mov-inRf-single-RL'},1,length(rfInCond1))...
                    repmat({'mov-outRf-single-LR'},1,length(rfOutCond0)),repmat({'mov-outRf-single-RL'},1,length(rfOutCond1))];
                
                allCond = [flashCond movCond];
                allCondStr = [flashCondStr movCondStr];
            elseif args.combinedStim == 1
                % Flashes
                allFlashCond = [cond.is_flash] & [cond.is_moving] & ...
                    ismember([cond.dx],args.dx) & ismember([cond.direction],args.direction);
                rfInArr = fetch1(fle.StimCenProxCond(fetch(self),sprintf('cond_idx = %u',cond(find(allFlashCond,1)).cond_idx)),'arr_rf_in');
                rfInCond = [cond(allFlashCond & [cond.arrangement]==rfInArr).cond_idx];
                rfOutCond = [cond(allFlashCond & [cond.arrangement]~=rfInArr).cond_idx];
                flashCond = [rfInCond rfOutCond];
                flashCondStr = [ repmat({'flash-inRf-comb'},1,length(rfInCond)),...
                    repmat({'flash-outRf-comb'},1,length(rfOutCond))];
                
                % Moving bars
                
                allMovCond = [cond.is_flash] & [cond.is_moving] & ...
                    ismember([cond.dx],args.dx) & ismember([cond.direction],args.direction);
                rfInArr = fetch1(fle.StimCenProxCond(fetch(self),sprintf('cond_idx = %u',cond(find(allMovCond,1)).cond_idx)),'arr_rf_in');
                rfInCond = [cond(allMovCond & [cond.arrangement]==rfInArr).cond_idx];
                rfOutCond = [cond(mov_cond_idx(allMovCond & [cond.arrangement]~=rfInArr)).cond_idx];
                movCond = [rfInCond rfOutCond];
                movCondStr = [ repmat({'mov-inRf-comb'},1,length(rfInCond)),...
                    repmat({'mov-outRf-comb'},1,length(rfOutCond))];
                
                allCond = [flashCond movCond];
                allCondStr = [flashCondStr movCondStr];
            else
                error('Combining combined and single conditions not implemented yet!');
            end
            
            if args.rfCond == -1 % get conditions where stim was inside or outside rf
                
                if all(ismember(stimTypes,args.barTypes))
                    sel = 1:length(allCond);
                elseif any(ismember(args.barTypes,'flash'))
                    sel = ismember(allCondStr,{ 'flash-inRf-single','flash-outRf-single',...
                        'flash-inRf-comb','flash-outRf-comb'});
                elseif any(ismember(args.barTypes,'moving'))
                    sel = ismember(allCondStr,{ 'mov-inRf-single-LR','mov-inRf-single-RL','mov-outRf-single-LR',...
                        'mov-outRf-single-RL','mov-inRf-comb','mov-outRf-comb'});
                else
                    error('args.barTypes should be ''moving'' and/or ''flash''');
                end
                
            elseif args.rfCond == 1
                if all(ismember(stimTypes,args.barTypes))
                    sel = ismember(allCondStr,{'flash-inRf-single','mov-inRf-comb',...
                        'flash-inRf-comb','mov-inRf-single-LR','mov-inRf-single-RL'});
                elseif any(ismember(args.barTypes,'flash'))
                    sel = ismember(allCondStr,{'flash-inRf-single','flash-inRf-comb'});
                elseif any(ismember(args.barTypes,'moving'))
                    sel = ismember(allCondStr,{'mov-inRf-single-LR','mov-inRf-single-RL','mov-inRf-comb'});
                else
                    error('args.barTypes should be ''moving'' and/or ''flash''');
                end
            elseif args.rfCond == 0
                if all(ismember(stimTypes,args.barTypes))
                    sel = ismember(allCondStr,{'flash-outRf-single','mov-outRf-comb',...
                        'flash-outRf-comb','mov-outRf-single-LR','mov-outRf-single-RL'});
                elseif any(ismember(args.barTypes,'flash'))
                    sel = ismember(allCondStr,{'flash-outRf-single','flash-outRf-comb'});
                elseif any(ismember(args.barTypes,'moving'))
                    sel = ismember(allCondStr,{'mov-outRf-single-LR','mov-outRf-single-RL','mov-outRf-comb'});
                else
                    error('args.barTypes should be ''moving'' and/or ''flash''');
                end
            end
            condIdx = allCond(sel);
            condStr = allCondStr(sel);
            
            selMovCondIdx = condIdx(ismember(condIdx,find([cond.is_moving])));
            
            % Add speed and direction labels to condition strings
            nCond = length(selMovCondIdx);
            for iCond = 1:nCond
                idx = selMovCondIdx(iCond);
                speed = cond(idx).dx;
                condStr{condIdx==idx} = [condStr{condIdx==idx} sprintf('-dx=%u dir=%u',speed,...
                    cond(idx).direction)];
            end
        end
    end
end
