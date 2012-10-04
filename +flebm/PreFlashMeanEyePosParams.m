%{
flebm.PreFlashMeanEyePosParams (lookup) # my newest table
pre_flash_time=100: smallint unsigned # ms before flash onset for analysis
-----

%}

classdef PreFlashMeanEyePosParams < dj.Relvar

	properties(Constant)
		table = dj.Table('flebm.PreFlashMeanEyePosParams')
	end

	methods
		function self = PreFlashMeanEyePosParams(varargin)
			self.restrict(varargin)
		end
	end
end
