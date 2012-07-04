% flevbl.Phys - my newest table
% I will explain what my table does here 

%{
flevbl.Phys (computed) # my newest table
-> ephys.Spikes
-> flevbl.TrialGroup
-----
%}

classdef Phys < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.Phys')
    end
	methods
		function self = Phys(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)
            tuples = fetch(ephys.Spikes(key) * flevbl.TrialGroup(key));            
            self.insert(tuples);            
		end
	end
end
