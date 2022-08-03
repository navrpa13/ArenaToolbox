function printSetts(varargin)  %saves charts with Stims visualised for priting, right now for porto version,
                              %later intended for differt input formats

for k=1:numel(varargin) %check format and read settings
    
   if isdouble(varargin{k})&&(numel(varargin{k})==7) %old DIPS version format
       
       lc=varargin{k}(1,2);
       rc=varargin{k}(1,4);
       settings{k}.contacts=[0==lc;1==lc;2==lc;3==lc,0==rc;1==rc;2==rc;3==rc];
       settings{k}.amp.left=varargin{k}(1,3);
       settings{k}.amp.right=varargin{k}(1,5);
       
   else 
       error('Wrong format of setts')
       
   end
   
end


       
    
   
   

    






















function pic = blueCircles(pic,diameter,varargin) %draws blue circles with red alinement, last argument is a list of centers

[r,c]=size(pic);

for ii=1:numel(varargin)
    
    for jj=1:c
        
        for yy=1:r
            
            if (yy-varargin{ii}(1))^2+(jj-varargin{ii}(2))^2<((diameter/2)^2+40)
                pic(jj,yy,1)=150;
                pic(jj,yy,2)=0;
                pic(jj,yy,3)=0;
                
            end
            
            if (yy-varargin{ii}(1))^2+(jj-varargin{ii}(2))^2<(diameter/2)^2
                pic(jj,yy,1)=0;
                pic(jj,yy,2)=0;
                pic(jj,yy,3)=150;
                
            end
            
        end
    end
end

end
                

