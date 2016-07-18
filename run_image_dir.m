function run_image_dir(img_dir, ext, result_dir)

imgfiles = dir(fullfile(img_dir, ['*.', ext]));
nfiles = length(imgfiles);

if ~exist(result_dir, 'dir'),
    mkdir(result_dir);
end

count = 1;%pic_count
incount = 1;%in_count
correct = 0;
wrong = 0;
discrete = 0;

detface_count = 0;

global net12;
global net12_c;
global net24;
global net24_c;
global net48;
global net48_c;

net12 = load('12net-newborn/f12net.mat') ;
net12_c = load('12net-cc-v1/f12net_c.mat') ;
net24 = load('24net-newborn/f24net-cpu.mat') ;
net24_c = load('24net-cc-v1-no256/f24netc.mat') ;
%net48 = load('48net-6hard-2/f48net-cpu.mat') ;
net48 = load('48net-6hard/f48net-cpu.mat') ;
net48_c = load('48net-cc-cifar-v2-submean/f48netc.mat') ;

score_file = fopen(fullfile(result_dir, 'face_scores.txt'), 'w');

for i=1:nfiles
    tline = fullfile(img_dir, imgfiles(i).name);
    fprintf('%s\n', tline);
    fname = imgfiles(i).name;
    img = imread(tline);
    [~,~,c]=size(img);
    if c==1
        img=repmat(img,[1,1,3]);
    end
    boxes = [];
    imshow(img);
    tic;  % check time
    pad = 10;
    for tt=1:1
        [hh,ww,~]=size(img);
        I = uint8(zeros(hh+pad*2,ww+pad*2,3));
        I (pad:hh+pad-1,pad:ww+pad-1,:) = img;
        boxes_temp = scanpic_fast_only12_24_48_newmodel_submean_demo(I,tt);   %%
        boxes = [boxes;boxes_temp];
    end
    toc;
    if ~isempty(boxes)
        x1 = boxes(:,1);
        y1 = boxes(:,2);
        x2 = boxes(:,3);
        y2 = boxes(:,4);
        boxes_size = size(boxes);
        detface_count = detface_count + boxes_size(1);
        for xx = 1:boxes_size(1)
            rectangle('Position',[y1(xx)-pad,x1(xx)-pad,(y2(xx)-y1(xx)),x2(xx)-x1(xx)],'LineWidth',2,'EdgeColor','b');
            text(y1(xx)-pad,x1(xx)-pad,num2str(boxes(xx,5)),'BackgroundColor','b','Color','w');
            fprintf(score_file, '%.6f\n',    boxes(xx,5));
        end
        save_path = fullfile(result_dir, fname);
        %print(save_path, '-dpng');
        fig_frame = getframe;
        imwrite(fig_frame.cdata, save_path);
    end 
end

fclose(score_file);

log_file = fopen(fullfile(result_dir, 'detected_faces.txt'), 'w');
fprintf(log_file, 'num. of detected faces: %d\n', detface_count);
fclose(log_file);
