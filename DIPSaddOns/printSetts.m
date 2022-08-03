function pics = printSetts(name,varargin)  %saves charts with Stims visualised for priting, right now for porto version,
                              %later intended for differt input formats
                              
    settings=cell(1,numel(varargin));                          

for k=1:numel(varargin) %check format and read settings
    
   if isnumeric(varargin{k})&&(numel(varargin{k})==7) %old DIPS version format
       
       lc=varargin{k}(1,3);
       rc=varargin{k}(1,6);
       settings{k}.contacts=[3==rc 3==lc;2==rc 2==lc;1==rc 1==lc; 0==rc 0==lc];
       settings{k}.amp.left=varargin{k}(1,4);
       settings{k}.amp.right=varargin{k}(1,7);
       
   else 
       error('Wrong format of setts')
       
   end
   
   
   
   
end



centers={[725,393] [720,1203];[795,393] [790,1203];[860,393] [860,1203];[930,392] [930,1203]}; %approximate centers of contacts in the template

template=imread('chartTemplate.png');

pics=cell(1,numel(varargin));


for iSett=1:numel(varargin)
    
    contacts=centers(settings{iSett}.contacts);
    pics{iSett}=blueCircles(template,40,contacts);
    
    % writing into the picture using mask - hell on earth 
    %I don´t understand why you have to pay to get such a simple function
    %as insertText...if you know how to do it better, please tell me, this
    %sucks, I know
    
    
    
    figure(2) 
    image(ones(size(template)));
    
   
    text('units','pixels','position', [160 320], 'fontsize',30,'string',name)
    text('units','pixels','position', [10 30], 'fontsize',20,'string',num2str(settings{k}.amp.right))
    text('units','pixels','position', [375 30], 'fontsize',20,'string',num2str(settings{k}.amp.left))
    text('units','pixels','position', [40 30], 'fontsize',20,'string','mA')
    text('units','pixels','position', [405 30], 'fontsize',20,'string','mA')
    text('units','pixels','position', [15 320], 'fontsize',20,'string',num2str(iSett))
    
    
    f=getframe(gca);
    close(2)
    mask=imresize(f.cdata, size(template, [1 2]));
    mask=~logical(mask);
    pics{iSett}(mask)=0;
    
end
    
%now works just with mA, to be continued 
    
    
    
    
    
    
    
    
    
    


       
    
   
   

    






















function pic = blueCircles(pic,diameter,cents) %draws blue circles with red alinement, last argument is a list of centers

[r,c]=size(pic);

for ii=1:numel(cents)
    
    for jj=1:c
        
        for yy=1:r
            
            if (yy-cents{ii}(1))^2+(jj-cents{ii}(2))^2<((diameter/2)^2+40)
                pic(yy,jj,1)=150;
                pic(yy,jj,2)=0;
                pic(yy,jj,3)=0;
                
            end
            
            if (yy-cents{ii}(1))^2+(jj-cents{ii}(2))^2<(diameter/2)^2
                pic(yy,jj,1)=0;
                pic(yy,jj,2)=0;
                pic(yy,jj,3)=150;
                
            end
            
        end
    end
end

end

end
                

