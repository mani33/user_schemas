% flevbl.FlashResp - my newest table
% I will explain what my table does here 

%{
flevbl.FlashRespStat (computed) # my newest table
-> flevbl.SpikeSets
-> flevbl.FlashRespStatParams
cond_idx : smallint unsigned # condition index of the flashes
-----
mean_fr_base = Null: double # baseline mean firing rate
mean_fr_evoked = Null: double # stimulus evoked mean firing rate 
is_responsive = 0: boolean # is the neuron/multiunit responsive to a given flash
%}

classdef FlashRespStat < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('flevbl.FlashRespStat')
	end
	properties
		popRel = flevbl.SpikeSets * flevbl.FlashRespStatParams  % !!! update the populate relation
	end

	methods
		function self = FlashRespStat(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)

        % Get mean firing rates for flashes without any other stimulus present in the
        % same subtrial
        cond = fetch(flevbl.StimCond & key,'*');
        tc = find([cond.is_flash] & ~[cond.is_moving],1);
        rfArr = getStimCenProxArrForCond(flevbl.TrialGroup(key),tc,'flash');
        flashInd = find([cond.is_flash] & ~[cond.is_moving] & [cond.arrangement]==rfArr);
        
        nFlashes = length(flashInd);
        bwin = [-key.base_time 0];
        ewin = [key.resp_win_start key.resp_win_end];
        
        for iFlash = 1:nFlashes
            currCondIdx = flashInd(iFlash);
            key.cond_idx = currCondIdx;
            cs = sprintf('cond_idx=%u',currCondIdx);
            
            spikes = fetchn(flevbl.SubTrialSpikes(key) & flevbl.SubTrials(cs),'spike_times');
            baseFr = cellfun(@(x) 1000*length(x(x >= bwin(1) & x < bwin(2)))/diff(bwin),spikes);
            evokedFr = cellfun(@(x) 1000*length(x(x >= ewin(1) & x < ewin(2)))/diff(ewin),spikes);
            [~,key.is_responsive] = ranksum(baseFr,evokedFr,'alpha',key.alpha);
            key.mean_fr_base = mean(baseFr);
            key.mean_fr_evoked = mean(evokedFr);
            
            self.insert(key)
        end
        end
	end
end
