% flevbl.BarGrayLevels - my newest table
% I will explain what my table does here 

%{
flevbl.BarGrayLevels (computed) # my newest table
-> flevbl.TrialGroup
bar_gray_level  : tinyint unsigned # bar gray level
-----

%}

classdef BarGrayLevels < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.BarGrayLevels')
	end

	methods
		function self = BarGrayLevels(varargin)
			self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            c = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            for j = 1:size(c.barColor,2)
                assert(length(unique(c.barColor(:,j)))==1,'Non-gray colors are not supported')
                key.bar_gray_level = c.barColor(1,j);
                self.insert(key);
            end
        end
    end
end
