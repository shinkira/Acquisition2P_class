clear

load traceDen.mat

dF = traceDen;

% create kernel
kernel_length = 100;
hw = kernel_length/2; % a half width of the kernel

if 1
    % boxcar tilter
    bin_size = 10; % time bin (ms)
    kernel = zeros(1,kernel_length);
    kernel(hw-bin_size/2+1:hw+bin_size/2) = 1/bin_size;
else
    % alpha function
    t_k = -hw:hw;
    alpha = 0.002; % mimicking GCaMP6m
    % alpha = 0.1;
    kernel = alpha.^2.*t_k.*exp(-alpha.*t_k);
    kernel = kernel.*(t_k>=0); % rectitication
    kernel(t_k<0) = 0;
end

figure(1)
for ri = 1:size(dF,1)
    sig = dF(ri,:);
    temp = conv(sig,kernel);
    dFs(ri,:) = temp(kernel_length/2:end-kernel_length/2-1);
    subplot(6,1,ri); hold on
    % plot(t_axis,F(1,:),'r-')
    plot(dFs(ri,:),'r-')
end
set(gcf,'position',[300 300 1500 1000])

return
