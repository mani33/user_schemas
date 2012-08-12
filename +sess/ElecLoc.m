% sess.ElecLoc - which areas the electrodes were in?
%{
sess.ElecLoc (manual) # my newest table
subject_id               : int unsigned # unique identifier for subject
setup                    : tinyint unsigned  # setup number
session_start_time       : bigint            # start session timestamp
ephys_start_time         : bigint # ephys start timestamp
electrode_num            : smallint unsigned # electrode number

---
vis_area_num = 0: tinyint unsigned # was the electrode in v1,v2,v3 or v4?
hemisphere: enum("left","right") # which side of the brain the electrodes were in
session_datetime = NULL  : datetime          # readable format of session start

%}


classdef ElecLoc < dj.Relvar

	properties(Constant)
		table = dj.Table('sess.ElecLoc')
	end

	methods
		function self = ElecLoc(varargin)
			self.restrict(varargin)
		end
	end
end
