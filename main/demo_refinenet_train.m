
% Author: Guosheng Lin (guosheng.lin@gmail.com)

% This file shows how to perform training on your own dataset.

% Before running this demo file for training, you need to 
% download the PASCAL VOC 2012 dataset and place it at: 
% ../datasets/voc2012_trainval

% Training on other dataset:
% other datasets can be handled in a similar way as the VOC2012 dataset.
% Basically the users need to provide a file to describe your dataset:
% my_gen_ds_info_[your dataset name].m
% please refer to my_gen_ds_info_voc.m for details

% Training instructions:

% Stage 1: using a fixed learning rate for training util the performance
% get stable on the validation set.

% Stage 2: chose one cached model, initilize from this model, and using a
% lowler learning rate (e.g., multiplied by 0.1) to peform further training. 

% For example, using the following setting for loading an existed model and
% using a lower learning rate:
% run_config.trained_model_path='../cache_data/voc2012_trainval/model_20161219094311_example/model_cache/epoch_70';
% run_config.learning_rate=5e-5;

% Please refer to the following demo file for perform further training with lowler learning rate:
% demo_refinenet_train_reduce_learning_rate.m


function demo_refinenet_train()


rng('shuffle');

addpath('./my_utils');
dir_matConvNet='../libs/matconvnet/matlab';
run(fullfile(dir_matConvNet, 'vl_setupnn.m'));


run_config=[];
ds_config=[];

run_config.use_gpu=true;
% run_config.use_gpu=false;
run_config.gpu_idx=1;

% use a random model name:
model_name=['model_' datestr(now, 'YYYYmmDDHHMMSS')];

% or specify a model_name for training, if the cached snapshot files existed, it will resume training
% model_name='model_20161219094311_example';

% update the model name when reducing learning rate for training, e.g.,
% model_name='model_20161219094311_example_epoch70_low_learn_rate';



ds_name='voc2012_trainval';
gen_ds_info_fn=@my_gen_ds_info_voc;


% control the size of input images
run_config.input_img_short_edge_min=450;
run_config.input_img_short_edge_max=1100;


run_config.input_img_scale=1;


ds_config.use_dummy_gt=false;
run_config.use_dummy_gt=ds_config.use_dummy_gt;
ds_config.use_custom_data=false;


ds_config.ds_name=ds_name;
ds_config.gen_ds_info_fn=gen_ds_info_fn;
ds_config.ds_info_cache_dir=fullfile('../datasets', ds_name);


run_config.root_cache_dir=fullfile('../cache_data', ds_name, model_name);
mkdir_notexist(run_config.root_cache_dir);

run_config.model_name=model_name;

diary_dir=run_config.root_cache_dir;
mkdir_notexist(diary_dir);
diary(fullfile(diary_dir, 'output.txt'));
diary on


run_dir_name=fileparts(mfilename('fullpath'));
[~, run_dir_name]=fileparts(run_dir_name);
run_config.run_dir_name=run_dir_name;
run_config.run_file_name=mfilename();




fprintf('\n\n\n=====================================================================\n');
disp('gen ds_info');

disp('ds_config:');
disp(ds_config);

ds_info=gen_dataset_info(ds_config);

my_diary_flush();


fprintf('\n\n\n=====================================================================\n');
disp('run network');


run_config.run_evaonly=false;


% settings for training:

run_config.trained_model_path=[];
run_config.learning_rate=5e-4;


% init from a cached model
% e.g., can be used for resuming network training with a lower learning rate by
% initilizing from a cached model.
% the following is an example for loading a cached model and using a lower learning
% to continue the training

% run_config.trained_model_path='../cache_data/voc2012_trainval/model_20161219094311_example/model_cache/epoch_70';
% run_config.learning_rate=5e-5;


% turn on this option to cache all data into memory, if it's possible
% run_config.cache_data_mem=true;
run_config.cache_data_mem=false;

% random crop training:
run_config.crop_box_size=400;

% for cityscape, using a larger crop:
% run_config.crop_box_size=600;

% evaluate step: do evaluation every 10 epochs, can be set to 5:
run_config.eva_run_step=10;
run_config.snapshot_step=1;

% choose ImageNet pre-trained resnet:
run_config.init_resnet_layer_num=50;
% run_config.init_resnet_layer_num=101;
% run_config.init_resnet_layer_num=152;

% generate network
run_config.gen_network_fn=@gen_network_main;

run_config.gen_net_opts_fn=@gen_net_opts_model_type1;



% uncomment the following for debug:
% select a subset for both training and evaluation.
% ds_info.train_idxes=ds_info.train_idxes(1:5);
% ds_info.test_idxes=ds_info.train_idxes;
% run_config.snapshot_step=inf;


train_opts=run_config.gen_net_opts_fn(run_config, ds_info.class_info);




disp('train_opts:');
disp(train_opts);

disp('train_opts.eva_param:');
disp(train_opts.eva_param);

my_diary_flush();

imdb=my_gen_imdb(train_opts, ds_info);

data_norm_info=[];
data_norm_info.image_mean=128;

imdb.ref.data_norm_info=data_norm_info;

if run_config.use_gpu
	gpu_num=gpuDeviceCount;
	if gpu_num>=1
		gpuDevice(run_config.gpu_idx);
    else
        error('no gpu found!');
	end
end

[net_config, net_exp_info]=prepare_running_model(train_opts);

% net_config can be changed here before running the network

my_net_tool(train_opts, imdb, net_config, net_exp_info);


fprintf('\n\n--------------------------------------------------\n\n');
disp('results are saved in:');
disp(run_config.root_cache_dir);


my_diary_flush();
diary off


end


