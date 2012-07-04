% flevbl.SpikeBinParams - parameter list for binnings spikes. Can be used for normal trials
% and subtrials.

%{
flevbl.SpikeBinParams (lookup) # my newest table
bin_width = 1  : double                # Bin width in msec
pre_stim_time = 300   : double          # Time to bin before alignment event
post_stim_time = 300  : double         # Time after bin before alignment event
-----

%}

classdef SpikeBinParams < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.SpikeBinParams')
	end

	methods
		function self = SpikeBinParams(varargin)
			self.restrict(varargin)
		end
	end
end
