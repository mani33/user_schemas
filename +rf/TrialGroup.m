% rf.TrialGroup - Subset of DotMappingExperiment sessions

%{
rf.TrialGroup (computed) # my newest table
-> stimulation.StimTrialGroup
-----

%}

classdef TrialGroup < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.TrialGroup')
        popRel = (stimulation.StimTrialGroup-acq.StimulationIgnore) & ephys.SpikeSet &...
            acq.Stimulation('exp_type =''DotMappingExperiment'' and correct_trials >= 100')...
            - acq.SessionsIgnore;
    end
    
    methods
        function self = TrialGroup(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % Populate subtables
            %             makeTuples(rf.Phys,key)
            makeTuples(rf.StimConstants,key)
            makeTuples(rf.Trials,key)
        end
    end
    methods
        function varargout = plotMapForTetArray(self,xylim_deg,col)
            % Supported only for multiunits currently
                     
            if nargin < 2
                xylim_deg = [];
                col = [0 0 0.8];
            elseif nargin < 3
                col = [0 0 0.8];
            end
            
            if ~isempty(xylim_deg)
                ori = xylim_deg([1 3]);
                width = diff(xylim_deg(1:2));
                height = diff(xylim_deg(3:4));
                pos = [ori width height];
            end
            key = fetch(self * acq.Subjects * acq.Sessions,'*');
            assert(length(key)~=0,'The requested tuple does not exit')
            assert(length(key)==1,'Supported for one tuple only')
            
            tetArrayLayout = getTetrodeArrayLayout(key.subject_name,1);
            [nRows, nCols] = size(tetArrayLayout);
            c = 0;
            figure;
            font_size = 6;
            set(gcf,'Position',[147 1172 956 665])
            dot_size = fetch1(rf.StimConstants(key),'dot_size');
            dnx = fetch1(rf.StimConstants(key),'dot_num_x');
            dny = fetch1(rf.StimConstants(key),'dot_num_y');
            % Plot
            for iRow = 1:nRows
                for iCol = 1:nCols
                    c = c + 1;
                    tet = tetArrayLayout{iRow,iCol};
                    if ischar(tet) && ismember(tet,{'R1','R2','R3','R4'}) % ref
                        subplot(nRows,nCols,c);
                        
                        title(tet,'FontSize', font_size,'Color',[1 0 0]);
                        if ~isempty(xylim_deg)
                            rectangle('Position',pos,'FaceColor',col)
                            axis equal
                            xlim(xylim_deg(1:2))
                            ylim(xylim_deg(3:4))
                            set(gca,'FontSize', font_size)
                        else
                            imagesc(cat(3,0*ones(dny,dnx),0*ones(dny,dnx),0.8*ones(dny,dnx)));
                            set(gca,'FontSize', font_size,'XTickLabel',[],'YTickLabel',[])
                        end
                    elseif ~isnan(tet) % tetrodes
                        titStr = sprintf('TT %0.0d',tet);
                        rv = rf.MapAvg(sprintf('sort_method_num = 4 and map_type_num=3 and subject_id=%u',key.subject_id)) & ...
                            key & ephys.Spikes(sprintf('electrode_num = %u',tet));
                        subplot(nRows,nCols,c);
                        if count(rv) > 0  % live electrodes
                            plot(rv,'xylim_deg',xylim_deg,'bkgdCol',col);
                            set(gca,'FontSize', font_size);
                            title(titStr,'FontSize', font_size);
                            
                        else % dead/non-existent electrodes
                            title(titStr,'FontSize', font_size);
                            if ~isempty(xylim_deg)
                                rectangle('Position',pos,'FaceColor',col)
                                axis equal
                                xlim(xylim_deg(1:2))
                                ylim(xylim_deg(3:4))
                                set(gca,'FontSize', font_size)
                            else
                                imagesc(cat(3,0*ones(dny,dnx),0*ones(dny,dnx),0.8*ones(dny,dnx)));
                                axis image;
                                set(gca,'FontSize', font_size,'XTickLabel',[],'YTickLabel',[])                                
                            end
                        end
                    end
                end
            end
            [~, sds] = fileparts(fetch1(acq.Stimulation(key),'stim_path'));

            dotSizeDeg = dot_size/fetch1(vstim.PixPerDeg(self),'pix_per_deg');
            ms_suptitle([key.subject_name '  ' sds sprintf('   dotSize: %0.2f deg',dotSizeDeg)]);
            if nargout
                varargout{1} = [key.subject_name '_' sds '.png'];
            end
        end
        
        function plotRfOutlines(self,varargin)
            % Plot the receptive field outlines for all the multiunits from the given
            % session.
            eKeys = fetch(rf.FitAvg(self,'map_type_num=3'));
            for key = eKeys'
                [ox oy] = getOutline(rf.FitAvg(key));
                plot(ox,oy,'k')
                hold on
            end
            
            set(gca,'YDir','Reverse','Xlim',[-0.5 4],'Ylim',[-0.5 2.5])
            plot([0 0],ylim,'r')
            plot(xlim,[0 0],'r')
            axis equal
            set(gca,'Xlim',[-0.5 4],'Ylim',[-0.5 2.5])
        end
        function plotRfCenters(self,varargin)
            % Plot the receptive field centers for all the multiunits from the given
            % session.
            args = struct;
            args = parseVarArgs(args,varargin{:});
            argList = struct2argList(args);
            
            eKeys = fetch(rf.FitAvg(self,'map_type_num=3'));
            for key = eKeys'
                [cx cy] = fetchn(rf.FitAvg(key),'cen_x','cen_y');
                plot(cx,cy,'k.','MarkerSize',14,argList{:})
                hold on
            end
            
            set(gca,'YDir','Reverse','Xlim',[-0.5 4],'Ylim',[-0.5 2.5])
            plot([0 0],ylim,'r')
            plot(xlim,[0 0],'r')
            axis equal
            set(gca,'Xlim',[-0.5 4],'Ylim',[-0.5 2.5])
            
        end
    end
end