clear

load spTrigAve.mat
res = bsxfun(@minus,spTrigAve,spTrigAve(1,:));
res = res(2:end,:);

% for i = 1:400
%     % figure(i)
%     imdata(:,:,i) = reshape(res(i,:),512,128)';
%     % imagesc(imdata(:,:,i),[-200 500])
% end

%%
t = Tiff('myfile2.tif','w');

for i = 1:400
    
    % temp = imdata(:,:,i);
    temp = reshape(res(i,:),512,128)';
    temp = temp + 2^15;
    temp = uint16(temp);
    
    setTag(t,'ImageLength',128)
    setTag(t,'ImageWidth',512)
    setTag(t,'Photometric',Tiff.Photometric.MinIsBlack)
    setTag(t,'BitsPerSample',16)
    setTag(t,'SamplesPerPixel',1)
    setTag(t,'Compression',Tiff.Compression.None)
    setTag(t,'RowsPerStrip',8)
    setTag(t,'PlanarConfiguration',Tiff.PlanarConfiguration.Chunky)
    % setTag(t,'Software','MATLAB')
    
    write(t,temp);
    writeDirectory(t);
    
end
close(t)

