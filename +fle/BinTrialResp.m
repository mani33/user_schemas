%{
fle.BinTrialResp (computed) # my newest table
-> fle.BinTimesByCond
-> fle.Phys
-> fle.SubTrials
-----

spike_counts = NULL : blob # spike counts
%}

classdef BinTrialResp < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('fle.BinTrialResp')
		popRel = fle.SubTrials * fle.BinTimesByCond * fle.Phys  % !!! update the populate relation
    end

    methods 
        function self = BinTrialResp(varargin)
            self.restrict(varargin{:})
        end
    end
    
	methods(Access=protected)

		function makeTuples(self, key)
            spk = fetch1(fle.SubTrialSpikes(key),'spike_times');
            [bc, bw] = fetch1(fle.BinTimesByCond(key),'t','bw_t');
            % Make bin edges so that the bin times correspond to bin centers
            bin_edges = cat(1,bc-bw/2, bc(end)+bw/2);
            sc = histc(spk,bin_edges);
            sc = sc(1:end-1);
            key.spike_counts = sc(:); 
			self.insert(key)
		end
	end
end
