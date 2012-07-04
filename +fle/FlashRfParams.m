% fle.FlashRfParams - my newest table
% I will explain what my table does here 

%{
fle.FlashRfParams (lookup) # my newest table
base_time = 150: double # msec before stimulus onset for baseline firing computation
min_lag = 0: double # msec after stimulus onset for receptive field computation - starting
max_lag = 150: double # msec after stimulus onset for receptive field computation - ending
resp_win_start = 50: double # win start time for stimulus response
resp_win_end = 120: double # end time for stimulus response
-----

%}

classdef FlashRfParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.FlashRfParams')
	end

	methods
		function self = FlashRfParams(varargin)
			self.restrict(varargin)
		end
	end
end
