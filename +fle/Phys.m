% fle.Phys - my newest table
% I will explain what my table does here 

%{
fle.Phys (computed) # my newest table
-> ephys.Spikes
-> fle.TrialGroup
-----
%}

classdef Phys < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.Phys')
    end
	methods
		function self = Phys(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)
            tuples = fetch(ephys.Spikes(key) * fle.TrialGroup(key));            
            self.insert(tuples);            
		end
	end
end
