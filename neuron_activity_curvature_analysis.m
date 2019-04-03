%% Prcoess data and registrate channels

% Load tiff files
setup_proof_reading;
fprintf('tiff files loading finished. \n');
imshowpair(imagelist_g{1,1}, imagelist_r{1,1});
coef = 5;

% Registration
answer = questdlg('Need registration?', 'Image processing');
if strcmp(answer,'Yes')==1
    close all;
    figure; 
    subplot(1,2,1); imshowpair(imagelist_g{1,1}, imagelist_r{1,1});
    image_registration_tform; 
    subplot(1,2,2); imshowpair(movingRegistered{1,1}, imagelist_r{1,1});
end

%% Track neuron and generate signal

proof_reading(imagelist, [], filename, ...
    istart, iend, 1);

%% Save data

parts = strsplit(pathname, '\');
data_path = fullfile(parts{1,1:end-3}, 'Alpha_Data_Raw', parts{1,end-1});
warning('off'); mkdir(data_path); 
data_path_name = fullfile(data_path, [filename(1:end-4) '.mat']);
save(data_path_name, ...
    'signal', 'signal_mirror', 'ratio', 'neuron_position_data', 'dual_position_data');
fprintf('data saved. \n');

%% Process data

%imagelist_g = movingRegistered;
% Delineate dorsal and ventral muscles
tic; close all;  
[dorsal_data, ventral_data, centerline_data, centerline_data_spline, curvdata, curvdatafiltered] = ...
    extract_centerline_incomplete(imagelist_g, 10, 4);
toc;
%%
% % Calculate dorsal and ventral muscle activities, save output
% % Generate data
% tic;  fprintf('activity analysis kicks off \n');
% [dorsal_smd, ventral_smd, dorsal_smd_r, ventral_smd_r] = ...
%     activity_all(imagelist_g, imagelist_r, range, dorsal_data, ventral_data, centerline_data_spline, curvdatafiltered);
% fprintf('activity analysis finished. \n');
% figure;
% subplot(1,2,1); imagesc(dorsal_smd./dorsal_smd_r); title('Dorsal');
% subplot(1,2,2); imagesc(ventral_smd./ventral_smd_r); title('Ventral');
% toc;

% Save data
parts = strsplit(pathname, '\');
data_path = fullfile(parts{1,1:end-3}, 'Alpha_Data_Raw', parts{1,end-1});
warning('off'); mkdir(data_path); 
data_path_name = fullfile(data_path, [filename(1:end-4) '_curvature.mat']);
save(data_path_name, ...
    'centerline_data_spline', 'curvdatafiltered', 'curvdata', 'dorsal_data', 'ventral_data');
% data_path_new = fullfile(data_path, 'Alpha_Data_Raw', 'Muscle_Interneurons_Ablated');
fprintf('data saved. \n');

%% Navigate to data folder to caculate neuron curvature and then create superimposed movies

%%%%%%%%%% Caculate curvature

[filename, pathname] = uigetfile('*.mat', ...
    'Select two files', 'MultiSelect', 'on');
load(filename{1,1}); load(filename{1,2});

[seg_cls, curv_cor] = closest_seg_curv(centerline_data_spline, ...
    neuron_position_data, curvdatafiltered);
close all; figure; plot(curv_cor);

data_path_name = fullfile(pathname, ...
    [filename{1,1}(1:end-4) '_neuron_curvature.mat']);
save(data_path_name, ...
    'seg_cls', 'curv_cor');
% data_path_new = fullfile(data_path, 'Alpha_Data_Raw', 'Muscle_Interneurons_Ablated');
fprintf('data saved. \n');


%%%%%%%%% Generate images superimposed with boundaries and centerline 

setup_proof_reading;
filenamemovie = filename;

h = figure(1);

for slide = 1:length(imagelist)
   
    hold off;
    imshow(imagelist_g{slide,1}, [0 3000]);
    hold on;
    plot(ventral_data{2*slide-1,1}, ventral_data{2*slide,1},'b');
    plot(dorsal_data{2*slide-1,1}, dorsal_data{2*slide,1},'r');
    plot(centerline_data_spline(:, 2*slide-1), centerline_data_spline(:, 2*slide), ':w');
    
    drawnow;
    frame = getframe(h);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im,256);
    
    if slide == 1
        imwrite(imind, cm, [filenamemovie(1:end-4) '_overlaid.gif'], 'gif', 'loopcount', Inf, 'delaytime', 1);
    else
        imwrite(imind, cm, [filenamemovie(1:end-4) '_overlaid.gif'], 'gif', 'writemode', 'append', 'delaytime', 1);
    end
    
end
