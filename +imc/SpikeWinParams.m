%{
imc.SpikeWinParams (lookup) # my newest table
pre_stim_time = 300   : double          # Time to bin before alignment event
post_stim_time = 500  : double          # Time after bin before alignment event
-----

%}

classdef SpikeWinParams < dj.Relvar
    properties(Constant)
		table = dj.Table('imc.SpikeWinParams')
	end

	methods
		function self = SpikeWinParams(varargin)
			self.restrict(varargin)
		end
	end
end