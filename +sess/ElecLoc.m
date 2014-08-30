%{
sess.ElecLoc (manual) # which visual area the electrodes were in?$
-> acq.Ephys
electrode_num   : smallint unsigned      # electrode number
---
vis_area_num=0              : tinyint unsigned              # was the electrode in v1,v2,v3 or v4?
hemisphere                  : enum('left','right')          # which side of the brain the electrodes were in
session_datetime=null       : datetime                      # readable format of session start
elecloc_ts=CURRENT_TIMESTAMP: timestamp                     # automatic timestamp. Do not edit
depth=-1                    : double                        # depth of the electrode in the brain(-1 means unknown depth)
%}

classdef ElecLoc < dj.Relvar

	properties(Constant)
		table = dj.Table('sess.ElecLoc')
	end

	methods
		function self = ElecLoc(varargin)
			self.restrict(varargin{:})
		end
	end
end

