%{
stim.PixPerDeg (computed) # my newest table
-> stimulation.StimTrialGroup
-----
pix_per_deg: double # pixel per degree for each sessions.
%}

classdef PixPerDeg < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('stim.PixPerDeg')
	end
	properties
		popRel = stimulation.StimTrialGroup;
	end

	methods
		function self = PixPerDeg(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)

             % Compute flash_center_x in degrees
            sessData = fetch(stimulation.StimTrialGroup(key),'*');
            const = sessData.stim_constants;
            if isfield(const,'resolution')
               resol_x = const.resolution(1);
            else
                resol_x = 1600;
                if abs(resol_x - const.monitorCenter(1)*2) > 10
                    error('Monitor resolution_x is possibly different from 1600');
                end
            end
            
            % To fix inconsistencies, we are going to assume 41 as monitor size_x.
            if strcmp(const.monitorType,'CRT')
                if isfield(const,'monitorSize')
                    if abs(41-const.monitorSize(1)) < 2
                        const.monitorSize(1) = 41;
                    end
                else
                    const.monitorSize = [41 30];
                end
                if const.monitorDistance == 109 && key.subject_id==8
                    const.monitorDistance = 107;
                end
            end
            key.pix_per_deg = degrees2pixels(1,const.monitorDistance, resol_x,...
                const.monitorSize(1));
            self.insert(key)
		end
	end
end
