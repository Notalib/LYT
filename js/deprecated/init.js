/**
 * init.js
 * Creates global vars
 * Detects target platform and include relevant player.js
 * Finally includes gui.js to start application
 */

var PROTOCOL_TYPE = "DODP";
var settings;
var book_tree;
var goto="bookshelf";
var full_bookshelf="";
var bookshelf_showitems = 5;
var nowPlayingIcon = true;

$(document).bind("mobileinit", function(){
  	$.mobile.page.prototype.options.addBackBtn = true;
	//Gets settings from localstorage...    
	if(GetSettings()){
		gotoPage();
	}
});

//TRIGGER SOMETHING ON EVERY PAGELOAD
$('[data-role=page]').live('pageshow', function (event, ui) {
		//ANALYTICS
	  _gaq.push(['_setAccount', 'UA-25712607-1']);
	  _gaq.push(['_trackPageview', event.target.id]);
	  //if(isPlayerAlive() && nowPlayingIcon){
	  //	$('[data-role=header]').find('h1').append('<a href="#book-play" data-role="button" class="ui-btn-right" data-icon="arrow-r" data-iconpos="notext">Afspiller nu</a>');
	  //	$('[data-role=header]').trigger('create');
	  //	nowPlayingIcon=false;
	  //}
});


if(navigator.userAgent.toLowerCase().indexOf("chrome") != -1 || navigator.userAgent.toLowerCase().indexOf("android") != -1)
{
    $.browser.chrome = true;    
}
if($.browser.chrome)
{
    delete $.browser.safari;
}
//correction to JQuery $.browser

var alang = window.navigator.userLanguage || window.navigator.language;

if( alang.indexOf("da") != -1)
{
    alang = "da";      
}
else if(alang.indexOf("en") != -1)
{
    alang = "en";      
}




var PlayerJSPath = "<script src='js/Default/Player.js'></script>";
var ControlsJSPath = "<script src='js/Default/controls.js'></script>";



if(PROTOCOL_TYPE != undefined || PROTOCOL_TYPE != "")
{
    var ProtocolJSPath = "<script src='js/Protocol/FileInterface-"+PROTOCOL_TYPE +".js'></script>";
    
}
else
{
    alert("you have to insert a ' var PROTOCOL_TYPE = ??? ' into your html code header");
}


document.write(PlayerJSPath);
document.write(ControlsJSPath);
document.write(ProtocolJSPath);
document.write('<script src="/js/gui.js" type="text/javascript"></script>');

//Utility functions

//Get settings object from localstorage - if null use default settings
function GetSettings()
{
    if (!supports_local_storage())
    {
        alert("Din browser understøtter desværre ikke LYT, da vi ikke må få lov at gemme lokale filer på din telefon eller computer");      
        return false;
    }
    else
    {
        try
        {    
        	settings = localStorage.getItem("mobileSettings"); 
            if(settings == null || settings=="undefined")
             {
                     InitSettings();
                     return false;
             }
             else
             {             
                settings = JSON.parse(localStorage.getItem("mobileSettings"));
				if( settings.version != 'dev5.8' || settings.username==-1 || settings.username==""){
					InitSettings();
                     return false;
                }
             }
        }
        catch(e)
        {
            alert(e.message);
			return false;
        }
    }   
    return true;
}

function InitSettings()
{
				//alert('Vi opdaterer nu LYT til den nyeste version - du vil blive bedt om at logge på');
				LogOff();
                localStorage.clear(); 
				settings = 
                { 
                    textSize: "14px", 
                    markingColor: "none-black", 
                    textType: "Helvetica",
                    textPresentation: "full",
                    readSpeed: "1.0",
                    currentBook: "0",
                    currentTitle: "Ingen Titel",
                    currentAuthor: "John Doe",
					textMode: 1, //phrasemode = 1, All text = 2
					username: "",
					password: "",
					version: 'dev5.8',
                };    
	        	localStorage.setItem("mobileSettings", JSON.stringify(settings));  
                settings = JSON.parse(localStorage.getItem("mobileSettings"));
}


//update settings object in localstorage
function SetSettings()
{
   try
   {
        localStorage.setItem("mobileSettings", JSON.stringify(settings));        
   }
   catch(e)
   {
        alert(e.message);
   
   }
}


//Return image covers from e17 if exists
function covercache(element){
	$(element).each(function(){
		var id = $(this).attr('id');
		var u = 'http://www.e17.dk/sites/default/files/bookcovercache/'+ id +'_h80.jpg';
		var img = $(new Image()).load(function() {
		    // image exists
			$('#'+id).find('img').attr('src',u);
		}).error(function() {
		    // image does not exist
		}).attr('src',u);
	});	
}
//Return image covers from e17 if exists
function covercache_one(element){
	var id = $(element).find('img').attr('id');
	var u = 'http://www.e17.dk/sites/default/files/bookcovercache/'+ id +'_h80.jpg';
	var img = $(new Image()).load(function() {
	    // image exists
		$(element).find('img').attr('src',u);
	}).error(function() {
	    // image does not exist
	}).attr('src',u);
}

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
function parse_media_name(mediastring){
//ONLY TWO OPTIONS; AA = AUDIO, AT= AUDIO WITH TEKST
	if(mediastring.indexOf('AA') != -1){
		return 'Lydbog';
	}else{
		return 'Lydbog med tekst';
	}
}


