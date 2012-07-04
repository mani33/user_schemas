% fle.BarRfParams - my newest table
% I will explain what my table does here 

%{
fle.BarRfParams (lookup) # my newest table
base_time = 150: double # msec before stimulus onset for baseline firing computation
min_lag = 0: double # msec after stimulus onset for receptive field computation - starting
max_lag = 150: double # msec after stimulus onset for receptive field computation - ending

-----

%}

classdef BarRfParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.BarRfParams')
	end

	methods
		function self = BarRfParams(varargin)
			self.restrict(varargin)
		end
	end
end
