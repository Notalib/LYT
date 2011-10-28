function PlayOrPause()
{

    try
    {
        
        if(Player.player.paused)
        {
             Player.isUserEvent = true;
             Player.userPaused = false;
             
             if(rememberSoundFile.length > 0) //if the user jumped in text, whitout sound -> rember soundfile..
             {
                GetSound(rememberSoundFile[0], rememberSoundFile[1], rememberSoundFile[2]);
                rememberSoundFile.length = 0; //nulstil array
             }
             else
             {
             
                Player.player.play();
             }
             
        }
        else
        {
            Player.isUserEvent = true;
            Player.userPaused = true;
            Player.player.pause();   
        }
        
    }
    catch(e)
    {
        alert(e.message);
    }

}


function FF()
{
    if (Player.player.playbackRate != undefined) 
    {
        if (Player.player.playbackRate == Player.player.defaultPlaybackRate) 
        {
            try 
            {
                
                Player.player.playbackRate = 2; 
                
            }
            catch (err) 
            {
                alert("kunne ikke spole frem i dette medie");
            }
        }
        else
        {
            try 
            {
                Player.player.playbackRate = Player.player.defaultPlaybackRate; 
            }
            catch(err)
            {
                alert("kunne ikke indstile playbackrate frem i dette medie");
            }
                    
        }
            
    }
    

}

function FR()
{
    if (Player.player.currentTime != undefined) 
    {
        try 
        {
   
            Player.player.currentTime += -5;
                        
        }
        catch (err) 
        {
            alert("kunne ikke spole tilbage i dette medie");
        }
            
    
    }


}

function NextPart()
{
    try
    {
        clearInterval(Player.BeginPolling);//DONT ASK FOR END TIME...
        Pause();
        
         
        if(audioTagList.length > 0)//more audiotags to one text element
        {
            audioTagList.shift();
        }
        if(textTagList.length > 0)// more text paragrafs....
        {
            
            
            
            var aTextTag = textTagList.shift();
            GetAllTheText = false;
            
            GetTextAndSoundPiece(aTextTag.getAttribute("id"),smilCacheTable[currentSmilFile]);
        }
        else if( nextAElement != null)
        {
            
            GetTextAndSound(nextAElement);//next part is under next ncc-point....
        }
        
    }
    catch(e)
    {
        alert(e.message);
    }
    

}
function LastPart()
{
    try
    {
        //alert("hallo");
        
        //alert(tempTextList.length + "start");
        //alert(textTagList.length + "start text");
        clearInterval(Player.BeginPolling);//DONT ASK FOR END TIME...
        Pause();
        
        if(textTagList.length == tempTextList.length -1) //first paragraph on page -> go back on ncc point
        {
            if( currentAElement.getAttribute("xhref") == PLAYLIST[0].getAttribute("xhref")) //PLAYLIST[i] is defined in filerInterface files
            {
                alert("call GUI to show message - reached start of book");
            }
            else
            {
                
                Player.LastPartNCCJump = true;
                LastNCC();//skal finde sidste punkt
            
                //alert(textTagList.length);
                
                //console.log(tempTextList);
                //console.log(textTagList);
                
                for(var i = 0; i < tempTextList.length; i++)
                {
                    textTagList.shift();//remove text peaces as they were read
                }
                //alert(textTagList.length + " textTagList efter shift");
            
                GetTextAndSoundPiece(tempTextList[tempTextList.length-1].getAttribute("id"),smilCacheTable[currentSmilFile]);
            }
            //alert("før");
            
        }
        else
        {
            if( textTagList.length == 0) //last element
            {
            
                textTagList.unshift(tempTextList[tempTextList.length-1]);//put back the last text part...
                GetTextAndSoundPiece(tempTextList[tempTextList.length-2].getAttribute("id"),smilCacheTable[currentSmilFile]);
            
            }
            else
            {
                    //alert(tempTextList.length);
                    //alert(textTagList.length);
                    //alert(textTagList[0].getAttribute("src"));
                for(var i = 0; i < tempTextList.length; i++)
                {
           
                    if(textTagList[0]==tempTextList[i])
                    {
                        if(i > 1)
                        { 
                    
                        
                        textTagList.unshift(tempTextList[i-1]);//put back the last text part...
                        GetTextAndSoundPiece(tempTextList[i-2].getAttribute("id"),smilCacheTable[currentSmilFile]);
                        }
                    }
                }
            }
        }
        
    }
    catch(e)
    {
        alert(e.message);
    }


}


function NextNCC()
{
    try
    {
        GetTextAndSound(nextAElement);
    }
    catch(e)
    {
        alert(e.message);
    }
}

function LastNCC()
{

    try
    {
        var temp = GetLastAElement(currentAElement);
        if(temp != null)
        {
            
            GetTextAndSound(temp); //  currentAElement 
        }
    }
    catch(e)
    {
        alert(e.message);
    }

}




