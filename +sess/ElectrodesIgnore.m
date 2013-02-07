%{
sess.ElectrodesIgnore (manual) # my newest table
-> acq.Sessions
electrode_num : smallint unsigned # electrode number to ignore
-----
electrodesignore_ts=CURRENT_TIMESTAMP: timestamp   # importing time stamp
%}

classdef ElectrodesIgnore < dj.Relvar

	properties(Constant)
		table = dj.Table('sess.ElectrodesIgnore')
	end

	methods
		function self = ElectrodesIgnore(varargin)
			self.restrict(varargin)
		end
	end
end
