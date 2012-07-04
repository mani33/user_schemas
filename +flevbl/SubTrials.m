% flevbl.SubTrials - SubTrial level information for FlePhysEffExperiment
%

%{
flevbl.SubTrials (computed) # my newest table
-> flevbl.TrialGroup

subtrial_num     : int unsigned          # subTrial number
-----
trial_num        : int unsigned          # trial number
cond_idx         : smallint unsigned     # condition index of the subTrial
substim_on       : bigint unsigned       # showSubStimulus time
substim_off      : bigint unsigned       # endSubStimulus time
bar_locations    : blob                  # moving bar locations
bar_rects        : blob                  # moving bar rect coordinates
bar_centers      : blob                  # moving bar centers
flash_locations  : blob                  # flashed bar locations
flash_centers 	 : blob                  # flashed bar centers
%}

classdef SubTrials < dj.Relvar
    
    properties(Constant)
        table = dj.Table('flevbl.SubTrials')
    end
    
    methods
        function self = SubTrials(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            
            fprintf('Computing tuples')
            tic
            %!!! compute missing fields for key here
            [trialNum trialParams validTrial] = fetchn(stimulation.StimTrials(key),'trial_num','trial_params','valid_trial');
            vInd = find(validTrial);
            nVtrials = numel(vInd);
            trialParams = [trialParams{vInd}];
            tc = {trialParams.conditions};
            
            trialNum = trialNum(vInd);
            trialNum = cellfun(@(tn,c) repmat(tn,1,length(c)),num2cell(trialNum'),...
                tc,'UniformOutput',false);
            trialNum = [trialNum{:}];
            
            barLocations = [trialParams.barLocations];
            barCenters = [trialParams.barCenters];
            barRects = [trialParams.barRects];
            
            flashLocations = [trialParams.flashLocations];
            flashCenters = [trialParams.flashCenters];
            conditions = [trialParams.conditions];
            
            onsets = cell(1,nVtrials);
            offsets = onsets;
            
            for iTrial = 1:nVtrials
                % Get substimulus onsets and offsets
                tInd = vInd(iTrial);
                tn = sprintf('trial_num = %0.0f',tInd);
                if any(strcmp(fetchn(stimulation.StimTrialEvents(key,tn),'event_type'),'showSubStimulus'))
                    on = fetchn(stimulation.StimTrialEvents(key,tn,'event_type = ''showSubStimulus'''),'event_time');
                    off = fetchn(stimulation.StimTrialEvents(key,tn,'event_type = ''endSubStimulus'''),'event_time');
                else
                    on = fetchn(stimulation.StimTrialEvents(key,tn,'event_type = ''showStimulus'''),'event_time');
                    off = fetchn(stimulation.StimTrialEvents(key,tn,'event_type = ''endStimulus'''),'event_time');
                end
                % Order the onsets and offsets in increasing time to match with condition indices order
                onsets{iTrial} = sort(on)';
                offsets{iTrial} = sort(off)';
            end
            onsets = [onsets{:}];
            offsets = [offsets{:}];
            
            nSub = length(trialNum);
            % Create subTrials data structure
            tuples = repmat(key,1,nSub);
            for iSub = 1:nSub
                tuples(iSub).trial_num = trialNum(iSub);
                tuples(iSub).subtrial_num = iSub;
                tuples(iSub).cond_idx = conditions(iSub);
                tuples(iSub).substim_on = onsets(iSub);
                tuples(iSub).substim_off = offsets(iSub);
                tuples(iSub).bar_locations = barLocations(iSub);
                tuples(iSub).bar_centers = barCenters(iSub);
                tuples(iSub).bar_rects = barRects(iSub);
                tuples(iSub).flash_locations = flashLocations(iSub);
                tuples(iSub).flash_centers = flashCenters(iSub);                
            end
            fprintf(' (%0.0f s) -->',toc);
            tic
            fprintf(' Inserting')
            self.insert(tuples);
            fprintf(' (%0.0f sec) --> Done\n\n',toc);
        end
        
        
        function varargout = getParamsBySubTrials(self,subTrialNums,varargin)
            
            paramNames = varargin;
            nParams = length(paramNames);
            
            subTrials = subTrialNums(:);
            nTrials = length(subTrials);
            varargout = cell(1,nParams);
            
            for iParam = 1:nParams
                vals = cell(1,nTrials);
                for iSub = 1:nTrials
                    qs = sprintf('subtrial_num = %u',subTrials(iSub));
                    vals{iSub} = fetchn((self & qs),paramNames{iParam});
                end
                if iscell(vals{1})
                    vals = [vals{:}];
                end
                varargout{iParam} = reshape(vals,size(subTrialNums));
            end
        end
        
        function subTrialNums = getSubTrialsByConditions(self,conditions)
            
            cond = conditions(:);
            nCond = length(cond);
            subTrialNums = cell(1,nCond);
            for iCond = 1:nCond
                qs = sprintf('cond_idx = %u',cond(iCond));
                subTrialNums{iCond} = reshape(fetchn((self & qs),'subtrial_num'),[],1);
            end
            subTrialNums = reshape(subTrialNums,size(conditions));
        end
        
        function varargout = getParamsByConditions(self,conditions,varargin)
            %       function vals = getParamsByConditions(self,conditions,varargin)
            
            params = varargin;
            nParams = numel(params);
            cond = conditions(:);
            nCond = length(cond);
            varargout = cell(1,nParams);
            % Find param values for each param under each condition
            for iParam = 1:nParams
                vals = cell(1,nCond);
                for iCond = 1:nCond
                    qs = sprintf('cond_idx = %u',cond(iCond));
                    vals{iCond} = fetchn((self & qs),params{iParam});
                end
                varargout{iParam} = reshape(vals,size(conditions));
            end
        end
    end
end
