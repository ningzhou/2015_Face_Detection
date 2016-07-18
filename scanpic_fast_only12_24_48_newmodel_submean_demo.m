function boxes=scanpic_fast_only12_24_48_newmodel_submean_demo(img,tt)
% Load the CNN learned before
boxes=[];
global net12;
global net12_c;
global net24;
global net24_c;
global net48;
global net48_c;
% Load the sentence
[oh,ow,~] = size(img);
origin_im = img;
bias12 = 0.3;
bias24 = 0.2;
bias48 = 0.5;

thres12 = 0.2;
thres24 = 0.16;
thres48 = 0.12;
%calibration ���
%
xn = [0.17,0,-0.17]; %0.17
yn = [0.17,0,-0.17]; %0.17
sn = [1.21,1.10,1.0,0.91,0.83];
zzd_24=0;
%{
xn = [0,0,0];
yn = [0,0,0];
sn = [1,1,1,1,1];
%}
chang_count = 1;
chang = zeros(3,45);

for m = 1:5 %adverse
    for n = 1:3
        for k = 1:3
            chang(:,chang_count)=[xn(k),yn(n),sn(m)];
            chang_count = chang_count + 1;
        end
    end
end

boxes=[];
boxes12=[];
boxes24=[];
boxes48=[];
ttt = 1;

for k=1:8
    %ss = (200/min(oh,ow))/ttt;% oh/12<f<oh
    ss = (500/min(oh,ow))/ttt;
    %ss = 12/(20*ttt);
    ttt =ttt*1.41;
    im = imresize(origin_im,ss);
    [h, w ,c] = size(im)    ;
    im = im2single(im) ;
    im = bsxfun(@minus, im,net12.imageMean) ;
    %cim =  (im - net12_c.imageMean) ;
    win12=[];
    win24=[];
    win48=[];
    %-----------------------12net--------------
    if(h<=12)
        break;
    end;
    if(w<=12)
        break;
    end;
    
    im1 = im;
    im2 = im; im2(:,1,:) = [];% delete first col
    im3 = im; im3(1,:,:) = [];% delete first row
    im4 = im; im4(1,:,:) = [];im4(:,1,:) = [];% delete first row and col
    res12_last1=[];
    res12_last2=[];
    res12_last3=[];
    res12_last4=[];
    if( ~isempty(im1) )
        res12_1 = vl_simplenn(net12,im1) ;
        X = res12_1(end).x;
        E = exp(bsxfun(@minus, X, max(X,[],3))) ;
        L = sum(E,3) ;
        Y = bsxfun(@rdivide, E, L) ;
        %imshow(res12_1(end).x(:,:,1)); %heatmap
        res12_last1 = reshape(Y,[],2)';
    end;
    if( ~isempty(im2) )
        res12_2 = vl_simplenn(net12,im2) ;
        X= res12_2(end).x;
        [x,y,~] = size(X);
        E = exp(bsxfun(@minus, X, max(X,[],3))) ;
        L = sum(E,3) ;
        Y = bsxfun(@rdivide, E, L) ;
        Y(:,y,:)=[];
        res12_last2 = reshape(Y,[],2)';
    end;
    if( ~isempty(im3) )
        res12_3 = vl_simplenn(net12,im3) ;
        X = res12_3(end).x;
        [x,y,~] = size(X);
        E = exp(bsxfun(@minus, X, max(X,[],3))) ;
        L = sum(E,3) ;
        Y = bsxfun(@rdivide, E, L) ;
        Y(x,:,:)=[];
        res12_last3 = reshape(Y,[],2)';
    end;
    if( ~isempty(im4) )
        res12_4 = vl_simplenn(net12,im4) ;
        X = res12_4(end).x;
        E = exp(bsxfun(@minus, X, max(X,[],3))) ;
        L = sum(E,3) ;
        Y = bsxfun(@rdivide, E, L) ;
        [x,y,~] = size(X);
        Y(x,:,:)=[];
        Y(:,y,:)=[];
        res12_last4 = reshape(Y,[],2)';
    end;
    %local (1,1) (3,1) (5,1)...
    %im1
    l2 = 1:2:(w-12+1);%109 55
    local1_2 = sort(repmat(l2,1,floor((h-12)/2)+1));
    l1 = 1:2:(h-12+1);%181 91
    local1_1 = repmat(l1,1,floor((w-12)/2)+1);
    local_1 = [local1_1;local1_2];
    %im2
    l2 = 2:2:(w-12+1);%109
    local2_2 = sort(repmat(l2,1,floor((h-12)/2)+1));
    l1 = 1:2:(h-12+1);%181
    local2_1 = repmat(l1,1,floor((w-1-12)/2)+1);
    local_2 = [local2_1;local2_2];
    %im3
    l2 = 1:2:(w-12+1);%109
    local3_2 = sort(repmat(l2,1,floor((h-1-12)/2)+1));
    l1 = 2:2:(h-12+1);%181
    local3_1 = repmat(l1,1,floor((w-12)/2)+1);
    local_3 = [local3_1;local3_2];
    %im4
    l2 = 2:2:(w-12+1);%109
    local4_2 = sort(repmat(l2,1,floor((h-1-12)/2)+1));
    l1 = 2:2:(h-12+1);%181
    local4_1 = repmat(l1,1,floor((w-1-12)/2)+1);
    local_4 = [local4_1;local4_2];
    
    res12_last = [res12_last1,res12_last2,res12_last3,res12_last4];
    local = [local_1,local_2,local_3,local_4];
    chosen = res12_last(1,:)>bias12; %(res12_last(2,:) + bias12);
    value = res12_last(1,:);
    value = value(chosen);
    local = local(:,chosen)./ss;
    width = repmat(12./ss,1,sum(chosen));
    win12= [local;width;value]';
    % win12 = [win12;win12_tmp'];
    %win12 = cat(1,win12,win12_tmp');
    
    %-----------------------------12netc-----------------

    x1 = round(win12(:,1));
    y1 = round(win12(:,2));
    w = round(win12(:,3));
    x2 = x1 + w;
    y2 = y1 + w;
    delete = int32(x1<1)+int32(y1<1)+int32(x2>oh)+int32(y2>ow);
    win12(find(delete>0),:)=[];
    if isempty(win12)
        continue;
    end
    x1 = round(win12(:,1));
    y1 = round(win12(:,2));
    w = round(win12(:,3));
    x2 = x1 + w;
    y2 = y1 + w;
    process12_im = im2single(origin_im) ;
    process12_im = 256*bsxfun(@minus, process12_im , net12_c.imageMean) ;
    s = size(win12);
    x1_zzd = int32(x1 - 1);
    x2_zzd = int32(x2 - 1);
    y1_zzd = int32(y1 - 1);
    y2_zzd = int32(y2 - 1);
    w_zzd = int32(w(1)+1);  %w is same
    %resize_form12 = int32([12,12]);
    im12_zzd = zzd(process12_im,x1_zzd,x2_zzd,y1_zzd,y2_zzd,w_zzd,w_zzd,s(1));  %return patches by mex code
    im12_zzd = reshape(im12_zzd,w_zzd,w_zzd,3,s(1));
    im12 = imresize(im12_zzd,[12 12]);
    res12_c = vl_simplenn(net12_c,im12) ;
    X = res12_c(end).x;
    E = exp(bsxfun(@minus, X, max(X,[],3))) ;
    L = sum(E,3) ;
    Y = bsxfun(@rdivide, E, L) ;
    res12_c_last = reshape(Y,[],45)';
    for i = 1:s(1)
        res12_mask = find(res12_c_last(:,i)>thres12);
        if(~isempty(res12_mask))
            meanx = sum(chang(:,res12_mask),2)/size(res12_mask,1);
            xn = meanx(1);
            yn = meanx(2);
            sn = meanx(3);
            w = win12(i,3);
            %    win12(i,1) = win12(i,1)-yn*w/sn;
            %    win12(i,2) = win12(i,2)-xn*w/sn;
            %     win12(i,3) = w/sn;
            center_x = win12(i,1)+w/2;
            center_y = win12(i,2)+w/2;
            center_x = center_x - yn*w/sn;
            center_y = center_y - xn*w/sn;
            win12(i,3) = w/sn;
            win12(i,1) = center_x - win12(i,3)/2;
            win12(i,2) = center_y - win12(i,3)/2;
        end
    end
    boxes12 = [win12(:,1),win12(:,2),win12(:,1)+win12(:,3),win12(:,2)+win12(:,3),win12(:,4)];
    
    %-----------------------------nms
    pick = nms(boxes12,0.9);
    win12 = win12(pick(:),:);
    
    
    %-------------------------------24net-----------------------
    %disp('24net');
    x1 = round(win12(:,1));
    y1 = round(win12(:,2));
    w = round(win12(:,3));
    x2 = x1 + w;
    y2 = y1 + w;
    delete = int32(x1<1)+int32(y1<1)+int32(x2>oh)+int32(y2>ow);
    win12(find(delete>0),:)=[];
    process24_im = im2single(origin_im) ;
    win12(:,3)  = round(win12(:,3));
    win12 = sortrows(win12,3);
    x1 = round(win12(:,1));
    y1 = round(win12(:,2));
    w = win12(:,3);
    x2 = x1 + w;
    y2 = y1 + w;
    sort_w = win12(:,3);
    im24=[];
    while(~isempty(sort_w))
        select = find(win12(:,3)==sort_w(1));
        select_win = win12(select,:);
        x1_zzd = int32(x1(select) - 1);
        x2_zzd = int32(x2(select) - 1);
        y1_zzd = int32(y1(select) - 1);
        y2_zzd = int32(y2(select) - 1);
        w_zzd = int32(sort_w(1)+1);  %w is same
        im24_zzd = zzd(process24_im,x1_zzd,x2_zzd,y1_zzd,y2_zzd,w_zzd,w_zzd,numel(select));  %return patches by mex code
        im24_zzd = reshape(im24_zzd,w_zzd,w_zzd,3,[]);
        im24 = cat(4,im24,imresize(im24_zzd,[24 24]));
        sort_w(find(sort_w== sort_w(1)))=[];
    end
    im24 =  bsxfun(@minus,im24,net24.imageMean) ;
    cim24 = bsxfun(@minus,im24,net24_c.imageMean) ;
    %-----------------------24net------------------
    res24 = vl_simplenn(net24, im24) ;
    X = res24(end).x;
    E = exp(bsxfun(@minus, X, max(X,[],3))) ;
    L = sum(E,3) ;
    Y = bsxfun(@rdivide, E, L) ;
    res24_last = reshape(Y,2,[]);
    chosen = res24_last(1,:) > bias24;%- res24_last(2,:) > bias24;
    value = res24_last(1,:);
    value = value(chosen);
    w = w(chosen);
    w = w';
    win12 = win12(chosen,:);

    %-----------------------24net-c---------------
    posbatch24.im = cim24(:,:,:,chosen);
    if isempty(posbatch24.im)
        %disp('no24face');
        continue;
    end
    res24c = vl_simplenn(net24_c, posbatch24.im) ;
    res24c_last = reshape(res24c(end).x,45,[]);
    win24(:,1) = win12(:,1);
    win24(:,2) = win12(:,2);
    win24(:,3) = win12(:,3);
    win24(:,4) = value;
    for i = 1:length(w)
        res24_mask = find(res24c_last(:,i)>thres24);
        if(~isempty(res24_mask))
            meanx = sum(chang(:,res24_mask),2)/size(res24_mask,1);
            xn = meanx(1);
            yn = meanx(2);
            sn = meanx(3);
            wi = w(i);
            %     win24(i,1) = win12(i,1)-yn*wi/sn;
            %  win24(i,2) = win12(i,2)-xn*wi/sn;
            % win24(i,3) = wi/sn;
            center_x = win12(i,1)+wi/2;
            center_y = win12(i,2)+wi/2;
            center_x = center_x - yn*wi/sn;
            center_y = center_y - xn*wi/sn;
            win24(i,3) = wi/sn;
            win24(i,1) = center_x - win12(i,3)/2;
            win24(i,2) = center_y - win12(i,3)/2;
        end
    end
    boxes24 = [win24(:,1),win24(:,2),win24(:,1)+win24(:,3),win24(:,2)+win24(:,3),win24(:,4)];
    
    pick = nms(boxes24,0.85);
    win24 = win24(pick(:),:);
    %-------------------------------48net-----------------------
    if( isempty(win24) )
            continue;
    end;
    s = size(win24);
    zzd_24 = zzd_24+s(1);
    x1 = round(win24(:,1));
    y1 = round(win24(:,2));
    w = win24(:,3);
    x2 = round(x1 + w);
    y2 = round(y1 + w);
    x2(x2>oh) = oh;
    y2(y2>ow) = ow;
    x1(x1<1) = 1;
    y1(y1<1) = 1;
    process48_im = im2single(origin_im);
    im48 = single(zeros(48,48,3,s(1)));
    parfor i=1:s(1)
        im48(:,:,:,i) = imresize(process48_im(x1(i):x2(i),y1(i):y2(i),:),[48 48]);
    end
    %----------------------norm
    im48 = bsxfun(@minus,im48,net48.imageMean);
    %-----------------------48net------------------
    res48 = vl_simplenn(net48, im48) ;
    X = res48(end).x;
    E = exp(bsxfun(@minus, X, max(X,[],3))) ;
    L = sum(E,3) ;
    Y = bsxfun(@rdivide, E, L) ;
    res48_last = reshape(Y,2,[]);
    %  X = reshape(X,2,[]);
    chosen = res48_last(1,:) > bias48;
    value = res48_last(1,:);
    % chosen = X(1,:)>300;
    % value = X(1,:);
    value = value(chosen);
    %w = w(chosen);
    %w = w';
    win24 = win24(chosen,:);
    boxes48_temp = [win24(:,1),win24(:,2),win24(:,1)+win24(:,3),win24(:,2)+win24(:,3),value'];
    if(~isempty(boxes48_temp))
        boxes48 = cat(1,boxes48,boxes48_temp);
    end
end

if isempty(boxes48)
    disp('no48face');
    boxes=[];
    return;
end

%fprintf('after24:%d\n',zzd_24);
%--------------------global nms------------

pick = nms(boxes48,0.49);
boxes48= boxes48(pick(:),:);
%}

value = boxes48(:,5);
w = boxes48(:,3)-boxes48(:,1);
%-----------------------48net-c---------------
s = size(boxes48);
x1 = boxes48(:,1);
y1 =boxes48(:,2);
x2 = boxes48(:,3);
y2 = boxes48(:,4);
x2(x2>oh) = oh;
y2(y2>ow) = ow;
x1(x1<1) = 1;
y1(y1<1) = 1;
process48_cim = im2single(origin_im);
cim48 = single(zeros(48,48,3,s(1)));
parfor i=1:s(1)
    cim48(:,:,:,i) = imresize(process48_cim(round(x1(i)):round(x2(i)),round(y1(i)):round(y2(i)),:),[48 48]);
end
%----------------------norm
data2 = cim48;
data2 = data2-net48_c.imageMean;
cim48 = data2;

res48c = vl_simplenn(net48_c, cim48) ;
X = res48c(end).x;
E = exp(bsxfun(@minus, X, max(X,[],3))) ;
L = sum(E,3) ;
Y = bsxfun(@rdivide, E, L) ;
res48c_last = reshape(Y,45,[]);

win48(:,1) = boxes48(:,1);
win48(:,2) = boxes48(:,2);
win48(:,3) = w;
win48(:,4) = value;
for i = 1:length(w)
    res48_mask = find(res48c_last(:,i)>thres48);
    if(~isempty(res48_mask))
        meanx = sum(chang(:,res48_mask),2)/size(res48_mask,1);
        xn = meanx(1);%w
        yn = meanx(2);%h
        sn = meanx(3);
        wii = w(i);
        center_x = win48(i,1)+wii/2;
        center_y = win48(i,2)+wii/2;
        center_x = center_x - yn*wii/sn;
        center_y = center_y - xn*wii/sn;
        win48(i,3) = wii/sn;
        win48(i,1) = center_x - win48(i,3)/2;
        win48(i,2) = center_y - win48(i,3)/2;
    end
end
boxes48 = [win48(:,1),win48(:,2),win48(:,1)+win48(:,3),win48(:,2)+win48(:,3),win48(:,4)];
%
pick = nms(boxes48,0.25);
win48 = win48(pick(:),:);
%-----------------------------show
%imshow(origin_im);
if isempty(win48)
    disp('noface');
    return;
else
    s = size(win48);
    x1 = round(win48(:,1));
    y1 = round(win48(:,2));
    w = win48(:,3);
    x2 = round(x1 + w);
    y2 = round(y1 + w);
    %x2(x2>oh) = oh;
    %y2(y2>ow) = ow;
    % x1(x1<1) = 1;
    %y1(y1<1) = 1;
    boxes = [x1,y1/tt,x2,y2/tt,win48(:,end)];
    %{
    for i=1:s(1)
        rectangle('Position',[y1(i)/tt,x1(i),(y2(i)-y1(i))/tt,x2(i)-x1(i)],'LineWidth',2,'EdgeColor','b');
    end
    %}
end