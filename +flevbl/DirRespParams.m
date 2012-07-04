% flevbl.DirRespParams - my newest table
% I will explain what my table does here 

%{
flevbl.DirRespParams (lookup) # my newest table

pre_rf_entry_time = 50: smallint unsigned # msec before the time of entering the rf
post_rf_entry_time = 100: smallint unsigned # msec after entering the receptive field
-----

%}

classdef DirRespParams < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.DirRespParams')
	end

	methods
		function self = DirRespParams(varargin)
			self.restrict(varargin)
		end
	end
end
