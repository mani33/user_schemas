%{
fle.UnitsFinal (manual) # For convenience, units selected for the phy fle paper
-> ephys.Spikes
-----
electrode_num : smallint unsigned # electrode number
hemisphere: enum('Left','Right') # bla
vis_area=0: boolean # was the electrode in v1 or v2
multi_speeds = 0: boolean # was there more than one speed
multi_lum = 0: boolean # was there more than one bar luminance
combined = 0: boolean # flash and motion presented together
init = 0: boolean # flash-initiated condition?
stop = 0: boolean # flash-stopped condition?
reverse = 0: boolean # flash-reversed condition?
lcd=0                       : boolean                       # monitor type lcd or crt
subj_initials : varchar(4) # abbreviation for subjects

%}

classdef UnitsFinal < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.UnitsFinal')
    end
    methods
        function self = UnitsFinal(varargin)
            self.restrict(varargin)
        end
    end
end
