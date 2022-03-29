function [first_choice, alternative] = findDIPSsettings(TH)

function [best_choice] = findBESTchoice(th)
    
    th=sortrows(th,1,'descend'); %orders according to impro
    
if th(1,2)>0.7&& th (1,5)>0.7  %if both confidences are over 70% take the best ipro. sett.
    best_choice = th(1,:);
    
elseif [[th(:,2)>0.54]&[th(:,5)>0.54]]==[th(:,2)<0] %if there´s no sett. with conf. over 0.54
    best_choice = [0,0,0,0,0,0,0];
    
else                                               %otherwise find compromise between confidence and impro.
    X=repmat([[th(:,2)>0.54]&[th(:,5)>0.54]],1,7);
    relth=th.*X;
    for ii=1:size(relth,1)
        relth(ii,8)=((relth(ii,2)+relth(ii,5))*relth(ii,1));
    end
    
        
    relth=sortrows(relth,8,'descend');
    best_choice=relth(1,1:7);
    
end
end

first_choice=findBESTchoice(TH); %finds best choice


    
    if first_choice==[0,0,0,0,0,0,0]; 
        alternative=[0,0,0,0,0,0,0];
    else
        
    A=[[TH(:,3)]>first_choice(1,3)]&[[TH(:,6)]>first_choice(1,6)]; %selects sett. with both contacts more prox.
    
    if sum(A)==0
        B=[[TH(:,3)]>first_choice(1,3)]|[[TH(:,6)]>first_choice(1,6)]; %at least one more prox.
        if sum(B)==0
            C=[[TH(:,4)]>first_choice(1,4)]&[[TH(:,7)]>first_choice(1,7)]; %both have lower amplitude
            if sum(C)==0
                D=[[TH(:,4)]>first_choice(1,4)]|[[TH(:,7)]>first_choice(1,7)]; %one has lower amp.
                if sum (D)==0
                    alternative=[0,0,0,0,0,0,0];
                else
                    D=repmat(D,1,7);
                    relTH=TH.*D;
                    alternative=findBESTchoice(relTH);
                end
            else 
                C=repmat(C,1,7);
                relTH=TH.*D;
                alternative=findBESTchoice(relTH);
            end
        else
            B=repmat(B,1,7);
            relTH=TH.*B;
            alternative=findBESTchoice(relTH);
        end
    else
        A=repmat(A,1,7);
        relTH=TH.*A;
        alternative=findBESTchoice(relTH);
    end
    end
end

                    
                    
                
               
               
            
        
       
    
    
        
       
        
        
        
  
        
  
       
    

    
    
    
    
    

    
        
    
    
    
    
   
    