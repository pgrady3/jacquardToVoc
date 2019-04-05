%% An example of preparing data for da-faster-rcnn, the exmample is based on adaptation from Cityscapes to Foggy Cityscapes, other datasets can be prepared similarly.
%  
% yuhua chen <yuhua.chen@vision.ee.ethz.ch> 
% created on 2018.07.17

clear;clc; close all;

visualize = false;
ANGLE_CLASSES = 19;

%% specify path
%source_data_dir = '/home/patrick/workspace/datasets/jacquard';
target_data_dir = '/home/patrick/workspace/datasets/jacquard';

%% initialization
img_dir = 'output/VOC2007/JPEGImages';
sets_dir = 'output/VOC2007/ImageSets/Main';
annotation_dir = 'output/VOC2007/Annotations';

addpath VOCdevkit2007/VOCcode
mkdir(img_dir); mkdir(sets_dir); mkdir(annotation_dir);

%% organize images & prepare split list.

% % process source train images
% [~,cmd_output] = system(sprintf('find %s -name "*.png"', ...
%     fullfile(source_data_dir,'leftImg8bit','train')));
% file_names = strsplit(cmd_output); file_names = file_names(1:end-1);
% 
% file_names = file_names(1:10);%CUT for debugging
% 
% source_train_list = cell(numel(file_names),1);
% for i = 1:numel(file_names)
%     im_name = strsplit(file_names{i},'/'); 
%     im_name = strrep(im_name{end},'.png','');
%     im_name = ['source_' im_name];
%     
%     img = imread(file_names{i});
%     imwrite(img,fullfile(img_dir, [im_name '.jpg']));
%     
%     source_train_list{i} = im_name;
%     
%     fprintf('%d %d\n', i, numel(file_names))
% end

% process target train images.
[~,cmd_output] = system(sprintf('find %s -name "*RGB.png"', target_data_dir));
file_names = strsplit(cmd_output);
file_names = file_names(1:end-1);

%file_names = file_names(1:10);%CUT for debugging

split_index = round(length(file_names) * 0.8);

train_files = file_names(1:split_index);
test_files = file_names(split_index + 1:end);


file_names = train_files;
target_train_list = cell(numel(file_names),1);
for i = 1:numel(file_names)
    im_name = strsplit(file_names{i},'/'); 
    im_name = strrep(im_name{end},'.png','');
    %im_name = ['target_' im_name];
    
    img = imread(file_names{i});
    imwrite(img,fullfile(img_dir, [im_name '.jpg']));
    
    target_train_list{i} = im_name;
    
    fprintf('%d %d\n', i, numel(file_names))
end

% process target test images
file_names = test_files;

target_test_list = cell(numel(file_names),1);
for i = 1:numel(file_names)
    im_name = strsplit(file_names{i},'/'); 
    im_name = strrep(im_name{end},'.png','');
    %im_name = ['target_' im_name];
    
    img = imread(file_names{i});
    imwrite(img,fullfile(img_dir, [im_name '.jpg']));
    
    target_test_list{i} = im_name;
    fprintf('%d %d\n', i, numel(file_names))
    
end

% write the list
%train_list = [source_train_list;target_train_list];
train_list = [target_train_list];
test_list = target_test_list;

write_list(train_list,fullfile(sets_dir,'trainval.txt'));
write_list(test_list,fullfile(sets_dir,'test.txt'));

%% prepare the annotation needed for training/testing.

file_names = [train_files, test_files];

for i = 1:numel(file_names)
    %find the annotation file name
    im_path = file_names{i};
    anno_path = strrep(im_path, '_RGB.png', '_grasps.txt');
    
    annos = importdata(anno_path);
    
    if visualize
        im = imread(im_path);
        imshow(im);
        
        for j = 1:size(annos, 1)
           cornersDraw = xyaojToCorners(annos(j, :));
           cornersDraw(5, :) = cornersDraw(1, :);
           line(cornersDraw(:, 1), cornersDraw(:, 2));
        end
    end
    
    boxes = zeros(size(annos, 1), 4);
    boxes(:, 1) = annos(:, 1) - annos(:, 4) / 2;
    boxes(:, 2) = annos(:, 2) - annos(:, 5) / 2;
    boxes(:, 3) = annos(:, 1) + annos(:, 4) / 2;
    boxes(:, 4) = annos(:, 2) + annos(:, 5) / 2;
    
    angle = mod(annos(:, 3), 360) / 360.001; %set range from [0 to 1)
    angle = floor(angle * ANGLE_CLASSES) + 1;
    
    im_name = strsplit(file_names{i},'/'); 
    im_name = im_name{end};
    im_name_jpg = strrep(im_name, '.png', '.jpg');
    
    im_inst = imread(file_names{i});
    
    clear save_var
    save_var.annotation.folder = 'VOC2007';
    save_var.annotation.filename = im_name_jpg;
    save_var.annotation.segmented = '0';
    save_var.annotation.size.width = num2str(size(im_inst,2));
    save_var.annotation.size.height = num2str(size(im_inst,1));
    save_var.annotation.size.depth = '3';
    
    for i_obj = 1:size(boxes, 1)
        save_var.annotation.object(i_obj).bndbox.xmin = round(boxes(i_obj, 1));
        save_var.annotation.object(i_obj).bndbox.ymin = round(boxes(i_obj, 2));
        save_var.annotation.object(i_obj).bndbox.xmax = round(boxes(i_obj, 3));
        save_var.annotation.object(i_obj).bndbox.ymax = round(boxes(i_obj, 4));
        class = int2str(angle(i_obj));
        save_var.annotation.object(i_obj).name = class;
        save_var.annotation.object(i_obj).difficult = '0';
        save_var.annotation.object(i_obj).truncated = '0';
        %fprintf('class %s \n', class);
    end
    
    xml_name = strrep(im_name, '.png', '');
    xml_name = char(xml_name);
    xml_name = fullfile(annotation_dir,[xml_name,'.xml']);
    VOCwritexml(save_var,xml_name);
    
    fprintf('%d %d\n', i, numel(file_names))
end

% for the target domain: Foggy Cityscapes, the
% annotation is the same, simply copy from Cityscapes

% all_target_images = [target_train_list;target_test_list];
% for i = 1:numel(all_target_images)
%     im_name = all_target_images{i};
%     source_name = strrep(strrep(im_name,'_foggy_beta_0.02',''),'target','source');
%     copyfile(fullfile(annotation_dir,[source_name,'.xml']),...
%         fullfile(annotation_dir,[im_name,'.xml']));
% end
