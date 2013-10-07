%{
flevbl.BinTimesByCond (computed) # my newest table
-> flevbl.MovBw
-> flevbl.StimCond
-----
bin_cen_t: double # bin center times in ms relative to stimulus onset
bin_edge_t: double # bin edge times in ms relative to stimulus onset
bin_width: double # actual bin width used
%}

classdef BinTimesByCond < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('flevbl.BinTimesByCond')
		popRel = (flevbl.StimCond * flevbl.MovBw) & flevbl.SubTrialSpikes & vstim.RefreshPeriod & vstim.PixPerDeg % !!! update the populate relation
	end

	methods(Access=protected)

		function makeTuples(self, key)
            
            
            
            
            
		%!!! compute missing fields for key here
			self.insert(key)
		end
	end
end
