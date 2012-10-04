%{
vstim.TrialsIgnore (manual) # my newest table
-> stimulation.StimTrials

-----

%}
% We put trials that are not fit for analysis
% MS 2012-08-29
%
classdef TrialsIgnore < dj.Relvar

	properties(Constant)
		table = dj.Table('vstim.TrialsIgnore')
	end

	methods
		function self = TrialsIgnore(varargin)
			self.restrict(varargin)
		end
	end
end
