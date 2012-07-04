% flevbl.Stats - my newest table
% I will explain what my table does here

%{
flevbl.Stats (computed) # my newest table
-> flevbl.SpikeSets
-> flevbl.StatsParams
-----
is_excitatory = 0: boolean # is the unit excitatory
is_inhibitory = 0: boolean # is the unit inhibitory
is_responsive = 0: boolean # responsive?
stats_ts=CURRENT_TIMESTAMP: timestamp # do not edit
%}

classdef Stats < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.Stats')
    end
    properties
        popRel = flevbl.SpikeSets * flevbl.StatsParams  % !!! update the populate relation
    end
    
    methods
        function self = Stats(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            
            % Is the neuron/multiunit responsive?
            cond = fetch(flevbl.StimCond(key),'*');
            flashCond = find([cond.is_flash] & ~[cond.is_moving]);
            nCond = length(flashCond);
            pval = nan(1,nCond);
            frBase = cell(1,nCond);
            frEvoke = frBase;
            for iCond = 1:nCond
                stRel = flevbl.SubTrials(key,...
                    sprintf('cond_idx = %u',flashCond(iCond)));
                stsRel = flevbl.SubTrialSpikes(key,stRel);
                spikes = fetchn(stsRel,'spike_times');
                scBase = cellfun(@(x) length(x(x >= -key.base_time & x < 0)),spikes);
                scEvoke = cellfun(@(x) length(x(x >= key.resp_win_start & x < key.resp_win_end)),spikes);
                frBase{iCond} = 1000 * scBase/key.base_time; % Hz
                frEvoke{iCond} = 1000 * scEvoke/(key.resp_win_end - key.resp_win_start); % Hz
                pval(iCond) = ranksum(frBase{iCond},frEvoke{iCond});
            end
            
            meanBaseFr = cellfun(@(x) mean(x),frBase);
            meanEvokFr = cellfun(@(x) mean(x),frEvoke);
            frChange = meanEvokFr - meanBaseFr;
            
            if ~any(meanEvokFr > key.firing_rate_th) || ~any(frChange > key.firing_rate_change_th)
                key.is_responsive = false;
            else
                % Do Bonferroni correction
                key.is_responsive = any(pval < key.alpha/nCond);
            end
            % Receptive field flash location
            [~,rfInd] = max(abs(frChange));
            
            % Is the neuron excitatory or inhibitory
            if key.is_responsive
                % Select the condition having maximum difference between basal and evoked firing rate
                key.is_excitatory = frChange(rfInd) > 0;
                key.is_inhibitory = ~key.is_excitatory;
            else
                % The default values are set in the table definition
            end
            self.insert(key)
        end
    end
end
