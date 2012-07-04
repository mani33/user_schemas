% fle.ElecLoc - which areas the electrodes were in?
%{
fle.ElecLoc (manual) # my newest table
subject_id   : int unsigned # unique identifier for subject
setup                    : tinyint unsigned  # setup number
session_start_time       : bigint            # start session timestamp
ephys_start_time: bigint # ephys start timestamp
electrode_num: smallint unsigned # electrode number

---
v1 = 0: boolean # was the electrode in v1?
v2 = 0: boolean # was the electrode in v2?
v3 = 0: boolean # was the electrode in v3?
v4 = 0: boolean # was the electrode in v4?
hemisphere: enum("left","right") # which side of the brain the electrodes were in
session_datetime = NULL  : datetime          # readable format of session start

%}


classdef ElecLoc < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.ElecLoc')
	end

	methods
		function self = ElecLoc(varargin)
			self.restrict(varargin)
		end
	end
end
