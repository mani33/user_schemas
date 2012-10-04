%{
vstim.EyeTraceParams (lookup) # my newest table
pre_stim_time = 500: int # pre-stimulus time in msec
post_stim_time = 3000: int # post stimulus time in msec
decimation_fac = 2: double # downsampling factor
-----

%}

classdef EyeTraceParams < dj.Relvar

	properties(Constant)
		table = dj.Table('vstim.EyeTraceParams')
	end

	methods
		function self = EyeTraceParams(varargin)
			self.restrict(varargin)
		end
	end
end
