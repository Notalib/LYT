
//ALL LIVE EVENTS TODO WITH LOGIN
function login(){}

$('#login').live("pagebeforeshow",function(event){
    $("#login-form").submit(function(event)
    { 
    	goto="bookshelf";
        //set loading screen
        $.mobile.showPageLoadingMsg();
        //remove focus 
        $('#password').blur();	
        // Prevent the default submit.
        event.preventDefault();
        event.stopPropagation();	
        //Save credentials - only save username if its not a cpr number
        if($('#username').val().length<10)settings.username = $('#username').val();
        settings.password = $('#password').val();
        SetSettings();
        //LogOn is defined in the FileInterface-****.js files
		LogOn($('#username').val(),$('#password').val());          
    });
});

//ALL LIVE EVENTS TODO WITH BOOK NAVIGATION DISPLAY
function book_index(){}

$('#book_index').live("pagebeforeshow",function(event){	
	//render listview
	$('#book_index_content').trigger('create');
	//Play / navigate
    $("li[xhref]").bind('click',function(event){
	        $.mobile.showPageLoadingMsg();
	    	if(($(window).width() - event.pageX > 40) || (typeof $(this).find('a').attr('href')=="undefined")){
				if($(this).find('a').attr('href')){
			    	event.preventDefault();
			        event.stopPropagation();
	    		}
			        event.stopImmediatePropagation();
	            	GetTextAndSound(this);
		            $.mobile.changePage('#book-play');
	    	} 
	        else{
	        	//Navigate further down in structure
			    event.stopImmediatePropagation();
	            $.mobile.changePage($(this).find('a').attr('href'));                    	
   	      	}
      }); 
});
 
function bookplay(){}
//ALL LIVE EVENTS AND DOINGS TODO WITH BOOK DISPLAY 
$('#book-play').live("pagebeforeshow",function(event){
	console.log('afsiller nu - ' + isPlayerAlive());
	if(!isPlayerAlive()){
		goto="bookshelf";
		gotoPage();
	}
	//SHIFT IMAGE IF IT EXISTS
	covercache_one($('#book-middle-menu'));
	//SET TEXT CONTENT TO SAVED SIZE, TYPE AND COLOR 
	$('#book-text-content').css('background',settings.markingColor.substring(0,settings.markingColor.indexOf('-',0)));
	$('#book-text-content').css('color',settings.markingColor.substring(settings.markingColor.indexOf('-',0)+1));        
    $('#book-text-content').css('font-size',settings.textSize+'px');	
    $('#book-text-content').css('font-family',settings.textType);
    $('#bookshelf [data-role=header]').trigger('create');
    $('#book-play').bind('swiperight', function(){
    	NextPart();
    });
    $('#book-play').bind('swipeleft', function(){
    	LastPart();
    });
});


function bookdetails(){}

//ALL LIVE EVENTS AND DOINGS TODO WITH BOOK DISPLAY 
$('#book-details').live("pagebeforeshow",function(event){

});

function onBookDetailsSuccess(data, status){
	$('#book-details-image').html('<img id="'+ data.d[0].imageid +'" class="nota-full" src="/images/default.png" />');
	var s = "";
	if(data.d[0].totalcnt>1) s = '<p>Serie: '+data.d[0].series+', del '+data.d[0].seqno+' af '+data.d[0].totalcnt+'</p>';
	$('#book-details-content').empty();
	$('#book-details-content').append('<h2>'+data.d[0].title+'</h2>'
		+'<h4>'+data.d[0].author+'</h4>'
		+'<a href=\"javascript:PlayNewBook(' + data.d[0].imageid+', \''+data.d[0].title.replace('\'', '') +'\',\''+data.d[0].author+'\')" data-role="button" data-inline="true">Afspil</a>'
		+'<p>' + parse_media_name(data.d[0].media) + '</p>'
		+'<p>'+data.d[0].teaser+'</p>'
		+ s
	).trigger('create');
	covercache_one($('#book-details-image'));
	//$('#book-details-content').refresh();
}

//Book details ERROR
function onBookDetailsError(msg, data){
		$('#book-details-image').html('<img src="/images/default.png" />');
		$('#book-details-content').html('<h2>Hov!</h2>'
										+'<p>Der skulle have været en bog her - men systemet kan ikke finde den. Det beklager vi meget! <a href="mailto:info@nota.nu?subject=Bog kunne ikke findes på E17 mobilafspiller">Send os gerne en mail om fejlen</a>, så skal vi fluks se om det kan rettes.</p>');

}   


//ALL LIVE EVENTS AND DOINGS TODO WITH SEARCH PAGE 
function search(){}


$('#search').live("pagebeforeshow",function(event)
{
		$("#search-form").submit(function()
        {
            $('#searchterm').blur();	
            $.mobile.showPageLoadingMsg();
    	    $('#searchresult').empty();
            $.ajax({
                type: "POST",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                url: "/Lyt/search.asmx/SearchFreetext",
                cache: false,
                data: '{term:"' + $('#searchterm').val() + '"}',
                success: onSearchSuccess,
                error: onSearchError,
                complete: onSearchComplete
        });
        return false;
    });
                
$("#searchterm").autocomplete({
        source: function(request, response) {
            $.ajax({
                url: "/Lyt/search.asmx/SearchAutocomplete",
                data: '{term:"' + $('#searchterm').val() + '"}',
                dataType: "json",
                type: "POST",
                contentType: "application/json; charset=utf-8",
                dataFilter: function(data) { return data; },
                success: function(data) {
                    response($.map(data.d, function(item) {
                        return {
                            value: item.keywords
                        }
                    }))                    
	                $('.ui-autocomplete').css('visibility','hidden');
	                var list = $('.ui-autocomplete').find('li').each(function(){
                    	$(this).removeAttr('class');
                    	$(this).attr('class','ui-icon-searchfield');
                    	$(this).removeAttr('role');
                    	$(this).html('<h3>' + $(this).find('a').text() + '</h3>');
                    	$(this).attr('onclick','javascript:$("#searchterm").val(\''+ $(this).text() +'\')');
                    });
                    if(list.length==1 && $(list).find('h3:first').text().length==0){
						$(list).html('<h3>Ingen forslag</h3>');
                    }
					$('#searchresult').html(list).listview('refresh');
                },
                error: function(XMLHttpRequest, textStatus, errorThrown) {
                    alert(textStatus);
                }
            });
        },
        minLength: 2
    });                
    
	$("#searchterm").bind( "autocompleteclose", function(event, ui) {
            $("#search-form").submit();
  	});	
		
	$('#search li').live('click', function() 
	{
		   $('#book-details-image').empty();
		   $('#book-details-content').empty();
	        $.ajax({
	            type: "POST",
	            contentType: "application/json; charset=utf-8",
	            dataType: "json",
	            url: "/Lyt/search.asmx/GetItemById",
	            cache: false,
	            data: '{itemid:"' + $(this).attr('id') + '"}',
	            success: onBookDetailsSuccess,
	            error: onBookDetailsError
			});
	    return false;
	});

});

//SEARCH SUCCESS FUNCTION - INSERT SEARCH RESULT INTO #STRUCTURE GIVEN THE FOLLOWING PARAMETERS
	//    title = t,
	//    author = a,
	//    imageid = i,
	//    teaser = d,
	//    media = m,
	//    series = se,
	//    seqno = v,
	//    totalcnt = vc,
	//    keywords = kw	                    
function onSearchSuccess(data, status){
	var s = "";
	if(data.d[0].resultstatus!="NORESULTS"){
		s += '<li><h3>' + data.d[0].totalcount + ' resultat(er)</h3></li>';
		$.each(data.d, function(index, item) {
			s += '<li id="'+item.imageid+'"><a href="#book-details">'
			+'<img class="ui-li-icon" src="/images/default.png" /><h3>' + item.title + '</h3><p>' + item.author + ' | ' + parse_media_name(item.media) + '</p></a></li>';
		})
	}else{
		s += '<li><h3>Ingen resultater</h3><p>Prøv eventuelt at bruge bredere søgeord. For at teste funktionen, søg på et vanligt navn, såsom "kim" eller "anders".</p></li>';		
	}
	$('#searchresult').html(s);
}

//SEARCH ERROR
function onSearchError(msg, data){
    $("#searchresult").text("Error thrown: " + msg.status);
}       

//SEARCH COMPLETE
function onSearchComplete(){
	$('#searchresult').listview('refresh');
	//JQM BUG
	$('#searchresult').find('a:first').css('padding-left','40px');
    $.mobile.hidePageLoadingMsg();
    //SHIFT IMAGES IF THEY EXIST
    covercache($('#searchresult').html());
}

function bookshelf(){}

//ALL LIVE EVENTS AND DOINGS TODO WITH BOOKSHELF PAGE 

$('#bookshelf').live('pagebeforeshow', function(event) {
	$.mobile.hidePageLoadingMsg();
});


function PlayNewBook(id,title,author){
		$.mobile.showPageLoadingMsg();
		Pause();		
        settings.currentBook = id.toString(); //change currentbook
		settings.currentTitle = title;
		settings.currentAuthor = author;
		SetSettings();
    	$('#currentbook_image').find('img').attr("src","/images/default.png").trigger('create');
    	$('#currentbook_image').find('img').attr("id",settings.currentBook).trigger('create');
    	$('#book_title').text(title);
    	$('#book_author').text(author);
    	$('#book_chapter').text(0);
    	$('#book_time').text(0);		
        $.mobile.showPageLoadingMsg();
        //PROTOCOL: CALLBACK TO GET NEW BOOK FROM SHELF
        GetBook(settings.currentBook);
        Play();
}
function settings(){}
//ALL LIVE EVENTS AND DOINGS TODO WITH SETTINGS PAGE 
$('#settings').live('pagebeforecreate',function(event){
	//SET CURRENT SETTINGS
	var initialize=true;

	//TEXT SIZE
    $('#textarea-example').css('font-size',settings.textSize+'px');
	$("#textsize").find('input').val(settings.textSize);

	//TEXT SIZE 2
	$('#textsize_2').find('input').each(function(){
		if($(this).attr('value') == settings.textSize){
			$(this).attr("checked",true);
		}
	});
		
	//TEXT TYPE
	$('#text-types').find('input').each(function(){
		if($(this).attr('value') == settings.textType){
			$(this).attr("checked",true);
		}
	});
    $('#textarea-example').css('font-family',settings.textType);

	//MARKING COLOR
	$('#marking-color').find('input').each(function(){
		if($(this).attr('value') == settings.markingColor){
			$(this).attr("checked",true);
		}
	});
        $('#textarea-example').css('background',settings.markingColor.substring(0,settings.markingColor.indexOf('-',0)));
        $('#textarea-example').css('color',settings.markingColor.substring(settings.markingColor.indexOf('-',0)+1));
    
    //RESPONSE FUNCTIONS
	//textsize 2 - radios
    $("#textsize_2 input").change(function(){
		settings.textSize = $(this).attr('value');
        SetSettings();
        $('#textarea-example').css('font-size',settings.textSize+'px');
        $('#book-text-content').css('font-size',settings.textSize+'px');
    });
	
    $("#text-types input").change(function(){
		settings.textType = $(this).attr('value');
        SetSettings();
        $('#textarea-example').css('font-family',settings.textType);
        $('#book-text-content').css('font-family',settings.textType);
    });
    
    $("#marking-color input").change(function(){
		settings.markingColor = $(this).attr('value');
        SetSettings();
        $('#textarea-example').css('background',settings.markingColor.substring(0,settings.markingColor.indexOf('-',0)));
        $('#textarea-example').css('color',settings.markingColor.substring(settings.markingColor.indexOf('-',0)+1));
        $('#book-text-content').css('background',settings.markingColor.substring(0,settings.markingColor.indexOf('-',0)));
        $('#book-text-content').css('color',settings.markingColor.substring(settings.markingColor.indexOf('-',0)+1));        
	});
    
    $("#reading-context").click(function(){
        settings.textPresentation = document.getElementById(this.getAttribute("for")).getAttribute("value");   
	});
    
});

//AND A LITTLE BIT AFTER BEFOREPAGECREATE
$('#settings').live('pagecreate',function(event){
});

//SYSTEM EVENTS

//Got a value from underlying protocol -> with boolean value (true or false)...
function eventSystemLogedOn(logedOn,id)
{
	if(id!=-1){
		settings.username = id;
		SetSettings();
	}    
	if(logedOn){
		console.log('GUI: Event system loged on - kalder goto ' + goto);
			gotoPage();
    }else{
	    //unset loading screen
	    $.mobile.hidePageLoadingMsg();
    	$.mobile.changePage('#login');
    }
}

//Got logoff event from underlying protocol -> with boolean value (true or false)...
function eventSystemLogedOff(logedOff)
{
	if(window.console)console.log('GUI: Event system loged off');
    //unset loading screen
    $.mobile.hidePageLoadingMsg();
	goto="bookshelf";
    if(logedOff){
    	$.mobile.changePage('#login');
    }
}


function eventSystemNotLogedIn(where){
	goto = where;
	if(settings.username!="" && settings.password!=""){
		if(window.console)console.log('GUI: Event system not logged in, logger på i baggrunden');
		LogOn(settings.username,settings.password);
	}else{
		$.mobile.changePage('#login');
	}
}

function eventSystemForceLogin(response){
	alert(response);
	$.mobile.hidePageLoadingMsg();
	$.mobile.changePage('#login');
}

//Got the book from underlying protocol
function eventSystemGotBook(bookTree)
{
	//update navigation and text-window
	$.mobile.hidePageLoadingMsg();
	$("#book-play #book-text-content").html(text_window);
    GetTextAndSound(PLAYLIST[0]);
    $("#book_index_content").empty();
	$("#book_index_content").append(bookTree);
	//$("#book_index_content").append('<p>Jeg er Hermann - jeg skulle have været en indholdsfortegnelse.</p>');
	$.mobile.changePage('#book-play');
}

function eventSystemGotBookShelf(bookShelf)
{
	goto="";
	full_bookshelf=bookShelf;
	console.log(full_bookshelf);
	$("#bookshelf-content").empty();
	//PARSE DODP RESPONSE - ATT: THIS SHOULD MAYBE BE CHANGED TO JSON 
	//REMARK FORMAT ON TEXT FROM PROTOCOL (title$author$format - must be parsed into title, author and format)
   	var aBookShelf ="";
   	var nowPlaying="";
   	var addMore ="";
   	//IF YOU WANT TO DELIMIT SIZE, USE :lt(10)
    $(bookShelf).find('contentItem:lt('+ bookshelf_showitems + ')').each(function()
    {
	   	var delimiter = $(this).text().indexOf('$');
	   	var author = $(this).text().substring(0, delimiter);
	   	var title = $(this).text().substring(delimiter +1);
    	if($(this).attr("id")==settings.currentBook) {
	        nowPlaying = '<li id="'+$(this).attr("id")+'" title="'+ title.replace('\'', '') +'" author="'+ author +'" ><a href="javascript:playCurrent();"><img class="ui-li-icon" src="/images/default.png" />'
	        + '<h3>' + title + '</h3><p>' + author + ' | afspiller nu</p></a></li>';    
    	}else{
	        aBookShelf += '<li id="' +$(this).attr("id")+'" title="'+ title.replace('\'', '') +'" author="'+ author +'"><a href=\'javascript:PlayNewBook(' + $(this).attr("id") + ', " '+ title.replace('\'', '') +' " , " '+ author +' ")\'><img class="ui-li-icon" src="/images/default.png" />'
	        + '<h3>' + title + '</h3><p>' + author + '</p></a><a href="javascript:if(confirm(\'Fjern ' + title.replace('\'', '') + ' fra din boghylde?\')){ReturnContent('+$(this).attr("id")+');}" >Fjern fra boghylde</a></li>';    
    	}
    });
    if($(full_bookshelf).find('contentList').attr('totalItems')>bookshelf_showitems) addMore= '<li id="bookshelf-end "><a href="javascript:addBooks()">Hent flere bøger på min boghylde</p></li>';
	$.mobile.changePage('#bookshelf');
    //INSERT BOOKSHELF IN GUI
    $("#bookshelf-content").append('<ul data-split-icon="delete" data-split-theme="d" data-role="listview" id="bookshelf-list">' + nowPlaying + aBookShelf + addMore + '</ul>').trigger('create');
    //SHIFT IMAGES IF THEY EXIST
    covercache($('#bookshelf-list').html());
}

function addBooks(){
	bookshelf_showitems +=5;
	eventSystemGotBookShelf(full_bookshelf)
}
//Got the bookmarks belonging to settings.currentbook 
function eventSystemGotBookmarks()
{
}
//Update the GUI when the player is paused by the user or system if aType = 1 -> system, aType = 2 -> user
function eventSystemPause(aType)
{
	//BUTTON TEXT: PLAY 
	$('#button-play').find('img').attr('src','/images/play.png').trigger('create');
 
    if(aType == Player.Type.user)
    {
        //alert("pause");  
    }
    else if(aType == Player.Type.system)
    {
    
    }


}
//Update the GUI when the player is playing started by the user or system if aType = 1 -> system, aType = 2 -> user
function eventSystemPlay(aType)
{
	//BUTTON TEXT: PAUSE 
	$('#button-play').find('img').attr('src','/images/pause.png').trigger('create');

    if(aType == Player.Type.user)
    {
        //alert("play"); 
    }
    else if(aType == Player.Type.system)
    {
    
    }

}
function eventSystemTime(t)
{
	var total_secs, current_percentage;
	if($('#NccRootElement').attr('totaltime')!=null){	
		tt = $('#NccRootElement').attr('totaltime');
		if(tt.length==8)total_secs = tt.substr(0,2)*3600+(tt.substr(3,2)*60)+parseInt(tt.substr(6,2));
		if(tt.length==7)total_secs = tt.substr(0,1)*3600+(tt.substr(2,2)*60)+parseInt(tt.substr(5,2));
		if(tt.length==5)total_secs = tt.substr(0,2)*3600+(tt.substr(3,2)*60);
	}
	current_percentage = Math.round(t/total_secs *98);
    $('#current_time').text(SecToTime(t));
    $('#total_time').text($('#NccRootElement').attr('totaltime'));
    $('#timeline_progress_left').css('width',current_percentage + '%');
}
//Got new textpeace from system.. 
function eventSystemTextChanged(textBefore,currentText,textAfter,chapter)
{
    try
    {
        text_window.innerHTML ="";
        if(chapter=="" || chapter==null)chapter="Kapitel";
        if(chapter.length>14)chapter=chapter.substring(0,14)+'...';
        $('#book_chapter').text(chapter);
        if(currentText.nodeType != undefined)
        {
            text_window.appendChild(document.importNode(currentText, true));
            $('#book-text-content').find('img').each(function(){
            	var rep_src = $(this).attr('src').replace(/\\/g, "\\\\");
            	var oldimage = $(this);
				var img = $(new Image()).load(function() {
				    // image exists
					$(oldimage).replaceWith($(this));
					$(oldimage).attr('src',$(this).attr('src'));
					$(this).css('max-width','100%');
					var position = $(this).position();
					$.mobile.silentScroll(position.top);
				}).error(function() {
				    // image does not exist
				}).attr('src',rep_src);
            });
			//UPDATE STYLING ON INCOURANT TAGS  		
			$('#book-text-content h1 a, #book-text-content h2 a').css('color',settings.markingColor.substring(settings.markingColor.indexOf('-',0)+1)).trigger('create');			
            
        }
        else
        {
        
        }    
    }
    catch(e)
    {
        alert(e);   
    }
}

//The undelaying player module is fetching data.....
function eventSystemStartLoading()
{
    $.mobile.showPageLoadingMsg();
}

function eventSystemEndLoading()
{
    $.mobile.hidePageLoadingMsg();
}


function showIndex(){
	$.mobile.changePage('#book_index');
}

function playCurrent(){
	if(isPlayerAlive()){
		$.mobile.changePage("#book-play");
	}else{
		PlayNewBook(settings.currentBook, settings.currentTitle,settings.currentAuthor);
	}
}
function setDestination(where){
	goto =  where;
}
function gotoPage(){
	if(window.console)console.log('GUI: gotoPage - ' + goto);
	switch(goto){
		case "bookshelf":
		  GetBookShelf();
		  goto="";
		  break;
		default:
		  if($('.ui-page-active').attr('id')=="login"){
		  	GetBookShelf();
		  }
		  break;
	}	
}

function logUserOff(){
	settings.username="";
	settings.password="";
	SetSettings();
	LogOff();
}