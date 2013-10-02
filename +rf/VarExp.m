%{
rf.VarExp (computed) # my newest table
-> rf.FitAvg

-----
ve: double # fraction of variance explained 
%}

classdef VarExp < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('rf.VarExp')
		popRel = rf.FitAvg  % !!! update the populate relation
	end
    methods
        function self = VarExp(varargin)
            self.restrict(varargin)
        end
    end
	methods(Access=protected)

		function makeTuples(self, key)
		%!!! compute missing fields for key here
            res = fetch1(rf.FitAvg(key),'residuals');
            map = fetch1(rf.MapAvg(key),'map');
            % apply smoothing
            n = 5;
            w = window(@gausswin,n);
            w = w * w';
            w = w / sum(w(:));
            smap = imfilter(map,w,'circular');
            SSR = sum(res.^2);
            mp  = smap(:);
            mu = mean(mp);
            SST = sum((mp-mu).^2);
            if SST <= 0
                key.ve = 0;
            else
                key.ve = 1-SSR/SST;
            end
            self.insert(key)
		end
	end
end
