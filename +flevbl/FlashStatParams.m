%{
flevbl.FlashStatParams (lookup) # params for flash response statistics

base_win_start = -150: double # starting time for baseline window
resp_win_start = 40: double # response window starting
resp_win_end = 120: double # blah
-----



flashstatparams_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef FlashStatParams < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.FlashStatParams')
	end

	methods
		function self = FlashStatParams(varargin)
			self.restrict(varargin{:})
		end
	end
end
