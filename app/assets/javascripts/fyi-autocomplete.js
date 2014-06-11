// location autocomplete (google)
$.widget("ui.googleAddressPicker", {
	/*
	 * Next line contains an object containing all the default options
	 * that you want to use in your plugin
	 */
	options : {
		country: "us",
		types: "(cities)",
		guess_after_x_chars: 3,
		keep_location_components: "['administrative_area_level_1', 'locality']",
		placeholder: "san francisco, california"
	},

	/*
	 * Then we have the _create function
	 * This function gets called as soon as your widget is invoked
	 * Think of it as the initialization function.
	 */
	_init : function() {
		var self = this;
		
		self.selected_place = null;

		var search_options = {
			types : [self.option("types")],
			componentRestrictions : {
				country : self.option("country")
			}
		};
		
		var input_class = "fyi_address_picker";
		$(self.element).addClass(input_class);
	    
	    $(self.element).attr("placeholder", "e.g., " + self.option('placeholder'));
		
		$(self.element).on('blur', function() {
		    setTimeout(function(){ 
		    	self._geocodeAddress();
			}, 300);
		});
		
		$(self.element).on('input', function() {
		    self.selected_place = null;
		    self._setLoadingStyle(true);
		}).keypress(function(e) {
	     	if(e.keyCode == 13) {
	       		e.preventDefault();
	     	}
    	});

		self.geocoder = new google.maps.Geocoder();
		self.autocompleteService = new google.maps.places.AutocompleteService();
		self.autocomplete = new google.maps.places.Autocomplete(self.element[0], search_options);
		
		google.maps.event.addListener(self.autocomplete, 'place_changed', function() {
			var tmpPlace = this.getPlace();
			if (tmpPlace && tmpPlace.geometry) {
				self.selected_place = tmpPlace;
				self._setLoadingStyle(true);
			} else {
				self.selected_place = null;
			}
			
			$(self.element[0]).trigger("blur");
	    });
	},
	
	_setLoadingStyle : function(isLoading) {
	    if(isLoading) {
	    	$(this.element).addClass( "loading" );
	    } else {
	    	$(this.element).removeClass( "loading" );
	    }
	},
	
	_geocodeAddress : function() {
		var self = this;
		
		if(self.selected_place) {
			var suggested = self.selected_info();
			$(self.element[0]).val(suggested.name);
			self._setLoadingStyle(false);
			
			$(self.element[0]).trigger("complete");
		} else {
	    	var address = $.trim($(self.element[0]).val());
	    	if(address.length >= self.option("guess_after_x_chars")){
				var prediction_service_options = {
					types : [self.option("types")],
					componentRestrictions : {
						country : self.option("country")
					},
					input: address
				};
				
				self.autocompleteService.getPlacePredictions(prediction_service_options, function(predictions, status){
					if (!predictions || status != google.maps.places.PlacesServiceStatus.OK) {
						$(self.element[0]).val("");
						self._setLoadingStyle(false);
						
						$(self.element[0]).trigger("complete");
					} else {
						var geocode_options = {
							'address': predictions[0].description,
							componentRestrictions : {
								country: self.option("country")
							}					
						};
					  	self.geocoder.geocode(geocode_options, function(results, status) {
						    if (status == google.maps.GeocoderStatus.OK) {
						    	self.selected_place = results[0];
						    	$(self.element[0]).val(self.selected_info().name);
							    self._setLoadingStyle(false);
						    } else {
						    	// something went wrong
						    	self._setLoadingStyle(true);
						    }
						    
						    $(self.element[0]).trigger("complete");
					  	});
					}			
				});
			} else {
				$(self.element[0]).val("");
				self._setLoadingStyle(false);
				
				$(self.element[0]).trigger("complete");
			}
		}
	},		

	selected: function (){
		return this.selected_place;
	},
	
	selected_info: function () {
		var res = null;
		
		if(this.selected_place) {
			res = {};
			
			var filtered_address_components = [];
			var keep_types = this.option("keep_location_components");
			
	        var address_components = this.selected_place.address_components;
	        for (var j = 0 ; j < address_components.length ; ++j) {
				var address_component = address_components[j];
				var should_keep = false;
				for (var k = 0; k < address_component.types.length; ++k) {
					var component_type = address_component.types[k];
					
					if($.inArray(component_type, keep_types) != -1) {
						should_keep = true;
						break;
					}
				}
				
				if(should_keep && address_component.long_name) {
					filtered_address_components.push(address_component.long_name);
				}
	         }
	         
	         res.name = filtered_address_components.join(", ").toLowerCase();	
	         res.lat = this.selected_place.geometry.location.k;
	         res.lng = this.selected_place.geometry.location.A;
		}
		
		return res;
	}
});


// location autocomplete (geonames)
$.widget( "ui.locationcomplete", $.ui.autocomplete, {
	_init: function() {
		var that = this;
		
		this.element.data('autocomplete', this.element.data('locationcomplete'));
		this.last_suggestions = null;
		this.selected_suggestion = null;
		
		this.element.focus(function() {
			if($(this).val()==""){
			 	$(this).locationcomplete("search","");
			}
		});
		
		this.element.blur(function() {
			that._normalize_value($(this));
    	});
    	
    	this.element.keypress(function(e) {
	     	if(e.keyCode == 13) {
	       		e.preventDefault();
	     	}
    	});
    	
    	$(this.element).attr("placeholder", "e.g., " + this.element.data('locationcomplete').option('placeholder'));
	},
	_renderMenu: function( ul, items ) {
    	var autocomplete = this.element.data( "locationcomplete" );
    	var defaultListTitle = autocomplete.option('defaultListTitle');		
		
		var self = this;
		var term = self.term;
		if(term == ""){
		 	ul.append( "<li class='ui-autocomplete-category'>" + defaultListTitle + "</li>" );
		}
		$.each( items, function( index, item ) {
			self._renderItemData( ul, item );
		});
	},
	_normalize_value: function ($input){
		var suggested = null;
		var term = $input.val().toLowerCase().replace(/[\s,]/g, '');
		if (this.last_suggestions != null) {
			$.each( this.last_suggestions, function( index, item ) {
				if(term == item.label.toLowerCase().replace(/[\s,]/g, '') || 
					term == item.shortLabel.toLowerCase().replace(/[\s,]/g, '')) {
					suggested = item;
				}
			});
		}

        var val = $input.val();
        if (suggested != null) {
			val = suggested.label;
        }
        
        this.selected_suggestion = suggested;
        $input.val(val.toLowerCase());
	},
	selected: function (){
		if (this.element.val()=="")
			return null;
		return this.selected_suggestion;
	},
    options: {
    	minLength: 0,
    	defaultOpts: [],
    	defaultListTitle: "Type or choose from the list:",
    	country_code: "USA",//not used, instead 'us' comes from server
    	placeholder: "san francisco, california",
		source: function( request, response ) {
			if (!$(this.element).is(":focus")) {
				response({});
			} else {
				this.selected_suggestion = null;
				var parts = request.term.split(",");
				var term = parts[0];
				if(term.length == 0 && this.option('defaultOpts').length > 0){
					response(this.option('defaultOpts'));
				} else if (parts.length > 1 && this.last_suggestions != null) {
					response({});
				} else {
					$.ajax({
						context: this,
						url: "http://ws.geonames.org/searchJSON",
						dataType: "jsonp",
						data: {
							username: "fiveyearitch",
							featureClass: "P",
							style: "full",
							maxRows: 8,
							country: this.option('country_code'),
							name_startsWith: term
						},
						success: function( data ) {
							var use_province_s = this.option('use_province');
	
							var use_province = (use_province_s===null || use_province_s === 'true');
							var suggests = $.map( data.geonames, function( item ) {
								var province_long = (item.adminName1 ? ", " + item.adminName1 : "");
								var province_short = (item.adminCode1 ? ", " + item.adminCode1 : "");
								return {
									label: item.name + (use_province ? province_long:""),
									value: item.name + (use_province ? province_long:""),
									shortLabel: item.name + (use_province ? province_short:""),
									lat: item.lat,
									lng: item.lng
								};
							});
							response(suggests);
							if (suggests.length > 0) {
								this.last_suggestions = suggests;
							}
						}
					});
				}
			}
		},
		open: function() {
	   		$(this).locationcomplete('widget').css('z-index', 100);           
		},	
		focus: function() {
			// prevent value inserted on focus
			return false;
		},
		select: function( event, ui ) {
	  		$($(this)[0]).change();
		}
    }
});

// autocomplete
$.widget("ui.cachedautocomplete", $.ui.autocomplete, {
	_init: function() {
		this.cache = {};
		this.noResultsPrefixes = [];
		this.element.data('autocomplete', this.element.data('cachedautocomplete'));
		
		this.element.focus(function() {
			if($(this).val()==""){
				if(!$(this).cachedautocomplete('widget').is(':visible')) {
		        	$(this).cachedautocomplete('search','');
		    	}
			}
		});
		
		this.element.blur(function() {
	        $(this).val($(this).val().toLowerCase());
    	});
    	
    	this.element.keypress(function(e) {
	     	if(e.keyCode == 13) {
	       		e.preventDefault();
	     	}
    	});
	},
	_extractLast: function ( term ) {
		return term.split( /,\s*/ ).pop();
	},
	_startsWithPrefixInList: function(term, listOfPrefixes) {
		for (i in listOfPrefixes) {
			if(term.substring(0, listOfPrefixes[i].length).toLowerCase() == listOfPrefixes[i]){
				return true;
			}
		}
		return false;
	},
	_findCached: function(term, extraParamVal, cachedSuggests) {
		for (var cachedTerm in cachedSuggests) {
			if(cachedTerm == this._buildHashKey(term, extraParamVal)){
				return {"term":term, "suggest":cachedSuggests[cachedTerm]};
			}
		}
		return null;
	},	
	_buildHashKey: function(term, extraParamVal) {
		return "[" + term + "][" + extraParamVal + "]".toLowerCase();
	},	
	_renderMenu: function( ul, items ) {
    	var autocomplete = this.element.data( "cachedautocomplete" );
    	var defaultListTitle = autocomplete.option('defaultListTitle');				
		
		var self = this;
		var term = self.term.split(/,\s*/).pop();
		if(term.length <= 1){
		 	ul.append( "<li class='ui-autocomplete-category'>" + defaultListTitle + "</li>" );
		}
		$.each( items, function( index, item ) {
			self._renderItemData( ul, item );
		});
	},
    options: {
    	url: "",
    	defaultOpts: null,
    	minLength: 0,
    	multiValue: false,
    	sequentialMatching: true,
    	numOfOpts: 8,
    	defaultListTitle: "Type or choose from the list:",
    	extraParam: "", // keeps element Id which value is sent as an extra parameter with each request
		source: function(request, response) {
			var term = request.term.toLowerCase();
			var multiValue = this.option('multiValue');
			var sequentialMatching = this.option('sequentialMatching');
			var numOfOpts = this.option('numOfOpts');
			var extraParamElemId = this.option('extraParam');
			
			var extraParamVal = "";
		    var extraParamURLPart = "";
        	if (extraParamElemId != "") {
        		extraParamVal = $(extraParamElemId).val();
        		extraParamURLPart = "&extra=" + encodeURIComponent(extraParamVal);
        	}

			if(multiValue) {
				term = term.split(/,\s*/).pop();
			}
			if(term.length <= 1 && this.option('defaultOpts') != null){
				response(this.option('defaultOpts'));
			} else {
				var cachedSuggests = this._findCached(term, extraParamVal, this.cache);
				if (cachedSuggests != null) {
					response(cachedSuggests["suggest"]);
				} else if (sequentialMatching && this._startsWithPrefixInList(term, this.noResultsPrefixes)) {
					response( [] );
				} else {
		        	$(this).addClass("ui-autocomplete-loading");
			        $.ajax({
			        	context: this,
			            url: this.option('url'),
			            data: "term=" + encodeURIComponent(term) + "&num=" + numOfOpts + extraParamURLPart,
			            success: function(data) {
			            	var obj = $.parseJSON(data);
			            	if(obj.length === 0) {
			            		this.noResultsPrefixes.push(term);
			            	} else {
			            		this.cache[ this._buildHashKey(term, extraParamVal) ] = obj;
			            	}
			                response(obj);
			                $(this).removeClass("ui-autocomplete-loading");
			            },
			            error: function() {
			                $(this).removeClass("ui-autocomplete-loading");
			            }
			        });
		        }
	      }
	   },
	   open: function() {
	        var $this = $(this),
            autocomplete = $this.data( "autocomplete" ),
            menu = autocomplete.menu;
            
			$this.cachedautocomplete('widget').css('z-index', 100);           
    	},
		focus: function() {
			// prevent value inserted on focus
			return false;
		},
    	select: function( event, ui ) {
    		$($(this)[0]).change();
    		
    		var autocomplete = $(this).data( "autocomplete" );
    		var multiValue = autocomplete.option('multiValue');
    		if(multiValue) {
				var terms =  this.value.split( /,\s*/ );
				// remove the current input
				terms.pop();
				// add the selected item
				terms.push( ui.item.value );
				// add placeholder to get the comma-and-space at the end
				terms.push( "" );
				this.value = terms.join( ", " );
				return false;
			}
			return true;
		}
    }
});
