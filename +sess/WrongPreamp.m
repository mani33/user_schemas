%{
sess.WrongPreamp (manual) # Sessions where the pre-amplifiers were plugged wrong
-> acq.Sessions

-----

%}

classdef WrongPreamp < dj.Relvar

	properties(Constant)
		table = dj.Table('sess.WrongPreamp')
    end
    
     methods
        function self = WrongPreamp(varargin)
            self.restrict(varargin)
        end
    end
end
