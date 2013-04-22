%{
rf.MapSets (computed) # my newest table
-> rf.SpikeSets
-----

%}

classdef MapSets < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.MapSets')
        popRel = rf.SpikeSets('pre_stim_time=300 and post_stim_time=300')
    end
    
    methods
        function self = MapSets(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % rf.Map has to be populated first since rf.Map2dAvg depends on it.
            makeTuples(rf.Map,key);
            makeTuples(rf.MapAvg,key);
        end
    end
    methods
        function plot(self,varargin)
            
            args.show_tit = true;
            args = parse_var_args(args,varargin{:});
            
            figure
            set(gcf,'Position',[296,183,646,478])
            
            key = fetch(self);
            md = fetch(rf.Map(key));
            
            allLags = [md.lag];
            lags = unique(allLags);
            all_mapTypes = [md.map_type_num];
            map_type_num = unique(all_mapTypes);
            map_type_str = fetchn(rf.MapTypes(sprintf('map_type_num in %s',...
                util.array2csvStr(map_type_num))),'map_type');
            nMapTypes = length(map_type_num);
            nLags = length(lags);
            c = 0;
            for i = 1:nMapTypes
                for j = 1:nLags
                    c = c + 1;
                    subplot(nMapTypes,nLags+1,c)
                    plot(rf.Map(key) & sprintf('map_type_num = %u and lag = %u',map_type_num(i),...
                        lags(j)));
                    cylabel(map_type_str{i},j==1);
                    ctitle(sprintf('%u ms',lags(j)),i==1);
                end
                % Plot time average map
                c = c+1;
                subplot(nMapTypes,nLags+1,c);
                plot(rf.MapAvg(key , sprintf('map_type_num = %u',map_type_num(i))));
                ctitle('Avg',i==1);
            end
            if args.show_tit
                ms_suptitle(get_tit(self));
            end
        end
        function fn = get_tit(self)
            ekey = fetch(self);
            subj = fetch1(acq.Subjects(ekey),'subject_name');
            vis = fetch1(sess.ElecLoc(ephys.Spikes(ekey)),'vis_area_num');
            elec = fetch1(ephys.Spikes(ekey),'electrode_num');
            ut = {'multi-unit','single-unit'};
            utype = ut{ekey.sort_method_num - 3};
            sessdt = getDateStrFromPathStr(fetch1(acq.Sessions(ekey),'session_path'));
            fn = sprintf('%s_V%u_elec_%u_unit_id_%u_%s_%s',subj, vis, elec, ekey.unit_id, utype,sessdt);
        end
    end
end
