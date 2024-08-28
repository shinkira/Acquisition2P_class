function register_static_image

    %% Load movie_1 and movie_2 from TIFF files

    if 0
        % Specify the file paths for the TIFF files
        movie_1_tiff = 'Z:\HarveyLab\Tier1\Shin\ShinDataAll\ImagingNew\SK113\240812\FOV3_00004_00001.tif';
        movie_2_tiff = 'Z:\HarveyLab\Tier1\Shin\ShinDataAll\ImagingNew\SK113\240816\FOV3_00002_00001.tif';

        % Load the TIFF files into 3D matrices
        castType = 'int16';
        [movie_1, metaMovie_1] = tiffRead(movie_1_tiff,castType);
        [movie_2, metaMovie_2] = tiffRead(movie_2_tiff,castType);

        %movie_1 = loadtiff(movie_1_tiff); % Assuming loadtiff loads the TIFF into a 3D matrix
        %movie_2 = loadtiff(movie_2_tiff); % Same assumption for movie_2

        %% Compute mean images for movie_1 and movie_2

        mean_image_1 = mean(movie_1, 3); % Calculate mean across time (3rd dimension)
        mean_image_2 = mean(movie_2, 3); % Same for movie_2

        save('mean_image.mat','mean_image_1','mean_image_2');
    else
        load('mean_image.mat','mean_image_1','mean_image_2');
    end

    %% Non-rigid and rigid registration for movie_1 and movie_2 mean images

    % aligned_nc is the nonrigid version 
    % aligned_rigid is the rigid version

    aligned_nc = {{[],[]},{[],[]}};
    aligned_rigid = {{[],[]},{[],[]}};

    % Perform registration for both movies
    % Use the mean images as target and source for registration
    for k = 1:2
        if k == 1
            source_plane = mean_image_1;
            target_plane = mean_image_2;
        else
            source_plane = mean_image_2;
            target_plane = mean_image_1;
        end

        % Non-rigid registration parameters
        opts = NoRMCorreSetParms('d1', size(target_plane, 1), 'd2', size(target_plane, 2), ...
                                 'grid_size', [128,128], 'mot_uf', 4, 'bin_width', 200, ...
                                 'max_shift', 15, 'max_dev', 3, 'us_fac', 50, 'init_batch', 20, ...
                                 'correct_bidir', false);

        % Apply non-rigid registration
        [aligned_nc{k}{2}, shifts_nc, template_nc, opts_nc, bdp_nc] = regNC(source_plane, target_plane, opts, 0);
        aligned_nc{k}{1} = applyRegNC(source_plane, shifts_nc, opts_nc, bdp_nc);

        % Perform rigid registration
        [aligned_rigid{k}{2}, shifts_rigid] = registerFFT(source_plane, target_plane);
        aligned_rigid{k}{1} = applyFFTShifts(source_plane, shifts_rigid);
    end

    %% Plot aligned results for visualization
    if 1
        clim = [0 1000];
        figure(1);clf;
        subplot(2,3,1); imagesc(mean_image_1, clim); axis equal; title('Movie 1 Mean Image');colorbar;
        subplot(2,3,2); imagesc(aligned_nc{1}{2}, clim); axis equal; title('Non-rigid Aligned (Movie 1 -> Movie 2)');colorbar;
        subplot(2,3,3); imagesc(aligned_rigid{1}{2}, clim); axis equal; title('Rigid Aligned (Movie 1 -> Movie 2)');colorbar;
        subplot(2,3,4); imagesc(mean_image_2, clim); axis equal; title('Movie 2 Mean Image');colorbar;
        colormap('gray');
        image_diff_nc    = mean_image_2./aligned_nc{1}{2};
        image_diff_rigid = mean_image_2./aligned_rigid{1}{2};
        
        image_diff_nc(image_diff_nc<1e-8) = 1e-8;
        image_diff_rigid(image_diff_rigid<1e-8) = 1e-8;
        log_image_diff_nc = log(image_diff_nc);
        log_image_diff_rigid = log(image_diff_rigid);
        
        subplot(2,3,5); imagesc(log_image_diff_nc,[-3 3]); axis equal; title('Non-rigid diff (Movie 1 -> Movie 2)');colorbar;
        subplot(2,3,6); imagesc(log_image_diff_rigid,[-3 3]); axis equal; title('Rigid diff (Movie 1 -> Movie 2)');colorbar;
        colormap('parula');
        % colormap('gray');
    end
    
    figure(3);clf;
    set(gcf,'OuterPosition',[700 200 800 800])
    imagesc(mean_image_2, clim); axis equal; title('Movie 2 Mean Image');colorbar;
    axis([0 512 0 512])
    colormap('gray');
    export_fig(gcf,['mean_image_2','.jpg'],'-jpg','-nocrop');
    
    figure(4);clf;
    set(gcf,'OuterPosition',[700 200 800 800])
    imagesc(aligned_nc{1}{2}, clim); axis equal; title('Non-rigid Aligned (Movie 1 -> Movie 2)');colorbar;
    axis([0 512 0 512])
    colormap('gray');
    export_fig(gcf,['mean_image_1','.jpg'],'-jpg','-nocrop');
    
    
    figure(10);clf;
    set(gcf,'OuterPosition',[700 200 800 800])
    image_diff = mean_image_2 - aligned_nc{1}{2};
    imagesc(image_diff);
    % colormap('gray');
    axis equal;
    colorbar
    
end

function [reg,shifts,template,opts,bdp] = regNC(Y,template,opts,isrigid)
    % wrapper function for normcorre registration of image series (movies)
    if isempty(opts)
        if isrigid
            opts = NoRMCorreSetParms('d1',size(Y,1),'d2',size(Y,2),'bin_width',200,'max_shift',15,'us_fac',50,'init_batch',20,'correct_bidir',false);
        else
            opts = NoRMCorreSetParms('d1',size(Y,1),'d2',size(Y,2),'grid_size',[128,128],'mot_uf',4,'bin_width',200,'max_shift',15,'max_dev',3,'us_fac',50,'init_batch',20,'correct_bidir',false);
        end
    end

    bdp = BiDiPhaseOffsets(Y);
    disp(['bdp offset ' num2str(bdp)]);
    % reject more than 3 pixel shift
    bdp(abs(bdp)>3) = 0;
    Y = ShiftBiDi(bdp, Y, size(Y,1), size(Y,2));

    if size(Y,3)>1
        if isempty(template)
            [reg,shifts,template,opts] = normcorre_batch(Y,opts);
        else
            [reg,shifts,~,opts] = normcorre_batch(Y,opts,template);
        end
    else
        if isempty(template)
            [reg,shifts,template,opts] = normcorre(Y,opts);
        else
            [reg,shifts,~,opts] = normcorre(Y,opts,template);
        end
    end
end

function [Y] = applyRegNC(Y,shifts,opts,bdp)
    % wrapper function for normcorre registration of volumes
    Y = ShiftBiDi(bdp, Y, size(Y,1), size(Y,2));
    Y = apply_shifts(Y,shifts,opts);
end

function [reg, shifts] = registerFFT(movie,template)
    nframes = size(movie,3);
    shifts = zeros(nframes,2);
    reg = zeros(size(movie));

    for k =1 :nframes
        [reg(:,:,k), shifts(k,1), shifts(k,2)] = subpixel_fft_registration(movie(:,:,k), template);
    end
end

function [reg] = applyFFTShifts(stack,shifts)
    reg = zeros(size(stack));

    for k =1:size(stack,3)
        reg(:,:,k) = imtranslate(stack(:,:,k),shifts(k,:));
    end
end