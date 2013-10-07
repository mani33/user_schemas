%{
vstim.PixPerDeg (computed) # my newest table
-> stimulation.StimTrialGroup
-----
pix_per_deg: double # pixel per degree for each sessions.
%}

classdef PixPerDeg < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('vstim.PixPerDeg')
        popRel = stimulation.StimTrialGroup;
    end
    
    methods
        function self = PixPerDeg(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            
            % Compute flash_center_x in degrees
            sessData = fetch(stimulation.StimTrialGroup(key),'*');
            const = sessData.stim_constants;
            if isfield(const,'resolution')
                resol_x = const.resolution(1);
            else
                resol_x = 1600;
                const.monitorCenter = [800 600];
                disp('Monitor center of [800 600] was assumed!')
                if abs(resol_x - const.monitorCenter(1)*2) > 10
                    error('Monitor resolution_x is possibly different from 1600');
                end
            end
            
            % To fix inconsistencies, we are going to assume 41 as monitor size_x.
            if ~isfield(const,'monitorType')
                const.monitorType = 'CRT';
            end
            if strcmp(const.monitorType,'CRT')
%                 if isfield(const,'monitorSize')
%                     if abs(41-const.monitorSize(1)) < 2
%                         const.monitorSize(1) = 41;
%                     end
%                 else
                    const.monitorSize = [41 30];
%                 end
                if ~isfield(const,'monitorDistance') && key.subject_id == 8
                    const.monitorDistance = 107;
                    disp('Monitor distance of 107 cm was assumed for Hulk')
                end
                if const.monitorDistance == 109 && key.subject_id==8
                    const.monitorDistance = 107;
                end
            end
            key.pix_per_deg = util.degrees2pixels(1,const.monitorDistance, resol_x,...
                const.monitorSize(1));
            self.insert(key)
        end
    end
end
