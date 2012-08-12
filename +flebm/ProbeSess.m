%{
flebm.ProbeSess (manual) # my newest table
-> flebm.TrialGroup

-----
probe_sess_ts = CURRENT_TIMESTAMP: timestamp # time the tuples were inserted
%}

classdef ProbeSess < dj.Relvar

	properties(Constant)
		table = dj.Table('flebm.ProbeSess')
	end

	methods
		function self = ProbeSess(varargin)
			self.restrict(varargin)
		end
	end
end
