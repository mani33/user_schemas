%{
fle.ForPaper (manual) # my newest table
-> ephys.Spikes

-----
v1=0: boolean # was the electrode in v1
v2=0: boolean # was the electrode in v2
multi_speeds = 0: boolean # was there more than one speed
multi_lum = 0: boolean # was there more than one bar luminance
single = 0: boolean # flash or moving bar at receptive field
combined = 0: boolean # flash and motion presented together
init = 0: boolean # flash-initiated condition?
stop = 0: boolean # flash-stopped condition?
reverse = 0: boolean # flash-reversed condition?
subj_initials : varchar(4) # abbreviation for subjects

%}

classdef ForPaper < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.ForPaper')
    end
     methods
        function self = ForPaper(varargin)
            self.restrict(varargin)
        end
    end
end
