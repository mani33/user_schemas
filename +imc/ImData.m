%{
imc.ImData (computed) # store image and movie data for ImCat experiments
-> imc.Stim
image_num                    : int unsigned                  # imageId
-----
im : longblob # image matrix
movie: longblob # 3D array - movie frames of a given image
# add additional attributes
%}

classdef ImData < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = imc.Stim  % !!! update the populate relation
    end
    
    methods
        function self = ImData(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
        function makeTuples(self, key)
            % Get image matrices for all the images used in the experiment
            sc = fetch(imc.StimConst(key),'*');
            params.flipIntervalSecs = fetch1(vstim.RefreshPeriod(key),'refresh_period_msec')/1000;
            params.dynamicStimTimeForRampSteps = sc.dynamic_stim_times;
            params.staticStimTimeForRampSteps = sc.static_stim_times;
            params.bgColor = [sc.bg_color_r;sc.bg_color_g;sc.bg_color_b];
            params.nFramesPerBufferSwap = sc.n_frames_per_bufferswap;
            params.rand_seed_data = sc.rand_seed_data;
            params.normalizeSpatialFreq = sc.normalize_spat_freq;
            params.im_for_avg_amp_sp = sc.im_for_avg_amp_sp;
            params.imageVignetteWidthPix = sc.im_vignette_width;
            params.showDynamicImage = true;
            imageDir = getLocalPath('/stor01/mani/images');
            params.imageClassArray = {'amMon','amHum','uaMonBr','uaHumBr'};
            imca = {'am_mon','am_hum','ua_mon_br','ua_hum_br'};
            params.uaMonBrFolder = 'modified/monkeys/unAmbiguous';
            params.uaHumBrFolder =  'modified/humans/unAmbiguous';
            
            params.amMonFolder = 'modified/monkeys/ambiguous';
            params.amHumFolder = 'modified/humans/ambiguous';
            
            monFolder = 'modified/monkeys/unAmbiguous';
            humFolder =  'modified/humans/unAmbiguous';
            
            
            amMonFolder = 'modified/monkeys/ambiguous';
            amHumFolder = 'modified/humans/ambiguous';
            
            folderNames     =   {   amMonFolder,...
                amHumFolder,...
                monFolder,...
                humFolder
                };
            %--------------------------------------------------------------------------
            nClasses = length(params.imageClassArray);
            ic = 0;
            imageClassArray = cell(1,1);
            %--------------------------------------------------------------------------
            for i = 1:nClasses
                imageNums = sc.(imca{i});
                if any(imageNums)
                    ic = ic+1;
                    imageClassArray{ic} = params.imageClassArray{i};
                    for j = 1:length(imageNums)
                        imageFileFs = num2str(imageNums(j));
                        folderName = folderNames{i};
                        imageToLoad = util.getImageMatrix(imageFileFs,folderName,imageDir);
                        images.(params.imageClassArray{i})(j).imageMatrix = imageToLoad(:,:,1);
                        images.(params.imageClassArray{i})(j).imageNum = imageNums(j);
                        fprintf('completed: %0.0f: %0.0f\n',j,imageNums(j));
                    end
                end
            end
            params.imageClassArray = imageClassArray;
            %% Load image stacks after computing phase scrambling
            dd = dynamicImage.recreatePhaseScramblingData(images,params,sc);
            
            fprintf('Performing spatial vignetting for single images\n')
            dd.images = addGradientFrame(dd.images,params);
            
            fprintf('Performing spatial vignetting for image stacks\n')
            ff = addGradientFrameForImageStacks(dd.repImDispData,params);
            nIm = length(ff);
            
            for i = 1:nIm
                ida = ff(i);
                key.image_num = ida.imageId;
                key.im = dd.images.(imageClassArray{i}).imageMatrix;
                key.movie = ida.imageStack;
                insert(self,key)
            end
        end
    end
end

