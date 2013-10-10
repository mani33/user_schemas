%{
fle.BarRfCen (computed) # my newest table
-> fle.BarRfFit

-----
cen_x_deg = null: double # bar center x in degrees
cen_x_ind = null: double # bar center in terms of bar location indices


barrfcen_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef BarRfCen < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('fle.BarRfCen')
		popRel = fle.BarRfFit & fle.RelFlashCenX  % !!! update the populate relation
	end

	methods
		function self = BarRfCen(varargin)
			self.restrict(varargin{:})
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
		%!!! compute missing fields for key here
            tup = key;
            fp = fetch1(fle.BarRfFit(key),'fit_params');
            if ~isempty(fp) 
                tup.cen_x_ind = fp(3);
                % Find corresponding visual space in degrees
                [loc_ind,loc_deg] = fetchn(fle.RelFlashCenX(key),'flash_location','rel_to_mon_cen_deg');
                loc_ind = unique(loc_ind);
                loc_deg = unique(loc_deg);
                tup.cen_x_deg = interp1(loc_ind,loc_deg,tup.cen_x_ind);
            end
			self.insert(tup)
		end
	end
end
