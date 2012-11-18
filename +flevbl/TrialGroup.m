% flevbl.TrialGroup - Subset of FlePhysEffExperiment sessions

%{
flevbl.TrialGroup (computed) # my newest table
-> stimulation.StimTrialGroup
-----

%}

classdef TrialGroup < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.TrialGroup')
        popRel = (stimulation.StimTrialGroup - acq.StimulationIgnore) & ephys.Spikes &...
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
%             makeTuples(flevbl.Phys,key)
            makeTuples(flevbl.StimCond,key)
            makeTuples(flevbl.StimConstants,key)
            makeTuples(flevbl.DxVals,key)
            makeTuples(flevbl.BarGrayLevels,key)
            makeTuples(flevbl.SubTrials,key)
            
        end
    end
    methods
        function [zeroTimePoint misAlignPixUsed movCond] = getTrajRelTimeAtFlashLoc(self,flashLocation,...
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
            c = fetch(flevbl.StimCond(key),'*');
            
            if ~any([c.dx]==dx)
                return
            end
            T = fetch1(vstim.RefreshPeriod(self),'refresh_period_msec');
            sc = fetch(flevbl.StimConstants(key), 'stim_center_x');
            flashCond = find([c.bar_color_r]==barLum & [c.flash_location]== flashLocation,1);
            
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
            
            fd = fetch(flevbl.SubTrials(key,sprintf('cond_idx = %u',flashCond)),'flash_centers',1);
            % Choose the condition where motion started from or ended at the rf center
            % location
            nMovCond = length(allMovCond);
            for iMovCond = 1:nMovCond
                movCond = allMovCond(iMovCond);
                % Get one subTrial with this condition
                md = fetch(flevbl.SubTrials(key,sprintf('cond_idx = %u',movCond)),'bar_locations',1);
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
            cp = fetch(flevbl.StimConstants(key),'combined');
            
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
                stimCenY = fetch1(flevbl.StimConstants(key),'stim_center_y');
                switch barType
                    case 'moving'
                        param = 'bar_centers';
                    case 'flash'
                        param = 'flash_centers';
                end
                bd = fetch(flevbl.SubTrials(key,sprintf('cond_idx=%u',condIdx2)),param,1);
                xy = bd.(param){:};
                y2 = xy(2,1);
                bd = fetch(flevbl.SubTrials(key,sprintf('cond_idx=%u',condIdx1)),param,1);
                xy = bd.(param){:};
                y1 = xy(2,1);
                [~,closer] = min(abs([y1 y2]-stimCenY));
                bothArr = [cond(condIdx1).arrangement cond(condIdx2).arrangement];
                arr(iCond1) = bothArr(closer);
            end
        end
        
        function [condIdx condStr] = getSelCond(self,varargin)
            arg.direction = [0 1];
            arg.dx = [];
            arg.arg.barTypes = {'flash','moving'};
            arg.rfCond = true;
            
            arg = parseVarArgs(arg,varargin{:});
            
            key = fetch(self);
            cond = fetch(flevbl.StimCond(key),'*');
            
            if isempty(arg.dx)
                dx = unique([cond.dx]);
                arg.dx = dx(~isnan(dx));
            end
            
            if ischar(arg.arg.barTypes)
                arg.arg.barTypes = {arg.arg.barTypes};
            end
            stimTypes = {'flash','moving'};
            
            comb = fetch1(flevbl.StimConstants(key),'combined');
            if arg.combinedStim && comb==0
                arg.combinedStim = false;
                fprintf('The requested session is not a combined session; using single stim conditions instead!\n');
            end
            
            
            if  arg.combinedStim == 0 % single stimulus in subtrial condition
                
                % Flashes
                allFlashOnlyCond = [cond.is_flash] & ~[cond.is_moving];
                rfInArr = getStimCenProxArrForCond(self,find(allFlashOnlyCond,1),'flash');
                rfInCond = find(allFlashOnlyCond & [cond.arrangement]==rfInArr);
                rfOutCond = find(allFlashOnlyCond & [cond.arrangement]~=rfInArr);
                flashCond = [rfInCond rfOutCond];
                flashCondStr = [ repmat({'flash-inRf-single'},1,length(rfInCond)),...
                    repmat({'flash-outRf-single'},1,length(rfOutCond))];
                
                % Moving bars
                allMovOnlyCond = ~[cond.is_flash] & [cond.is_moving] & ...
                    ismember([cond.dx],arg.dx) & ismember([cond.direction],arg.direction);
                rfInArr = getStimCenProxArrForCond(self,find(allMovOnlyCond,1),'moving');
                rfInCond = find(allMovOnlyCond & [cond.arrangement]==rfInArr);
                rfOutCond = find(allMovOnlyCond & [cond.arrangement]~=rfInArr);
                movCond = [rfInCond rfOutCond];
                movCondStr = [ repmat({'mov-inRf-single'},1,length(rfInCond)),...
                    repmat({'mov-outRf-single'},1,length(rfOutCond))];
                
                allCond = [flashCond movCond];
                allCondStr = [flashCondStr movCondStr];
            elseif arg.combinedStim == 1
                % Flashes
                allFlashCond = [cond.is_flash] & [cond.is_moving] & ...
                    ismember([cond.dx],arg.dx) & ismember([cond.direction],arg.direction);
                rfInArr = getStimCenProxArrForCond(self,find(allFlashCond,1),'flash');
                rfInCond = find(allFlashCond & [cond.arrangement]==rfInArr);
                rfOutCond = find(allFlashCond & [cond.arrangement]~=rfInArr);
                flashCond = [rfInCond rfOutCond];
                flashCondStr = [ repmat({'flash-inRf-comb'},1,length(rfInCond)),...
                    repmat({'flash-outRf-comb'},1,length(rfOutCond))];
                
                % Moving bars
                
                allMovCond = [cond.is_flash] & [cond.is_moving] & ...
                    ismember([cond.dx],arg.dx) & ismember([cond.direction],arg.direction);
                rfInArr = getStimCenProxArrForCond(self,find(allMovCond,1),'moving');
                rfInCond = find(allMovCond & [cond.arrangement]==rfInArr);
                rfOutCond = find(allMovCond & [cond.arrangement]~=rfInArr);
                movCond = [rfInCond rfOutCond];
                movCondStr = [ repmat({'mov-inRf-comb'},1,length(rfInCond)),...
                    repmat({'mov-outRf-comb'},1,length(rfOutCond))];
                
                allCond = [flashCond movCond];
                allCondStr = [flashCondStr movCondStr];
            else
                error('Combining combined and single conditions not implemented yet!');
            end
            
            if arg.rfCond == -1 % get conditions where stim was inside or outside rf
                
                if all(ismember(stimTypes,arg.barTypes))
                    sel = 1:length(allCond);
                elseif any(ismember(arg.barTypes,'flash'))
                    sel = ismember(allCondStr,{ 'flash-inRf-single','flash-outRf-single',...
                        'flash-inRf-comb','flash-outRf-comb'});
                elseif any(ismember(arg.barTypes,'moving'))
                    sel = ismember(allCondStr,{ 'mov-inRf-single','mov-outRf-single',...
                        'mov-inRf-comb','mov-outRf-comb'});
                else
                    error('arg.barTypes should be ''moving'' and/or ''flash''');
                end
                
            elseif arg.rfCond == 1
                if all(ismember(stimTypes,arg.barTypes))
                    sel = ismember(allCondStr,{'flash-inRf-single','mov-inRf-comb',...
                        'flash-inRf-comb','mov-inRf-single'});
                elseif any(ismember(arg.barTypes,'flash'))
                    sel = ismember(allCondStr,{'flash-inRf-single','flash-inRf-comb'});
                elseif any(ismember(arg.barTypes,'moving'))
                    sel = ismember(allCondStr,{'mov-inRf-single','mov-inRf-comb'});
                else
                    error('arg.barTypes should be ''moving'' and/or ''flash''');
                end
            elseif arg.rfCond == 0
                if all(ismember(stimTypes,arg.barTypes))
                    sel = ismember(allCondStr,{'flash-outRf-single','mov-outRf-comb',...
                        'flash-outRf-comb','mov-outRf-single'});
                elseif any(ismember(arg.barTypes,'flash'))
                    sel = ismember(allCondStr,{'flash-outRf-single','flash-outRf-comb'});
                elseif any(ismember(arg.barTypes,'moving'))
                    sel = ismember(allCondStr,{'mov-outRf-single','mov-outRf-comb'});
                else
                    error('arg.barTypes should be ''moving'' and/or ''flash''');
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
