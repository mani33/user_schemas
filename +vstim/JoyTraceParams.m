%{
vstim.JoyTraceParams (lookup) # joystick trace parameters
pre_stim_time = 500: int # pre-stimulus time in msec
post_stim_time = 3000: int # post stimulus time in msec
decimation_fac = 10: double # downsampling factor

-----

%}

classdef JoyTraceParams < dj.Relvar

	properties(Constant)
		table = dj.Table('vstim.JoyTraceParams')
	end

	methods
		function self = JoyTraceParams(varargin)
			self.restrict(varargin)
		end
	end
end
