// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery-1.8.3
//= require jquery_ujs
//= require jquery-ui-1.9.2.custom
//= require jquery.validationEngine-en
//= require jquery.validationEngine
//= require fyi-autocomplete 
//= require colpick
//= require jquery.colorPicker
//= require cycle.min
//= require jquery.sparkline.min
//= require jquery.raty.min
//= require cloudinary
//= require jquery.jcrop.min
//= require cloudinary/processing  
//= require ZeroClipboard.min
//= require uservoice 
 

if (!window.console) var console = { log: function() {} };

// validation engine globals
$.validationEngine.defaults.scroll = false;
$.validationEngine.defaults.autoHidePrompt = true;

// popups
$('a[data-popup]').live('click', function(event) { 
	window.open(this.href); 
     event.preventDefault(); 
});

$(".flash-x").live('click', function(event) { 
	$(this).closest(".closable").fadeOut("slow");
    event.preventDefault(); 
    return false;
});

// textarea maxlength
$('textarea[counterid], input[counterid]').live('focus keyup blur', function() {
    // Store the maxlength and value of the field.
    var maxlength = $(this).attr('maxlength');
    var val = $(this).val();

    // Trim the field if it has content over the maxlength.
    if (val.length > maxlength) {
        $(this).val(val.slice(0, maxlength));
    }
    
    var counterId = $(this).attr('counterId');
    if (counterId != null) {
    	$('#' + counterId).show();
    	$('#' + counterId).html(maxlength - val.length);
    }
});

$('textarea[counterid], input[counterid]').live('blur', function() {
    var counterId = $(this).attr('counterId');
    if (counterId != null) {
    	$('#' + counterId).hide();
    }
});

// accordion
$('.fyi-accordion .standard-section-header').live('click', function(event) { 
	var panel = $(this).next();
	var header = $(this);
	if (panel.is(":visible")) {		
		panel.slideToggle("fast", function () {
			header.removeClass("expanded");
			header.addClass("collapsed");			
		});
	} else {
		// close what's already open
		var accordion = $(this).closest('.fyi-accordion');
		if(accordion.hasClass("toggle-panels")) {
			accordion.find(".accordion-panel").slideUp("fast", function () {
				accordion.find(".accordion-header").removeClass("expanded").addClass("collapsed");	
			});
		}
		
		panel.slideToggle("fast", function () {
			header.removeClass("collapsed");
			header.addClass("expanded");
		});
	}

	return false;
});

$('.sign-in-link').live('click', function(event) {
	$("#email-input").focus();
	return false;
});

// create listing status controls 
function buildListingStatus(userId, status) {
	var html = "";
	if(status == 0) { // pending
		html = "<span>Not verified</span>";
	} else if (status == 1) { // verified
		html = "<span>Active</span><a id='status-inactivate' uid=" + userId + ">Deactivate</a>";
	} else { // deleted
		html = "<span>Inactive</span><a id='status-activate' uid=" + userId + ">Activate</a>";
	}
	
	$("#listing-status-box").html(html); 
}

function postUpdateStatusRequest(uid, status) {
	$.ajax({
	  type: "POST",
	  url: "/users/" + uid + "/set_status",
	  data: { status: status },
	  dataType: "script"
	});
}

$("#status-inactivate").live("click", function(){
  postUpdateStatusRequest($(this).attr('uid'), 2);
  trackEvent("developer", "inactivate listing");
  return false;
});

$("#status-activate").live("click", function(){
  postUpdateStatusRequest($(this).attr('uid'), 1);
  trackEvent("developer", "activate listing");
  return false;
});

$("#status-activate-top").live("click", function(){
  postUpdateStatusRequest($(this).attr('uid'), 1);
  return false;
});

function unescapeHTML(html_text) {
	var htmlNode = document.createElement("DIV");
	htmlNode.innerHTML = html_text;
	if(htmlNode.innerText) {
		return htmlNode.innerText; // IE
	}
	
	return htmlNode.textContent; // FF	
}

function escapeHTML( string ) {
    return jQuery( '<pre>' ).text( string ).html();
}

// tag selectors
function writeTag(newTagTxt, newTagDataKey, newTagDataVal, olId, idContext, readOnly, title) {
	var buildTagTypeClassName = function (newTagDataKey, newTagDataVal){
		return newTagDataKey + newTagDataVal;
	};
	
	var findInsertAfter = function(newTagDataKey, newTagDataVal) {
		var thisTypeTags = $o.children("." + buildTagTypeClassName(newTagDataKey, newTagDataVal));
		var $insertAfterElem = thisTypeTags.length == 0 ? null : $(thisTypeTags[thisTypeTags.length - 1]);
		return $insertAfterElem;
	};
	
	var newTag = $('<li title="'+escapeHTML(title)+'" class="onetag ' + buildTagTypeClassName(newTagDataKey, newTagDataVal) + '" />').text(newTagTxt);
	newTag.attr(newTagDataKey, newTagDataVal);
	
	if(!readOnly){			
		var tagXBtn = $('<a />');
		tagXBtn.click(function(e) {
			$(this).parent().fadeOut('fast', function() {
			    $(this).remove();
			});
		});
		
		newTag.append(tagXBtn);
	}
	
	var $o = null;
	if (idContext==null) {
		$o = $(olId); 
	} else{
		$o = $(idContext+" "+olId);
	}
		
	if(!readOnly){
		newTag.css('display', 'none');
	}
	
	var $insertAfterElem = findInsertAfter(newTagDataKey, newTagDataVal);
	if ($insertAfterElem == null){
		var intVal = parseInt(newTagDataVal,10);
		if (intVal != NaN){
			for (var i = intVal; i < 20/*max supported numeric value*/; i++) {
				$insertAfterElem = findInsertAfter(newTagDataKey, i);
				if($insertAfterElem != null){
					break;
				}
			}
		}
  	}
  	
  	if ($insertAfterElem == null){
  		$o.prepend(newTag);
  	} else {
		$insertAfterElem.after(newTag);
  	}
  	
  	if(!readOnly){
  		newTag.slideDown('fast');
  	}
}

function createNewTag(inputId, newTagDataKey, newTagDataVal, olId, suppressPrompt, titleFmt, text_for_add_more_plchldr) {
	var newTagTxt = $(inputId).val();
	newTagTxt = $.trim(newTagTxt).toLowerCase();
	if(newTagTxt != ""){
		var terms = newTagTxt.split( /,\s*/ );
		$.each(terms, function(index, value) {
			value = $.trim(value);
			if(value != ""){		
				$(olId + " > li").filter(function(){
				  return $(this).text() == value;
				}).remove();
		 		var tt_title_value = escapeHTML(value);
				var title= titleFmt.replace("%s", tt_title_value);//no stringf in JS, so workaround 
				writeTag(value, newTagDataKey, newTagDataVal, olId, null, false, title);

				$(inputId).attr("placeholder",text_for_add_more_plchldr);
			  	$(inputId).validationEngine('hidePrompt');
		  	}
		});	  	
	} else {
		if (!suppressPrompt){
			$(inputId).validationEngine('showPrompt', "Please enter a new tag.", 'error', 'topRight', true);
		}
	}
	
	$(inputId).val("");
}

function tagsToParams(olId, newTagDataKey) {
	var param = "";
	$(olId + " li").each(function(idx, itm) {
		if(param != "") {
			param += "&";
		}
		param += encodeURIComponent($(itm).text()) + "=" + encodeURIComponent($(itm).attr(newTagDataKey));
	});
	return param;
}



jQuery.fn.fading_highlight = function() {
	$(this).each(function() {
        var el = $(this);
        el.before("<div/>");
        el.prev()
            .width(el.outerWidth())
            .height(el.outerHeight())
            .addClass("fading_highlight")
            .fadeOut(500);
    });
};

function createValidUrl(elem) {
	var old_val = elem.val();
	var trimmed_old_val = $.trim(old_val);
	var trimmed_old_val_lc = trimmed_old_val.toLowerCase();//we do this only to account for case variation in HtTp
	if (trimmed_old_val_lc.indexOf('http') != 0 && trimmed_old_val_lc.length > 0) {
		elem.val("http://" + trimmed_old_val);
	} else if (old_val!=trimmed_old_val){
		elem.val(trimmed_old_val);
	}
}

 

function pitch_position(form_id, should_pitch){
	var $pitch_form = $(form_id);
	if ($pitch_form.find(".send-msg-btn").attr("disabled") != "disabled"){
		$pitch_form.find(".ajax-error-message").html("");
		var is_valid = $pitch_form.validationEngine('validate');
		if (is_valid){
			$pitch_form.find(".send-msg-btn").attr('disabled', true);
			$pitch_form.find(".no-msg-btn").attr('disabled', true);
			$pitch_form.find(".wait-indicator").css("visibility", "visible");
			$pitch_form.find(".should-pitch").val(should_pitch);
			
			trackEvent("employer", "should pitch: " + should_pitch);
			
			$pitch_form.submit();
		}
	}
}

// send invitation
$(document).delegate(".send-msg-form", "submit", function (event) {
	var res = false;
	if ($(this).find(".send-msg-btn").attr("disabled") != "disabled"){
		$(this).find(".ajax-error-message").html("");
		var is_valid = $(this).validationEngine('validate');
		if (is_valid){
			$(this).find(".send-msg-btn").attr('disabled', true);
			$(this).find(".no-msg-btn").attr('disabled', true);
			$(this).find(".wait-indicator").css("visibility", "visible");		
			trackEvent("employer", "invitation sent to developer");
			res = true;
		}
	}
	
	if (!res){
		event.preventDefault();
	}
	
	return res;
});	

function launchMailTo(email, subject, body) {
	var link = "/mailto#mailto:" + encodeURIComponent(email) + "?subject=" + encodeURIComponent(subject) + "&body=" + encodeURIComponent(body);
	window.open(link, '_blank');
}

$(function() {
	$(document).tooltip({ 
		position: { my: "left top+3", at: "left bottom" } 
	});
	
	$("a[target='_fyi_email']").click(function(){
	  var link = '/mailto#' + $(this).attr('href');
	  window.open(link, '_fyi_email');
	  return false;
	});
	
	// compound input box
	$('.free-text-input').focus(function() {
		$(this).closest(".compound-input-box").removeClass("inactive").addClass("active");
	});
	
	$('.free-text-input').blur(function() {
		$(this).closest(".compound-input-box").removeClass("active").addClass("inactive");
	});		
});

// This method supports window sizing and centering, 
// which in Chrome  does NOT work if you do a simple  window.open(..... 'width=800...'...
// Note that FF requires "1" rather than "yes" or "on". 
function openDialogWindow(href,  width_, height_, name_) {
    if (!name_)  name_ = '_fyi_infointerview';
    if (!width_) width_ = 1000;
    if (!height_) height_ = screen.height - 280;
 
    var defaultParams = { };

    var features_dict = {
        toolbar: '1',
        location: '0',
        directories: '0',
        left: (screen.width - width_) / 2,
        top: (screen.height - height_) / 2,
        status: '0',
        menubar: '0',
        scrollbars: '1',
        resizable: '1',
        width: width_,
        height: height_
    };
    features_arr = [];
    for(var k in features_dict) {
        features_arr.push(k+'='+features_dict[k]);
    }
    features_str = features_arr.join(',');


    var win = window.open(href, name_, features_str);
    win.focus();
    return false;
}

function highlight(field) {
	field.focus();
	field.select();
}

 
 //tooltip must be inside copy_button_selector with class .div-tooltip  or it will be ignored.
 //copy_button_selector must be an element of position!=static for relative positioning of tooltip to work.
 //TODO use zeroClipboard.Core to reduce load size
function zeroclipboard_init(copy_button_selector, text_callback) {
	ZeroClipboard.config({
		swfPath : '/ZeroClipboard.swf',
			bubbleEvents: false 
	});
	
	var button = $(copy_button_selector);
	
	var tooltip_div = $(copy_button_selector+" .div-tooltip");
	if (tooltip_div.length > 0){
		tooltip_div.click(function(){ 
			$(this).hide();
		});
	}

 	var client = new ZeroClipboard(button);
	client.on("ready", function(readyEvent) {
		client.on("copy", function(event) {
			var clipboard = event.clipboardData;
			var txt=text_callback();
			clipboard.setData("text/plain", txt);
			if(event.stopPropagation){
				event.stopPropagation();
			}
			event.cancelBubble=true;
		});

		client.on("aftercopy", function(event) {
			if (tooltip_div.length > 0 ){
				//  hide() is needed in case user clicks juset before fadeOut finishes
	 			tooltip_div.hide(); 
	 			tooltip_div.show();
	 	
	 			setTimeout(function() { 
					tooltip_div.fadeOut("slow"); 
				}, 3000);
		    }
		});
	});
}

function rgb2hex(rgb) {
	 if (  rgb.search("rgb") == -1 ) {
	      return rgb;
	 }
	 else if ( rgb == 'rgba(0, 0, 0, 0)' ) {
	     return 'transparent';
	 }
	 else {
	      rgb = rgb.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(\d+))?\)$/);
	      function hex(x) {
	           return ("0" + parseInt(x).toString(16)).slice(-2);
	      }
	      return "#" + hex(rgb[1]) + hex(rgb[2]) + hex(rgb[3]); 
	 }
}

function isDark( color ) {
	var hex = rgb2hex(color);
	hex = String(hex).replace(/[^0-9a-f]/gi, '');
	
	var sum = 0;
	for (i = 0; i < 3; i++) {
		sum += parseInt(hex.substr(i*2,2), 16);
	}
	
	return sum < 3 * 256 / 2; // r+g+b should be less than half of max (3 * 256)
}

// hex — a hex color value such as “#abc” or “#123456″ (the hash is optional)
// lum — the luminosity factor, i.e. -0.1 is 10% darker, 0.2 is 20% lighter, etc.
function colorLuminance(hex, lum) {
	// validate hex string
	hex = String(hex).replace(/[^0-9a-f]/gi, '');
	if (hex.length < 6) {
		hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
	}
	lum = lum || 0;

	// convert to decimal and change luminosity
	var rgb = "#", c, i;
	for (i = 0; i < 3; i++) {
		c = parseInt(hex.substr(i*2,2), 16);
		c = Math.round(Math.min(Math.max(0, c + (c * lum)), 255)).toString(16);
		rgb += ("00"+c).substr(c.length);
	}

	return rgb;
}