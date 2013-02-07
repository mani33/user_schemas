%{
archives.Raid (manual) # my newest table
setup : tinyint unsigned # setup from where data were collected
array_num: smallint unsigned # RAID array name
subject_id: smallint unsigned # subject's id
folder: varchar(50) # session parent folder
%}

classdef Raid < dj.Relvar

	properties(Constant)
		table = dj.Table('archives.Raid')
	end

	methods
		function self = Raid(varargin)
			self.restrict(varargin)
		end
	end
end
