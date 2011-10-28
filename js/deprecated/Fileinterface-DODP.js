/**
 * Fileinterface-DODP.js
 * Interaction with DAISY ONLINE Protocol
 */
 
//GLOBAL VARIABLES
var USER_REALNAME;     
var text_window = document.createElement("div");

var PLAYLIST; //NCC entries in current book
var DODPUriTransLate; //Translatebook
var smilCacheTable; // smil-buffer
var smilNamesToBeAdded = new Array(); //cache array for .smil names
var rememberSoundFile = new Array(); //Current pos in soundfile (used when jumping in NCC without sound)
var htmlCacheTable; //html files in book

var firstHtmlFilePart = "";
var sizeOfFirstHtmlFilePart = 65536; //64KB
var GotBookFired = false;

var audioTagList = new Array();//taglist of audiotags belonging to on <text> </text> tag
var textTagList = new Array();

var smilFilesInBuffer = 0;
var smilCacheSize = 10;
var smilFilesToCache = 3;
var smilCacheError = false;
var smilCacheTrigger = smilCacheSize - 3;//cache when you reach the secondlast in cache

var currentSmilFile =""; //Global smilfile
var currentAElement;
var nextAElement;
var nextSoundFileName ="";//name of nextsoundfilename...
var currentTimeInSmil = "";
var totalsec = 0;


var MaxBooksInlocalStorage = 20;

var HighLightColor ="HighLightColor";
var TOCHighLightColor = "TOCHighLightColor";
var GetAllTheText;


var clipBegin;
var clipEnd;
var GlobalCount = 0;
var soundfilename = "";
var tempTextList;

//DODP
var DODP_DEFAULT_TIMEOUT = 30000;
var DODP_URL = '/DodpMobile/Service.svc';
var SERVICE_ANNOUNCEMENTS = false; //if the service supports sevice announcements
var SHOW_SERVICE_ANNOUNCEMENTS = false;

var soapTemplate = "<?xml version='1.0' encoding='UTF-8'?><SOAP-ENV:Envelope xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:ns1='http://www.daisy.org/ns/daisy-online/'><SOAP-ENV:Body>${soapBody}</SOAP-ENV:Body></SOAP-ENV:Envelope>"
 
var Player = new Player(this.document);

// who paused? system or UI - should be rewritten to JQUERY
//if (this.document.addEventListener){
	//this.document.addEventListener('systemPause', eventSystemPaused, false);
//} else if (this.document.attachEvent){
  //this.document.attachEvent('systemPause', eventSystemPaused, false);
//}



//CALLBACK FUNCTIONS


function LogOnCallBack(response)
{
	//DEBUG THIS RESPONSE: 
	if(window.console) console.log('PRO: Log on callback');	
    if($(response).find("logOnResult").text() == 'true')
    {
	    //next step in DODP handshake..gets information about the service provider....		
      	GetServiceAttributes(); 
    }
    else
    {
		eventSystemForceLogin('Du har indtastet et forkert brugernavn eller password');
    }
}


function OnError(jqXHR, textStatus, errorThrown)
{
	if(window.console) console.log('PRO: Error: ',jqXHR);
	if(jqXHR.responseText=='undefined' || jqXHR.responseText==null ){
    	if(window.console)console.log(errorThrown);
		if(window.console)console.log(jqXHR);
    	return;
	}
	if(jqXHR.responseText.indexOf('Session is invalid')>0 || jqXHR.responseText.indexOf('Session is uninitialized')>0){
		eventSystemNotLogedIn();
	}else{
    	if(window.console)console.log(errorThrown + jqXHR.responseText);
		if(window.console)console.log(jqXHR);
	}
}

function LogOncompleteCallBack()
{
}

function LogOffCallBack(response)
{
	if(window.console)console.log('PRO: LogOff...');
	if($(response).find("logOffResult") != null)
	{
		eventSystemLogedOff($(response).find("logOffResult").text());
	}




}
function LogOffcompleteCallBack()
{
}



//DETERMINE DODP SERVICE ATTRIBUTES
//FOR NOW THE FUNCTION ONLY IMPLEMENTS SERVICE ANNOUNCEMENTS 
function GetServiceAttributesCallBack(response)
{
	//DEBUG THIS RESPONSE: 
	if(window.console) console.log('PRO: Service attributtes callback');
    var p = $(response).find("supportedOptionalOperations");   
    $(p).find("operation").each(function()
    {
         if($(this).text() == "SERVICE_ANNOUNCEMENTS")
         {
            SERVICE_ANNOUNCEMENTS = true;
         }
    });
    //next step in DODP handshake..sets information about the reading client....
    SetReadingSystemAttributes(); 
}


function GetServiceAttributescompleteCallBack()
{
}
function SetReadingSystemAttributesCallBack(response)
{
	//DEBUG THIS RESPONSE: 
	if(window.console) console.log('PRO: Set reading system attributes callback	');
    if($(response).find("setReadingSystemAttributesResult").text() == 'true')
    {
		//DISPLAY SERVICEANNOUNCEMENTS IF NESCESSARY - RIGHT NOW SET TO FALSE
		if(SERVICE_ANNOUNCEMENTS && SHOW_SERVICE_ANNOUNCEMENTS)
        {
            GetServiceAnnouncements();
        }        
        //DECLARE SYSTEM LOG IN EVENT TO GUI
        eventSystemLogedOn(true,$(response).find('MemberId').text()); //calling GUI function
    }
    else
    {
        alert(aLang.Translate("MESSAGE_LOGON_FAILED"));
    }
}


function SetReadingSystemAttributescompleteCallBack()
{      
}


function GetServiceAnnouncementsCallBack(response)
{
    var p = $(response).find("announcements");
    $(p).find("announcement").each(function()//text and/or audio
    {
        alert($(this).find("text").text());
        MarkAnnouncementsAsRead($(this).attr("id"));
    });

}

function GetServiceAnnouncementscompleteCallBack()
{

}

function MarkAnnouncementsAsReadCallBack(response)
{




}

function MarkAnnouncementsAsReadcompleteCallBack()
{

}

function GetContentListCallBack(response)
{
	//DEBUG THIS RESPONSE:
	if($(response).find('faultstring').text()=='Session is invalid' || $(response).find('faultstring').text()=='Session is uninitialized' || $(response).find('faultstring').text()=='Session has not been initialized' )
	{
			if(window.console) console.log('PRO: Boghylde callback	fejl: ikke logget på, kalder eventSystemNotLogedIn');
			eventSystemNotLogedIn();
	 }else{
			if(window.console) console.log('PRO: Boghylde callback	');
    		eventSystemGotBookShelf(response);  
	 }
}

function GetContentListcompleteCallBack()
{


}

function IssueContentCallBack(response)
{
	//DEBUG THIS RESPONSE:
	if(window.console) console.log('PRO: IssuecontentCallback ...');
	if($(response).find('faultstring').text()=='Session is invalid')
	{
			eventSystemNotLogedIn();
	 }else{
	 	if($(response).find('issueContentResult').text()=='true'){
				GetContentResources(settings.currentBook);
		}else{
			alert($(response).find('faultcode').text() + ' - ' + $(response).find('faultstring').text());
		}
	 }
}

function IssueContentcompleteCallBack()
{
}

function ReturnContentCallBack(response)
{
	//DEBUG THIS RESPONSE:
	if(window.console) console.log('PRO: ReturncontentCallback ...');
	if($(response).find('faultstring').text()=='Session is invalid')
	{
			eventSystemNotLogedIn();
	 }else{
	 	if($(response).find('returnContentResult').text()=='true'){
				GetBookShelf();
		}else{
			alert($(response).find('faultcode').text() + ' - ' + $(response).find('faultstring').text());
		}
	 }
}

function ReturnContentcompleteCallBack()
{
}
function GetContentMetadataCallBack(response)
{



}
function GetContentMetadatacompleteCallBack()
{


}

function GetContentResourcesCallBack(response)
{
	//DEBUG THIS RESPONSE:
	if(window.console) console.log('PRO: Get content resources callback  - Bog ressourcer',response);
	
	//Empty variables
  	InitSystem(); //clear buffers and other variables....
    var nccPath=""; 

	//GETTING BOOK FILE RESSOURCES
	if($(response).find('faultstring').text()==""){
		$(response).find("resource").each(function()
		{
		    var aHost = window.location.hostname;
		    var dodpHost = $(this).attr("uri");
		
		    var aProtocol = dodpHost.substring(0, dodpHost.indexOf("/")+2 );
		    dodpHost = dodpHost.substring(dodpHost.indexOf("/")+2);
		    dodpHost = dodpHost.substring(dodpHost.indexOf("/")); 
	
			//INSERT RELATIVE / ABSOLUTE VALUES IN DODPURITRANSLATE ARRAY
		    DODPUriTransLate[$(this).attr("localURI")] = aProtocol +aHost +dodpHost;     
		
			//WHEN WE FIND THE NCC FILE, BUILD THE INDEX TREE AND TELL INTERFACE TO START PLAYING
			var temp = $(this).attr("uri"); 
		    if (temp.indexOf("ncc.htm") != -1 && temp.substring(temp.length-4,temp.length)!=".bak")
		    {        	        
				nccPath = aProtocol +aHost +dodpHost;
		    }
	    });
	   }else
	   {
			if($(response).find('faultcode').text() == "s:invalidParameterFault")
			{
				alert($(response).find('faultstring').text());
				eventSystemEndLoading();
			}
			else
			{
				alert('Fejl i contenresourcescallback: ' + $(response).find('faultstring').text());
			}
	   }
	//BOOLEAN FOR LATER USE - TO TELL INTERFACE TO BEGIN PLAYING
	GotBookFired = false;
    //see if localstorage is available
    if (!supports_local_storage()) 
    { 
        CreateList(nccPath);
    }
    else
    {
        try
        {
            book_tree = localStorage.getItem("NCC/" + settings.currentBook);
			//check for invalid data....
            if(book_tree == null || book_tree == undefined || (book_tree.indexOf("ol") == -1) )
            {  
               CreateList(nccPath);
                try 
                {
                   if(localStorage.length > MaxBooksInlocalStorage)
                   {           
                        DeleteNccFromLocalStorage();
                   }
                   //saves to the database, "key", "value"
		          localStorage.setItem("NCC/" + settings.currentBook, book_tree); 
                } 
                catch (e) 
                {
                    if (e == QUOTA_EXCEEDED_ERR) 
                    {
                        //data wasn't successfully saved due to quota exceed so throw an error
	 	 	            localStorage.clear();	 	 	            
                    }
                 }
	        }  
        }
        catch (e) 
        {
            //error get ncc from server
            alert('Error on retrieve NCC');
             
        }
    }
    	// cache smilfiles and textfiles
    	//sometimes PLAYLIST a string from localstoage...sooooo...need to make XML list here
	    if (window.DOMParser)
	    {
	        try
	        {
	            var parser = new DOMParser();
	            doc = parser.parseFromString(book_tree,"text/xml");
				
		
	        }
	        catch(e)
	        {
	            alert(e.message);
	        }
	    }
	    else // Internet Explorer
	    {
	        doc=new ActiveXObject("Microsoft.XMLDOM");
	        doc.async="false";
	        doc.loadXML(book_tree); 
	    }
	PLAYLIST = doc.getElementsByTagName("li");
	PrePareSmilNames(PLAYLIST[0],smilCacheSize);
	//finding smilfilenames in <ol>
	//async method for caching smilfiles and first htmlFile
   	CacheSmilFiles(); 
}

function GetContentResourcescompleteCallBack()
{
}


function SetBookmarksCallBack()
{
}

function SetBookmarkscompleteCallBack()
{
}









       

///////////////////////////////////////////////Daisy Online CallBack functions - END///////////////////////////////////////////////////////////

//FUNCTIONS

function LogOff()
{
    var logOff_Soap = "<ns1:logOff></ns1:logOff>";
    
    $.ajax( { 
            url: DODP_URL,
            headers:{'SOAPAction':['/logOff']},
            type: "POST",
            processData: true,
            contentType: "text/xml; charset=utf-8",
            timeout: DODP_DEFAULT_TIMEOUT,
            dataType: "xml",
            data: soapTemplate.replace("${soapBody}",logOff_Soap),
            cache: false,
            success: LogOffCallBack,
            error: OnError,
            complete: LogOffcompleteCallBack
	});   
}




function LogOn(username,password)
{
	if(window.console)console.log('PRO: Log on: ' + username + ' | ' + password);
    var logOn_Soap = "<ns1:logOn><ns1:username>"+username +"</ns1:username><ns1:password>"+password +"</ns1:password></ns1:logOn>";
    
    $.ajax( { 
            url: DODP_URL,
            headers:{'SOAPAction':['/logOn']},
            type: "POST",
            processData: true,
            contentType: "text/xml; charset=utf-8",
            timeout: DODP_DEFAULT_TIMEOUT,
            dataType: "xml",
            data: soapTemplate.replace("${soapBody}",logOn_Soap),
            cache: false,
            success: LogOnCallBack,
            error: OnError,
            complete: LogOncompleteCallBack
	});   
}

function GetServiceAttributes()
{
     var serviceAttributes_Soap = "<ns1:getServiceAttributes/>";
     $.ajax( { 
            url: DODP_URL,
            headers:{'SOAPAction':['/getServiceAttributes']},
            type: "POST",
            contentType: "text/xml; charset=utf-8",
            timeout: DODP_DEFAULT_TIMEOUT,
            dataType: "xml",
            data: soapTemplate.replace("${soapBody}",serviceAttributes_Soap),
            cache: false,
            success: GetServiceAttributesCallBack,
            error: OnError,
            complete: GetServiceAttributescompleteCallBack
        });   
}

function SetReadingSystemAttributes()
{
     var readingSystemAttributes_Soap = "<ns1:setReadingSystemAttributes><ns1:readingSystemAttributes><ns1:manufacturer>NOTA</ns1:manufacturer><ns1:model>LYT</ns1:model><ns1:serialNumber>1</ns1:serialNumber><ns1:version>1</ns1:version><ns1:config></ns1:config></ns1:readingSystemAttributes></ns1:setReadingSystemAttributes>";

     $.ajax( { 
                url: DODP_URL,
                headers:{'SOAPAction':['/setReadingSystemAttributes']},
                type: "POST",
                contentType: "text/xml; charset=utf-8",
                timeout: DODP_DEFAULT_TIMEOUT,
                dataType: "xml",
                data: soapTemplate.replace("${soapBody}",readingSystemAttributes_Soap),
                cache: false,
                success: SetReadingSystemAttributesCallBack,
                error: OnError,
                complete: SetReadingSystemAttributescompleteCallBack
            });   
}

function GetServiceAnnouncements()
{

    var getServiceAnnouncements_Soap = "<ns1:getServiceAnnouncements/>";

     $.ajax( { 
                url: DODP_URL,
                headers:{'SOAPAction':['/getServiceAnnouncements']},
                type: "POST",
                processData: true,
                contentType: "text/xml; charset=utf-8",
                timeout: DODP_DEFAULT_TIMEOUT,
                dataType: "xml",
                data: soapTemplate.replace("${soapBody}",getServiceAnnouncements_Soap),
                cache: false,
                success: GetServiceAnnouncementsCallBack,
                error: OnError,
                complete: GetServiceAnnouncementscompleteCallBack
            });   



}


function MarkAnnouncementsAsRead(aId)
{
     
     var MarkAnnouncementsAsRead_Soap = "<ns1:markAnnouncementsAsRead><ns1:read><ns1:item>"+aId+"</ns1:item></ns1:read></ns1:markAnnouncementsAsRead>";

     $.ajax( { 
                url: DODP_URL,
                headers:{'SOAPAction':['/markAnnouncementsAsRead']},
                type: "POST",
                contentType: "text/xml; charset=utf-8",
                timeout: DODP_DEFAULT_TIMEOUT,
                dataType: "xml",
                data: soapTemplate.replace("${soapBody}",MarkAnnouncementsAsRead_Soap),
                cache: false,
                success: MarkAnnouncementsAsReadCallBack,
                error: OnError,
                complete: MarkAnnouncementsAsReadcompleteCallBack
            });   

}

function GetContentList(listName,firstItem,lastItem)
{
	if(window.console) console.log('PRO: Henter boghylde...');
    var GetContentList_Soap = "<ns1:getContentList><ns1:id>" +listName+ "</ns1:id><ns1:firstItem>"+firstItem+"</ns1:firstItem><ns1:lastItem>"+lastItem+"</ns1:lastItem></ns1:getContentList>";
    
    $.ajax( { 
            url: DODP_URL,
            headers:{'SOAPAction':['/getContentList']},
            type: "POST",
            contentType: "text/xml; charset=utf-8",
            timeout: DODP_DEFAULT_TIMEOUT,
            dataType: "xml",
            data: soapTemplate.replace("${soapBody}",GetContentList_Soap),
            cache: false,
            success: GetContentListCallBack,
            error: OnError,
            complete: GetContentListcompleteCallBack
	});
}


function IssueContent(bookId)
{
	if(window.console) console.log('PRO: Issue content: bookid: ',bookId);
   var IssueContent_Soap = "<ns1:issueContent><ns1:contentID>"+bookId+"</ns1:contentID></ns1:issueContent>";

   $.ajax( { 
            url: DODP_URL,
            headers:{'SOAPAction':['/issueContent']},
            type: "POST",
            contentType: "text/xml; charset=utf-8",
            timeout: DODP_DEFAULT_TIMEOUT,
            dataType: "xml",
            data: soapTemplate.replace("${soapBody}",IssueContent_Soap),
            cache: false,
            success: IssueContentCallBack,
            error: OnError,
            complete: IssueContentcompleteCallBack
	});
}

function ReturnContent(bookId)
{
	if(window.console) console.log('PRO: return content: bookid: ',bookId);
   var ReturnContent_Soap = "<ns1:returnContent><ns1:contentID>"+bookId+"</ns1:contentID></ns1:returnContent>";

   $.ajax( { 
            url: DODP_URL,
            headers:{'SOAPAction':['/returnContent']},
            type: "POST",
            contentType: "text/xml; charset=utf-8",
            timeout: DODP_DEFAULT_TIMEOUT,
            dataType: "xml",
            data: soapTemplate.replace("${soapBody}",ReturnContent_Soap),
            cache: false,
            success: ReturnContentCallBack,
            error: OnError,
            complete: ReturnContentcompleteCallBack
	});
}

function GetContentMetadata(aId)
{

    var ContentMetadata_Soap = "<ns1:getContentMetadata><ns1:contentID>" +aId+"</ns1:contentID></ns1:getContentMetadata>";
 


    $.ajax( { 
                url: DODP_URL,
                headers:{'SOAPAction':['/getContentMetadata']},
                type: "POST",
                processData: true,
                contentType: "text/xml; charset=utf-8",
                timeout: DODP_DEFAULT_TIMEOUT,
                dataType: "xml",
                data: soapTemplate.replace("${soapBody}",ContentMetadata_Soap),
                cache: false,
                success: GetContentMetadataCallBack,
                error: OnError,
                complete: GetContentMetadatacompleteCallBack
            });

}

function GetContentResources(aId)
{
	if(window.console) console.log('PRO: Kalder get content ressources...');
    var ContentResources_Soap = "<ns1:getContentResources><ns1:contentID>" +aId+"</ns1:contentID></ns1:getContentResources>";

   $.ajax( { 
        url: DODP_URL,
        headers:{'SOAPAction':['/getContentResources']},
        type: "POST",
        contentType: "text/xml; charset=utf-8",
        timeout: DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: soapTemplate.replace("${soapBody}",ContentResources_Soap),
        cache: false,
        success: GetContentResourcesCallBack,
        error: OnError,
        complete: GetContentResourcescompleteCallBack
	});
}

function SetBookmarks(aId,BookMarksXml)
{

    var bookmarks_Soap = "<ns1:setBookmarks><ns1:contentID>"+aId+"</ns1:contentID>"+BookMarksXml  +"</ns1:setBookmarks>";

   $.ajax( { 
                url: DODP_URL,
                headers:{'SOAPAction':['/setBookmarks']},
                type: "POST",
                processData: true,
                contentType: "text/xml; charset=utf-8",
                timeout: DODP_DEFAULT_TIMEOUT,
                dataType: "xml",
                data: soapTemplate.replace("${soapBody}",bookmarks_Soap),
                cache: false,
                success: SetBookmarksCallBack,
                error: OnError,
                complete: SetBookmarkscompleteCallBack
            });






}

function GetBookmarksSync(aId) //Get the bookmarks Sync ...importen to get the bookmarks from server if updated by other reading system
{
    //STUB for test
    var bookmarkXml = $('<bookmarkSet>');
    var t = $('<title>');
    
    bookmarkXml.append(t);
    
    var text =  $('<text>');
    
    text.append(aId);
    
    t.append(text);
    
    t.append($('<audio>'));
    
    var uid  = $('<uid>')
    
    uid.append(aId);
    
    bookmarkXml.append(uid);
    
    var last = $('<lastmark>');
    
    bookmarkXml.append(last);
    
    var ncxref = $('<ncxRef>');
    ncxref.append("xyub00066");
    
    last.append(ncxref);
    
    var URI = $('<URI>');
    URI.append("cddw000A.smil#xyub00066");
    
    last.append(URI);
    
    var timeOffset = $('<timeOffset>');
    
    timeOffset.append("00:10.0");
    
    last.append(timeOffset);
    
    
    //alert(Player.player.currentTime);
    //if(window.console) console.log(bookmarkXml);
    
    return bookmarkXml;
    //alert(bookmarkXml.find('title').text());



}

function GetBookmarksASync(aId) //Get the bookmarks ASync ...importen to get the bookmarks from server if updated by other reading system (used in INITIALIZATION)
{

 


}




///////////////////////////////////////////////Daisy Online functions - END///////////////////////////////////////////////////////////


function GetBookShelf()
{
	// from 0 to last item(-1)
	GetContentList("issued","0","-1"); 
}

function GetBook(bookId){
	if(window.console) console.log('PRO: PRO: Getbook: bookid: ',bookId);
    IssueContent(bookId);   
}

function GetBookmarks(aId)
{
   return GetBookmarksSync(aId);
}


function CreateList(urlToBookNcc)
{ 
	console.log('PRO: Creating list from: ' + urlToBookNcc);
	$.ajax( { 
		            url: urlToBookNcc,
		            type: "GET",
		            dataType: "xml",
		            async: false,
		            success: CreateListCallback,
		            error: OnError,
		});
}

function CreateListCallback(xml)
{
		console.log('PRO: Create list callback',xml);
		var string ="";
		var currentlevel = 1;
		var formerlevel = 1;
		var difference = 0;
		var savedforlater;
		var me = "";
		
		var forfatter;
		
		try
		{
		var totalTime = xml.getElementsByName("ncc:totalTime")[0].getAttribute("content");
		
		if(xml.getElementsByName("dc:creator").length != 0) 
		{
				forfatter = xml.getElementsByName("dc:creator")[0].getAttribute("content");
		}
		else
		{
				forfatter = "NN";
		}
		var title = xml.getElementsByName("dc:title")[0].getAttribute("content");
		
		
		
		
		
		
		$(xml).find(":header").each(function(i)
		{	
			currentlevel = this.nodeName.toLowerCase().substr(1,2);
			
			//ALTID ET LI ELEMENT
			me = '<li id="' + $(this).attr('id') + '" xhref="' + $(this).find('a').attr('href') + '">' + $(this).find('a').text() + '</li>';
			
			//SKIFT TIL UNDERNIVEAU
			if(formerlevel - currentlevel < 0) {
				string = string.slice(0,(string.length-5));
				string += '<ol>' + me;
			}
			//SKIFT TIL HØJERE NIVEAU
			if(formerlevel - currentlevel > 0) {
				for(i=0;i<formerlevel-currentlevel;i++){
					string += '</ol></li>';
				}
				string += me;
			}
			//BLIV PÅ SAMME NIVEAU
			if(formerlevel - currentlevel == 0) {
				string += me;
			}
	
			formerlevel = this.nodeName.toLowerCase().substr(1,2);
		});
		//SKIFT EVT TILBAGE TIL NIVEAU 1
		if(currentlevel > 1) {
			for(i=1;i<currentlevel;i++){
				string += '</ol></li>';
			}
		}else{
			string+='</li>';
		}	
		string = '<ul titel="'+title+'" forfatter="' + forfatter + '" totalTime="'+totalTime+'" id="NccRootElement" data-role="listview">' + string + '</ol>';
	   	book_tree = string;
		
		
		}
		catch(e)
		{
			alert(e.message);  
		}

   		if(window.console) console.log('PRO: NCC liste oversat til li...');
 }

function PrePareSmilNames(node,count)
{
	if(window.console)console.log('PRO: Prepare smile names');
   var j = findNode(node,PLAYLIST);
   
   if( j != -1)
   {
    for(var i = j; i < PLAYLIST.length; i++)
    {
        if( (i - j) < count)
        {
          //UrlToBook +
          var temp =   PLAYLIST[i].getAttribute("xhref").substring( PLAYLIST[i].getAttribute("xhref").lastIndexOf("/")+1,PLAYLIST[i].getAttribute("xhref").indexOf("#") );
         
          //BUILDING ARRAY WITH 
          smilNamesToBeAdded.push(temp);

        }
    
    }
   }
}

function DeleteNccFromLocalStorage()
{
    try
    {
        for(var j = 0; j < localStorage.length; j++)
        {
            if(localStorage.key(j).indexOf("NCC/") != -1)
            {
                localStorage.removeItem(localStorage.key(j));//remove the oldest book
                break;
            }
        }
        
    }
    catch(e)
    {
        alert(e.message);   
    }
    

}



/*function GetNcc(url){
   $.ajax( { 
            url: url,
            type: "GET",
            dataType: "xml",
            async: false,
            success: ParseNcc,
            error: OnError,
	});
}

function ParseNcc(xml){
	//DEBUG THIS RESPONSE
	if(window.console) console.log('PRO: ncc',xml);

	$(xml).find('h1 a').each(function(){
		PLAYLIST_STRING += '<li xhref="' + $(this).attr('href') + '>' + $(this).text() + '</li>';
	});
	alert(PLAYLIST_STRING);
	
	
}*/


////////////////////////////////////////////////////////////Cache smil files/////////////////////////////////////////
function CacheSmilFiles()
{
	if(window.console)console.log('PRO: Caching smile files');
    try
	{
	  // Firefox, Opera 8.0+, Safari, Chrome
	  xmlHttp1=new XMLHttpRequest();	  		
	}
	catch (e)
	{
	  	// Internet Explorer
			
	    try
        {
  		    xmlHttp1=new ActiveXObject("Msxml2.XMLHTTP");
   	    }
	  	catch (e)
   	    {
	    		try
	      		{
	      			xmlHttp1=new ActiveXObject("Microsoft.XMLHTTP");
	      		}
	    		catch (e)
	      		{
	      			alert("Your browser does not support AJAX!");
	      			return false;
	      		}
   	    }
	  }
	  xmlHttp1.onreadystatechange=function()
	  {
	   	if(xmlHttp1.readyState==4)
    	{
			
            if( smilNamesToBeAdded.length > 0)// more smilfiles to cache?
            {
	      		if(smilFilesInBuffer >= smilCacheSize) //buffer size
	      		{
		           
                   for (var i = 0; i < smilNamesToBeAdded.length; i++)
	      		   {
	      		       delete smilCacheTable[smilCacheTableGetKey(i)];     //delete smil from buffer
	      		       smilFilesInBuffer--;
	      		   }
	      		}
	      		
      		   
     
                var currentSmilFile = smilNamesToBeAdded.shift();//Removes the first element of an array, and returns that element
                 //console.log( "smilNamesToBeAdded.length" , smilNamesToBeAdded.length);
	      		
	      		try
	      		{
	      		
	      		  
	      		   //alert(currentSmilFile);
	      		   smilCacheTable[currentSmilFile] = xmlHttp1.responseXML;
	      		  
      		   
	      		   //alert(smilCacheTable[currentSmilFile]);
	      		   
	      		   if(xmlHttp1.status != 200)
	      		   {    
	      		      smilCacheTable[currentSmilFile] = -1; //no smil source
	      		   }
	      		   smilFilesInBuffer++;
	      		   if(smilFilesInBuffer==1)//firsttime that we see a smilfile -> get the htmlfile ref
	      		   {
	      		      //console.log( "html file hentes" , smilCacheTable[currentSmilFile]);
	      		       GetHtmlName(smilCacheTable[currentSmilFile]);
	      		   }
	      		   
	      		   CacheSmilFiles();
    		    }
    		    catch(e)
    		    {
    		      //alert(e.message);
    		      smilCacheError = true;    		      
	      		   //problem with cashing smilfiles
	      		}
	      		
	      			
  	        }
        }
      }
	    	
     if( smilNamesToBeAdded.length > 0)
     {
        //alert(DODPUriTransLate[ smilNamesToBeAdded[0] ]);
        if(xmlHttp1.overrideMimeType)
        {     
            xmlHttp1.overrideMimeType('text/xml');
        }
        xmlHttp1.open("GET", DODPUriTransLate[ smilNamesToBeAdded[0] ],true);   	
        xmlHttp1.send(null);//same directory
     
	 }	

}

function CacheSmilFilesSync()
{
    try
	{
	  // Firefox, Opera 8.0+, Safari
	  xmlHttp3=new XMLHttpRequest();
	  		
	}
	catch (e)
	{
	  	// Internet Explorer
			
	    try
        {
  		    xmlHttp3=new ActiveXObject("Msxml2.XMLHTTP");
   	    }
	  	catch (e)
   	    {
	    		try
	      		{
	      			xmlHttp3=new ActiveXObject("Microsoft.XMLHTTP");
	      		}
	    		catch (e)
	      		{
	      			alert("Your browser does not support AJAX!");
	      			return false;
	      		}
   	    }
	  }
	  
     if( smilNamesToBeAdded.length > 0)
     {
        //alert(smilNamesToBeAdded[0]);
         //smilNamesToBeAdded[0] ],true);
        if(xmlHttp3.overrideMimeType)
        {     
            xmlHttp3.overrideMimeType('text/xml');
        }   	
        xmlHttp3.open("GET",DODPUriTransLate[ smilNamesToBeAdded[0] ],false);   	
        xmlHttp3.send(null);//same directory
        
        
        if(smilFilesInBuffer >= smilCacheSize) //buffer size
   		{
		           
             for (var i = 0; i < smilNamesToBeAdded.length; i++)
		     {
	      		 delete smilCacheTable[smilCacheTableGetKey(i)];     //delete smil from buffer
 		         smilFilesInBuffer--;
  		     }
                    
	      		   
   		}
	      		
      		   
     
        var currentSmilFile = smilNamesToBeAdded.shift();//Removes the first element of an array, and returns that element
                    
     
   		try
   		{
	      		   //alert(xmlHttp.responseText);
		   smilCacheTable[currentSmilFile] = xmlHttp3.responseXML;
	      		   //alert(xmlHttp.status);
		   if(xmlHttp3.status != 200)
		   {    
                smilCacheTable[currentSmilFile] = -1; //no smil source
		   }
		   smilFilesInBuffer++;
		   if(smilFilesInBuffer==1)//firsttime that we see a smilfile -> get the htmlfile ref
		   {
                GetHtmlName(smilCacheTable[currentSmilFile]);
		   }
	    }
	    catch(e)
	    {
            smilCacheError = true;
	    }
        
        
        
     
	 }

        


}



function smilCacheTableGetKey(aIndex)
{
    var i = 0;
                            
    for(var n in smilCacheTable)
    {
        //alert(n);
        if(i == aIndex)
        {
            return n;
        }
        i++;

    }

}


function smilCacheTableGetIndex(aKey)
{

    var i = 0;
                            
    for(var n in smilCacheTable)
    {
        //alert(n);
        if(n == aKey)
        {
            return i;
        }
        i++;

    }
}



function findNode(node,list)
{
    var returnV = -1;
    try
    {
       
        for(var i=0; i < list.length ; i++)
        {
            if(node.getAttribute("xhref") == list[i].getAttribute("xhref"))
            {
              
               returnV = i;
            }
        }
    
    }
    catch(e)
    {
        //alert(e);        
    }

    return returnV;
}

///////////////////////////////////////////////////////////Cache html file///////////////////////////////////////// 
function CacheHtmlFile(htmlfileName, localname)
{
    var xmlHttp;

    try
	{
	  // Firefox, Opera 8.0+, Safari
	  xmlHttp=new XMLHttpRequest();
	  		
	}
	catch (e)
	{
	  	// Internet Explorer
			
	    try
        {
  		    xmlHttp=new ActiveXObject("Msxml2.XMLHTTP");
   	    }
	  	catch (e)
   	    {
	    		try
	      		{
	      			xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");
	      		}
	    		catch (e)
	      		{
	      			alert("Your browser does not support AJAX!");
	      			return false;
	      		}
   	    }
    }
	  
      
      xmlHttp.onreadystatechange=function()
	  {
	   //alert(xmlHttp.readyState);
	   	if(xmlHttp.readyState==3)//2 loading....
    	{
    	   
    	   if(firstHtmlFilePart.length <= sizeOfFirstHtmlFilePart) //get the first ??? KB 
           { 
    	       firstHtmlFilePart = xmlHttp.responseText;
    	       
   	       }
   	       else if (!GotBookFired)
   	       { 
           
   	         eventSystemGotBook(book_tree); //Okay, have the first part of the htmlfile -> call the GUI
   	         GotBookFired = true;
   	       }
    	   
    	     
    	}
    	if(xmlHttp.readyState==4)
    	{
    	
    	   
    	   htmlCacheTable[localname] = xmlHttp.responseXML;
		   ReplaceLocalURIInHtml(htmlCacheTable[localname]);
    	   
    	   if(!GotBookFired) //If done before sizeOfFirstHtmlFilePart call this
    	   {
	         eventSystemGotBook(book_tree); 
   	         GotBookFired = true;
    	   
    	   }
    	   
            
    	}
  	  }
  	
      
     if(xmlHttp.overrideMimeType)
	 {     
        xmlHttp.overrideMimeType('text/xml');//virker for firefox og safari
        xmlHttp.open("GET",htmlfileName,true);   	
        xmlHttp.send(null);//same directory
     }  
     else
     {
        var xmlDoc1;
        
        xmlDoc1 = new ActiveXObject("Microsoft.XMLDOM");
        xmlDoc1.async="false";
        //xmlDoc1.resolveExternals = "false";


        try
        {      //alert("her");
            xmlDoc1.load(htmlfileName);//xmlns="http://www.w3.org/1999/xhtml" if not declared err0r
            htmlCacheTable[localname] = xmlDoc1;
			ReplaceLocalURIInHtml(htmlCacheTable[localname]);
        }
        catch(e)
        {
            alert(e.message);
        
        }
  
     }
}  



function GetHtmlName(smilfileXml)
{
    if(window.console)console.log('PRO: GetHtmlName');
    if(smilfileXml.getElementsByTagName("text").length != 0)
    {
        var htmlFileName = smilfileXml.getElementsByTagName("text")[0].getAttribute("src");
   
        htmlFileName = htmlFileName.substring(0,htmlFileName.indexOf("#"));

        
        CacheHtmlFile(DODPUriTransLate[ htmlFileName ], htmlFileName);
     }
     else
     {
        alert("ingen text");
     }
}

function ReplaceLocalURIInHtml(html)
{
	$(html).find('img').each(
		function()
		{
			
			$(this).attr('src',DODPUriTransLate[$(this).attr('src')]);
		
		}
	);
}


//////////////////////////////////////////////////////////////creating a <li> strukture//////////////////////////////////////////////////////





function supports_local_storage() 
{
  try 
  {
    if (window['localStorage'] != null)
    {
        return true;
    }
    
  } 
  catch(e)
  {
    return false;
  }
}

function GetTextAndSound(aElement)
{
    if(Player.isSystemEvent)
    {
       Player.isSystemEvent = false; 
    }
    else
    {
        Player.isUserEvent = true;
    }
    
  //aElement.setAttribute("class", TOCHighLightColor);
    
  try 
  {
      
       currentAElement = aElement;
       nextAElement = GetNextAElement(aElement);
	   
	   
       
        
       // UrlToBook +
       var smilfile =  aElement.getAttribute("xhref").substring(aElement.getAttribute("xhref").lastIndexOf("/")+1,aElement.getAttribute("xhref").indexOf("#"));
       
       currentSmilFile = smilfile;
      
       var smilid   = aElement.getAttribute("xhref").substr(aElement.getAttribute("xhref").indexOf("#")+1);
       
       
       if(smilCacheTable[smilfile] == undefined )//not in cache
       {
        //alert("her");
         var p = findNode(aElement,PLAYLIST);
         PrePareSmilNames(PLAYLIST[p],1); 
         //hent smilfil ikke async.....
         CacheSmilFilesSync();
	
         GetTextAndSound(aElement);
        
       }
	   

       else if(smilCacheError)
       {    
            alert("There is a problem with the cache");
            //disable cache...maybe...
       }
       else
       {
            //alert(smilid);
            text_window.innerHTML ="";//clear the text window
            
             var pos = smilCacheTableGetIndex(smilfile); //Get position in cash
              
             if(pos > smilCacheTrigger) //if we hit the secondlast smilfile in the cache ->cache
             {
                
                var p = findNode(aElement,PLAYLIST) + (smilCacheSize - pos);

                //cache next  smilfiles...despose the 3 first
                PrePareSmilNames(PLAYLIST[p],smilFilesToCache); 
                
                CacheSmilFiles();             
             }
             
             soundfilename = smilCacheTable[smilfile].getElementsByTagName("audio")[0].getAttribute("src");
             nextSoundFileName = GetNextSoundFileName(smilCacheTable[smilfile],smilfile);
            
             tempTextList = smilCacheTable[smilfile].getElementsByTagName("text");
             
             textTagList.length = 0;//nulstil array
             
             for(var i = 0; i < tempTextList.length; i++)
             {
                textTagList[i] = tempTextList[i];//prepare list of text
             }
             
             //alert(textTagList.length + "antal text");
             //alert(tempTextList.length + "antal temp");
             if(settings.textMode==2)
             {
                GetAllTheText = true;
             }
             if(!Player.LastPartNCCJump)
             {
             	//return;
				
				currentTimeInSmil = smilCacheTable[smilfile].getElementsByName("ncc:totalElapsedTime")[0].getAttribute("content");
				SetTotalSeconds(currentTimeInSmil);
				
	   				
                GetTextAndSoundPiece(smilid,smilCacheTable[smilfile]);                  
                textTagList.shift(); //Returns the first element and removes it from the array...
             }
             else
             {
                Player.LastPartNCCJump = false;
             }                    
       }
         
   
  } 
  catch(e)
  {
    return false;
  }
}


function GetNextAElement(aElement)
{
    try
    {
        for(var i=0; i < PLAYLIST.length; i++)
        {
            if(PLAYLIST[i].getAttribute("xhref") == aElement.getAttribute("xhref"))
            {
                return PLAYLIST.item(i+1);
            }
        }
        return null;
    }
    catch(e)
    {
    
        return null;
    
    }

}

function GetLastAElement(aElement)
{
    try
    {
        for(var i=0; i < PLAYLIST.length; i++)
        {
            if(PLAYLIST[i].getAttribute("xhref") == aElement.getAttribute("xhref"))
            {
                return PLAYLIST.item(i-1);
            }
        }
        return null;
    }
    catch(e)
    {
    
        return null;
    
    }

}


function GetNextSoundFileName(smilCacheEntry,smilname)
{
   
    var found = false;
    
    try
    {
        var tempList = smilCacheEntry.getElementsByTagName("audio");
        
        
        
        if(tempList.length != 0)
        {
            
            
            for(var i=0; i < tempList.length; i++)
            {
                if(tempList[i].getAttribute("src") != soundfilename )
                {
                    soundfilename = tempList[i].getAttribute("src");
                    
                    found = true;
                    break;
                }
            
            
            }
            if(!found)//look in next smil file
            {
                
                var aIndex;
                aIndex = smilCacheTableGetIndex(smilname);
                if(aIndex < smilCacheSize)
                {
                    
                    var temp = smilCacheTableGetKey(aIndex+1);
                    //alert(smilCacheTable[temp]);
                    if(smilCacheTable[temp] != undefined)
                    {
                        //alert(temp);
                        GetNextSoundFileName(smilCacheTable[temp],temp);
                        //alert(smilCacheTable[smilname]);
                    }
                    else
                    {
                        soundfilename ="";
                    }
                }
                
            
            }
            
        }
        
        
        
    
    }
    catch(e)
    {
    
        alert(e.message);
    
    }
    
    return soundfilename;

}


function GetTextAndSoundPiece(aSmilId,smilfileXml)
{  
    try
    {  
        switch(smilfileXml.nodeType)
        {      
             case 1:      
                switch(smilfileXml.nodeName.toUpperCase())
                {
                        case "TEXT":
                            var id = $(smilfileXml).attr('id');    
                            if(settings.textMode==1)
                            {
                                if(id == aSmilId)
                                {
                                    var temp = smilfileXml.getAttribute("src");   
                                    //UrlToBook+
                                    GetText(temp.substring(0,temp.indexOf("#")),temp.substr(temp.indexOf("#")+1));
                                    
                                    var tempList = smilfileXml.parentNode.getElementsByTagName("audio");
                                    
                                    for(var i = 0; i < tempList.length; i++)
                                    {
                                        audioTagList[i] = tempList[i];
                                    }
                                
                                    var audio = audioTagList.shift(); // Returns the first element and removes it from the array...
                                    //UrlToBook +
                                    GetSound( DODPUriTransLate[ audio.getAttribute("src") ],audio.getAttribute("clip-begin"),audio.getAttribute("clip-end"));
                                }
                                
                            
                            }
                          
                            else
                            {
                                if(GetAllTheText)
                                {
                                    var temp = smilfileXml.getAttribute("src");
                                    //UrlToBook+ 
                                    GetText(temp.substring(0,temp.indexOf("#")),temp.substr(temp.indexOf("#")+1));
                                }
                                if(id == aSmilId)
                                {
                                
                                    var tempList = smilfileXml.parentNode.getElementsByTagName("audio");
                                
                                    for(var i = 0; i < tempList.length; i++)
                                    {
                                        audioTagList[i] = tempList[i];
                                    }
                                
                                    var audio = audioTagList.shift(); // Returns the first element and removes it from the array...
                                    //UrlToBook +
                                    GetSound( DODPUriTransLate[ audio.getAttribute("src") ],audio.getAttribute("clip-begin"),audio.getAttribute("clip-end"));
                                }
                                
                            }
                            
                        break;
                        
                       
                         
                        default : break;
  
                }
             break;
             
             default : break;
        
        }
    

        for(var i=0; i < smilfileXml.childNodes.length; i++)
        {
            GetTextAndSoundPiece(aSmilId,smilfileXml.childNodes[i]);
        }
  
    
    }
    catch(e)
    {
    
        alert(e.message);
    }
}

function FindEndTag(html,startPoint)
{

    try
    {
        
        html = html.substr(startPoint);
        GlobalCount += html.indexOf("<");
        
        if(  html.substring(html.indexOf("<")+1,html.indexOf("<")+2)   == "/")
        {
            
            FindEndTag(html,html.indexOf("<")+1);
        
        }
 
        
        
    
    }
    catch(e)
    {
        alert(e.message);
    
    }

}

function updateTime(currentTime)
{
	
	//var progress = 0;
	
    try
    {
		//currentTime = SecToTime(currentTime + totalsec)
        eventSystemTime(currentTime+ totalsec);

    }
    catch(e)
    {
        alert(e.message);
    
    }


}

function SetTotalSeconds(total)
{
 
  totalsec = parseInt(total.substr(0,2),10)*60*60;//houer
  
  totalsec = totalsec + (parseInt(total.substr(3,2),10)*60);//minutes
  
  totalsec = totalsec + parseInt(total.substr(6,2),10);//sec
  
}

function SecToTime(aTime)
{
	var temp;
	var houers;
	var min;
	var sec;
	
	houers = (aTime/60)/60;//houers
	houers = houers.toString();
	
	//min = aTime/60;
	
	
	min = houers.substring(houers.indexOf("."),(houers.length-1)-houers.indexOf("."));
	min = "0"+min;
	min = min * 60; //min
	min = min.toString();
	
	
	sec = min.substring(min.indexOf("."),(min.length-1)-min.indexOf("."));
	sec = "0"+sec;
	sec = sec * 60//sec
	
	sec = sec.toString();
	
	
	houers = houers.substring(0,houers.indexOf("."));
	min = min.substring(0,min.indexOf("."));
	sec = sec.substring(0,sec.indexOf("."));
	
	if(houers.length < 2)
	{
	  houers = "0"+houers;
	}
	if(min.length < 2)
	{
	  min = "0"+min;
	}
	if(sec.length < 2)
	{
	  sec = "0"+sec;
	}
	  
	
	
	temp = houers+":"+min+":"+ sec;

	 
	return temp;

}




function  GetText(htmlfileName,aId)
{
    try
    {
    
       
        
        if(htmlCacheTable[htmlfileName] != undefined || htmlCacheTable[htmlfileName] != null)
        {
			
			
			

			
			
          var html = htmlCacheTable[htmlfileName];
          var parameter = "//*[@id='"+aId+"']";
            
          if(document.evaluate)
          {
            var part =  html.evaluate(parameter,html, null, XPathResult.ANY_TYPE, null );
            var node = part.iterateNext();
            //node.setAttribute("class",HighLightColor);
            //text_window.appendChild(document.importNode(node, true));
            //alert("22 " + currentAElement.firstChild.nodeValue);
            eventSystemTextChanged("",node,"", currentAElement.firstChild.nodeValue);
            
          }
          else
          {
            //IE 
            
			//Android
			var temp = null;
			
			var t = $(htmlCacheTable[htmlfileName]);	
		 
		 //var j =  t.find('*');
		 //console.log(j);
		 
			t.find('*').each(
				function()
				{
					if($(this).attr('id') == aId)
					{
						temp = document.createTextNode($(this).text());
					}
		
				}
			);
			eventSystemTextChanged("",temp,"",currentAElement.firstChild.nodeValue);
			
			

          }
           
           


        }
        else //html file is not yet cached -> look in the first ?? kb of the file for the smil index....
        {
            
            if(firstHtmlFilePart.indexOf(aId) != -1)
            {   
                
                var temp1 = firstHtmlFilePart.substring(0,firstHtmlFilePart.indexOf(aId));
                var startTemp =  temp1.lastIndexOf("<");
                
                var temp2 = firstHtmlFilePart.substr(firstHtmlFilePart.indexOf(aId));
                var stopTemp = temp2.indexOf("</");
                
                
                GlobalCount = 0;
                FindEndTag(temp2,stopTemp);
                
                var htmlPart = firstHtmlFilePart.substring(startTemp,temp1.length + stopTemp + GlobalCount);
                //alert(htmlPart);
                //alert(currentAElement.firstChild.nodeValue);
                var temp = document.createTextNode($(htmlPart).text());
                 
                
               
                eventSystemTextChanged("",temp,"",currentAElement.firstChild.nodeValue);
                    
            }
        
            
            
        
        }
       
    
    }
    catch(e)
    {
    
        alert(e.message);
    
    }

}


function GetSound(UrlToSound,aStart,aEnd)
{
    if(Player.player.canPlayType('audio/mpeg') == "")
    {
        alert("kan ikke afspille mp3 format");             
        return;           
    }
    if(Player.userPaused)
    {   
        rememberSoundFile[0] = UrlToSound;
        rememberSoundFile[1] = aStart;
        rememberSoundFile[2] = aEnd;
        return; //If the user pushed the pause button dont play sound...
    }
    
    try
    {
        clearInterval(Player.BeginPolling);//stop asking for  Player.stopTime of file....
        if (Player.player.src.indexOf(UrlToSound) == -1)// ny lyd fil
        {
               if(Player.isCached(UrlToSound))
               {
                    //alert("switch");
                Player.SwitchPlayer(); //Use the other player object...:-)
                    
               }
               else
               {

					// OLES FORSLAG ER AT LOGGE IND HER: 
			        console.log('PRO: Requesting next sound file ' +UrlToSound);
					LogOn(settings.username,settings.password);
			        Player.player.src = UrlToSound; //.toLowerCase();            		
            		Player.player.preload = "metadata";
					Player.player.load();
               		
               }
			   
			   if(nextSoundFileName != "")
               {
					console.log('PRO: caching next sondfile' + nextSoundFileName);
					LogOn(settings.username,settings.password);
                    Player.CacheNextSoundFile(DODPUriTransLate[nextSoundFileName]);//cache the next soundfile 
               }
        }
        
         clipBegin = aStart.slice(4, -1);
         clipBegin = parseFloat(clipBegin);
         //alert(Player.player.readyState);
         //alert(Player.player.currentTime);
        if (Player.player.readyState != 0 )//&& Player.player.paused) //if mp3 file is loaded
        {
                            
            
                            //const unsigned short HAVE_NOTHING = 0;
                            //const unsigned short HAVE_METADATA = 1;
                            //const unsigned short HAVE_CURRENT_DATA = 2;
                            //const unsigned short HAVE_FUTURE_DATA = 3;
                            //const unsigned short HAVE_ENOUGH_DATA = 4;

            try
            { 
                   //alert(clipBegin);
                if(clipBegin != Player.stopTime || Player.player.currentTime < Player.stopTime )//næste tekst afsnit eller andre hop
                {
					
					Player.player.pause();
                    Player.player.currentTime = clipBegin; 
					
					
                    
                    //is not catching the eventseeked event for (IOS)....when currenttime is set to 0..
                    if(clipBegin == 0 )//&& Player.player.paused)
                    {
                        setTimeout("Player.player.play()",500);
                    }
                     
                }
                else
                {
					
					if(Player.player.paused)
					{
						Player.player.play();//same file (no jump) - keep playing
					}
                }
            }
            catch (err) 
            {

               // alert("du kan ikke springe i denne fil " + err);
                           
            }
                     
                      
                    
        }
        
        
        clipEnd = aEnd.slice(4, -1);
        clipEnd = parseFloat(clipEnd);
         
        Player.startTime =  clipBegin;
        Player.stopTime  =   clipEnd;
		
        Player.BeginPolling = setInterval("Player.CheckEndTime()", 50);
    }
    catch(e)
    {
    
        alert(e.message);
    }
    


}

function eventSystemPaused() //called when system makes a pause -not the UI...
{
    try
    {
       
        if(audioTagList.length > 0)//more audiotags to one text element
        {
            var audio = audioTagList.shift(); // Returns the first element and removes it from the array...                          
            GetSound(DODPUriTransLate[audio.getAttribute("src")],audio.getAttribute("clip-begin"),audio.getAttribute("clip-end")); 
        }
        else if(textTagList.length > 0)//more Texttags in smil file
        {
            var aTextTag = textTagList.shift();
            GetAllTheText = false;
            GetTextAndSoundPiece(aTextTag.getAttribute("id"),smilCacheTable[currentSmilFile]);
        }
        else if( nextAElement != null)
        {
            Player.isSystemEvent = true;
            GetTextAndSound(nextAElement);
        }
    }
    catch(e)
    {
    
        alert(e.message);
    }
    
}

function InitSystem()
{
  //Prepare new book.....
  
  DODPUriTransLate = new Object(); //flush the cache
  smilCacheTable = new Object();
  smilNamesToBeAdded = new Array();
  rememberSoundFile = new Array();
  smilFilesInBuffer = 0;
  htmlCacheTable = new Object();
  firstHtmlFilePart = "";
  GotBookFired = false;
  
  audioTagList = new Array();//taglist of audiotags belonging to on <text> </text> tag
  textTagList = new Array();
  smilCacheError = false;
  
  currentSmilFile = "";
  currentAElement = null;
  nextAElement = null;
  nextSoundFileName ="";//name of nextsoundfilename...
  currentTimeInSmil = ""; 
  totalsec = 0;
  
  
  Pause();
  Player.player.startTime = 0;
  Player.player.stopTime = 0;
  Player.player.BeginPolling = 0;
  Player.player.LastPartNCCJump = false;
  Player.player.userPaused = false;
}
