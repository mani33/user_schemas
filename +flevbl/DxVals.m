% flevbl.DxVals - my newest table
% I will explain what my table does here 

%{
flevbl.DxVals (computed) # my newest table
-> flevbl.TrialGroup
dx  : smallint unsigned # change in pixels per frame
-----

%}

classdef DxVals < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.DxVals')
	end

	methods
		function self = DxVals(varargin)
			self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            c = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            dx = unique(c.dx);
            for i = 1:length(dx)
                key.dx = dx(i);
                save('dkey','key')
                self.insert(key);
            end
        end
    end
end
