%{
rf.Phys (computed) # my newest table
-> rf.TrialGroup
-> ephys.Spikes
-----

%}

classdef Phys < dj.Relvar

	properties(Constant)
		table = dj.Table('rf.Phys')
	end

	methods
		function self = Phys(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)
		 tuples = fetch(ephys.Spikes(key) * rf.TrialGroup(key));            
            self.insert(tuples);     
		end
	end
end
