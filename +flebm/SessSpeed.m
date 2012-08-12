%{
flebm.SessSpeed (computed) # my newest table
-> flebm.TrialGroup

-----
sess_speed=null : double # in pix/s
%}

classdef SessSpeed < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flebm.SessSpeed')
        popRel = flebm.TrialGroup  % !!! update the populate relation
    end
    
    methods
        function self = SessSpeed(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            % Get the speed used in all the trials. If they are all the same, then we set that
            % speed as the session speed
            speeds = fetchn(flebm.Trials(key),'speed');
            assert(length(unique(speeds))==1,'Multiple speeds found!')
            key.sess_speed = speeds(1);            
            self.insert(key)
        end
    end
end
