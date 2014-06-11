//= require widget-config

// extend _fyiWidget
_fyiWidget.prototype.attachById = function(boxId, bodyClass, colors, widgetStyle){
	var container = document.getElementById(boxId);
	if(container != null){
		this.attachToElem(container, bodyClass, colors, widgetStyle);
	}
	return container;
}

_fyiWidget.prototype.attachToElem = function (elem, bodyClass, colors, widgetStyle) {
	widgetStyle = widgetStyle == undefined ? "" : widgetStyle;
	bodyClass = bodyClass == undefined ? "" : bodyClass;
	colors = colors == undefined ? "" : colors;
	
	this.replaceElemContentWithIframe(elem, _fyi_domain + _widget_path + "&publisher=" + encodeURIComponent(_publisher_refnum) + "&class=" + encodeURIComponent(bodyClass) + "&colors=" + encodeURIComponent(colors) + "&style=" + encodeURIComponent(widgetStyle));
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
var _WIDTH_MIN = 450;
var _WIDTH_MAX = 1200;
var _HEIGHT_MIN = 150;
var _HEIGHT_MAX = 900;
$(function() {
	update_sample_color();
	load_default_preview();

  	$( "#show-border" ).click(function(event){
  		update_preview();
  	});
  	
  	$( "#show-all" ).click(function(event){
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

    $( "#width" ).spinner({
      	min: _WIDTH_MIN,
      	max: _WIDTH_MAX
    });
    
    $( "#height" ).spinner({
      	min: _HEIGHT_MIN,
      	max: _HEIGHT_MAX
    });
});

$(".one-color").live("click", function(){
	$("#color-sample").css('background-color', $(this).css('background-color'));
	$("#color-sample").attr("hue", $(this).attr("hue"));
	update_preview();
});

function load_default_preview() {
	var previewElem = $("#widget-preview")[0];

	var _preview_widget = new _fyiWidget();
	_preview_widget.attachToElem(previewElem, _widget_style.widget_css_class,  _widget_style.colors);
	$(previewElem).attr("style", _widget_style.defaultBoxCssStyle());
	
	update_sample_color();
	
	$("#show-border").prop('checked', true);
	$("#show-all").prop('checked', $.inArray("solo", _widget_style.widget_css_class.split(" ")) == -1);
	$("#width").val(_widget_style.box_width);
	$("#height").val(_widget_style.box_height);
	
	var html = _widget_style.getResultingHtml(this._widget_path, "fyi:we-are-hiring", "We are hiring");
	$("#code-input").val(html.html);
	$("#url-input").val(html.url);
}

function update_preview() {
	var previewElem = $("#widget-preview")[0];

	var width = $.trim($("#width").val());
	if (width != "") {
		width_num = parseInt(width);
		if(isNaN(width_num) || width_num < _WIDTH_MIN || width_num > _WIDTH_MAX) {
			$("#width").validationEngine('showPrompt', 'The value is out of the range from ' + _WIDTH_MIN + ' to ' + _WIDTH_MAX + '. Using default.', 'error', 'topRight', true);
			$("#width").val(_widget_style.box_width);
			width = _widget_style.box_width;
		}
	}
	var height = parseInt($("#height").val());
	if(isNaN(height) || height < _HEIGHT_MIN || height > _HEIGHT_MAX) {
		$("#height").validationEngine('showPrompt', 'The value is out of the range from ' + _HEIGHT_MIN + ' to ' + _HEIGHT_MAX + '. Using default.', 'error', 'topRight', true);
		$("#height").val(_widget_style.box_height);
		height = _widget_style.box_height
	}
	
	var newBorderHue = parseInt($("#color-sample").attr("hue"));
	var newColors = _widget_style.shiftColorsHue(newBorderHue);
	
	var moreClasses = $('#show-all').is(":checked")? [] : ["solo"]
	
	var _preview_widget = new _fyiWidget();
	_preview_widget.attachToElem(previewElem, 
		_widget_style.getCustomizedWidgetCss(moreClasses, moreClasses),
		newColors);
	var showBorder = $("#show-border").is(":checked");
	$(previewElem).attr("style", _widget_style.boxCssStyle(showBorder, newBorderHue, width, height));
	
	var html = _widget_style.getResultingHtml(this._widget_path, "fyi:we-are-hiring", "We are hiring", showBorder, newBorderHue, undefined, width, height, moreClasses);
	$("#code-input").val(html.html);
	$("#url-input").val(html.url);
}

function update_sample_color() {
	var rgb = _widget_style.getBorderColor();
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
