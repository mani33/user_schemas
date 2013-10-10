% fle.SpikeWinParams - my newest table
% I will explain what my table does here 

%{
fle.SpikeWinParams (lookup) # my newest table
pre_stim_time = 500   : double          # Time to bin before alignment event
post_stim_time = 500  : double          # Time after bin before alignment event
-----


%}

classdef SpikeWinParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.SpikeWinParams')
	end

	methods
		function self = SpikeWinParams(varargin)
			self.restrict(varargin)
		end
	end
end
