//= require jquery-1.8.3
//= require jquery_ujs
//= require jquery-ui-1.9.2.custom
//= require jquery.validationEngine-en
//= require jquery.validationEngine
//= require widget-config

// validation engine globals
$.validationEngine.defaults.scroll = false;
$.validationEngine.defaults.autoHidePrompt = true;

// extend _fyiWidget
_fyiWidget.prototype.attachById = function(boxId, publisher, bodyClass, colors, widgetStyle){
	var container = document.getElementById(boxId);
	if(container != null){
		this.attachToElem(container, publisher, bodyClass, colors, widgetStyle);
	}
	return container;
}

_fyiWidget.prototype.attachToElem = function (elem, publisher, bodyClass, colors, widgetStyle) {
	widgetStyle = widgetStyle == undefined ? "" : widgetStyle;
	bodyClass = bodyClass == undefined ? "" : bodyClass;
	colors = colors == undefined ? "" : colors;
	
	if(publisher == undefined || publisher == ""){
		var msg = document.createTextNode("Error: Mandatory attribute is missing [publisher]");
		this.replaceElemContentWithNode(elem, msg);
	} else {
		this.replaceElemContentWithIframe(elem, this.fyi_domain + "/board/" + "?publisher=" + encodeURIComponent(publisher) + "&class=" + encodeURIComponent(bodyClass) + "&colors=" + encodeURIComponent(colors) + "&style=" + encodeURIComponent(widgetStyle));
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
var _WIDTH_MIN = 350;
var _WIDTH_MAX = 900;
var _HEIGHT_MIN = 280;
var _HEIGHT_MAX = 900;
$(function() {
	$('.style-chooser:first').prop('checked',true);
	update_sample_color();
	load_default_preview();

  	$( "#show-border" ).click(function(event){
  		update_preview();
  	});
	
	$( "#apply-style" ).button().click(function( event ) {
      	event.preventDefault();
      	update_preview();
  	});
  	
	$( "#reset-style" ).button().click(function( event ) {
      	event.preventDefault();      	
      	load_default_preview();
  	});
  	
  	$( "#font-size input:radio").click(function(event){
  		update_preview();
  	});
  	
    $( "#width" ).spinner({
      	min: _WIDTH_MIN,
      	max: _WIDTH_MAX
    });
    
    $( "#height" ).spinner({
      	min: _HEIGHT_MIN,
      	max: _HEIGHT_MAX
    });
});

$(".style-chooser").live("click", function(){
	update_sample_color();
	update_preview();
});

$(".one-color").live("click", function(){
	$("#color-sample").css('background-color', $(this).css('background-color'));
	$("#color-sample").attr("hue", $(this).attr("hue"));
	update_preview();
});

function load_default_preview() {
	var previewElem = $("#widget-preview")[0];
	var styleId = parseInt($('input.style-chooser:radio:checked').val());
	
	var widget_style = _widget_styles[styleId];
	var _preview_widget = new _fyiWidget();
	_preview_widget.attachToElem(previewElem, _publisher_refnum, widget_style.widget_css_class,  widget_style.colors);
	$(previewElem).attr("style", widget_style.defaultBoxCssStyle());
	
	$("#show-border").prop('checked', true);
	if(widget_style.hasWidgetCssClass("small-font")) {
		$("#small-font").prop('checked',true);
	} else if (widget_style.hasWidgetCssClass("large-font")) {
		$("#large-font").prop('checked',true);
	} else {
		$("#normal-font").prop('checked',true);
	}
	
	$("#width").val(widget_style.box_width);
	$("#height").val(widget_style.box_height);
	
	var html = widget_style.getResultingHtml("/board?", "fyi:board", "Hire top " + _publisher_name + " users");
	$("#code-input").val(html.html);
}

function update_preview() {
	var previewElem = $("#widget-preview")[0];
	var styleId = parseInt($('input.style-chooser:radio:checked').val());
	var widget_style = _widget_styles[styleId];
	
	var width = parseInt($("#width").val());
	if(isNaN(width) || width < _WIDTH_MIN || width > _WIDTH_MAX) {
		$("#width").validationEngine('showPrompt', 'The value is out of the range from ' + _WIDTH_MIN + ' to ' + _WIDTH_MAX + '. Using default.', 'error', 'topRight', true);
		$("#width").val(widget_style.box_width);
		width = widget_style.box_width;
	}
	var height = parseInt($("#height").val());
	if(isNaN(height) || height < _HEIGHT_MIN || height > _HEIGHT_MAX) {
		$("#height").validationEngine('showPrompt', 'The value is out of the range from ' + _HEIGHT_MIN + ' to ' + _HEIGHT_MAX + '. Using default.', 'error', 'topRight', true);
		$("#height").val(widget_style.box_height);
		height = widget_style.box_height
	}
	
	var newBorderHue = parseInt($("#color-sample").attr("hue"));
	var newColors = widget_style.shiftColorsHue(newBorderHue);
	
	var _preview_widget = new _fyiWidget();
	_preview_widget.attachToElem(previewElem, _publisher_refnum, 
		widget_style.getCustomizedWidgetCss(["small-font", "normal-font", "large-font"], [$('#font-size input:radio:checked').val()]), 
		newColors);
	var showBorder = $("#show-border").is(":checked");
	$(previewElem).attr("style", widget_style.boxCssStyle(showBorder, newBorderHue, width, height));
	
	var html = widget_style.getResultingHtml("/board?", "fyi:board", "Hire  top " + _publisher_name + " users", showBorder, newBorderHue, $('#font-size input:radio:checked').val(), width, height, []);
	$("#code-input").val(html.html);
}

function update_sample_color() {
  	var styleId = parseInt($('input.style-chooser:radio:checked').val());
	var widget_style = _widget_styles[styleId];
	var rgb = widget_style.getBorderColor();
	var hsl = rgbStrToHSL(rgb);
	$("#color-sample").css('background-color', rgb);
	$("#color-sample").attr("hue", hsl.h);
	
	$("#color-picker").empty();
	for(var col = 0; col < 6; col++) {
		var rowObj = $("<div class='color-picker-row clearfix'></div>");
		for(var row = 0; row < 6; row++){
			var newHue = (col * 6 + row) * 10;
			$(rowObj).append("<div class='one-color' hue='" + newHue + "' style='background-color: " + new HSLColour(newHue, hsl.s, hsl.l).getCSSHexadecimalRGB() + "'></div>");
		}
		$("#color-picker").append(rowObj);
	}
}
