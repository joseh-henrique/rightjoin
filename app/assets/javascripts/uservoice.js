 /*For efficiency this could be moved to the bottom of the relevant pages rather than being included in the application.js*/
 
UserVoice=window.UserVoice||[];(function(){var uv=document.createElement('script');uv.type='text/javascript';uv.async=true;uv.src='//widget.uservoice.com/nmIxv0x9rDknQVtyskKOQ.js';var s=document.getElementsByTagName('script')[0];s.parentNode.insertBefore(uv,s)})();
  
UserVoice.push(['set', {
  accent_color: '#448dd6',
  trigger_color: 'white',
  trigger_background_color: 'rgba(46, 49, 51, 0.6)'
}]);
 
  	 
// Uservoice widget is not enabled by default; the Uservoice widget is accessed by pressing an  element with this ID.

function init_uservoice_contact(uv_contact_element_selector, large_size){
	large_size = typeof large_size !== 'undefined' ? large_size : false; 
	var contact_elem= $(uv_contact_element_selector);
	var params = { mode: 'contact' };
	
	 if (large_size) {
		params['width'] = '650px';
		params['height'] = '588px';
		params['target'] = false;
		params['screenshot_enabled'] = false;
		params['contact_title'] ="Ask for info or a demo";	
	}
	
	if (contact_elem.length > 0) {
		UserVoice.push(['addTrigger',uv_contact_element_selector, params]);
	}
}	

init_uservoice_contact('#uservoice-contact'); /* TODO Call this only on pages with #uservoice-contact element is used: Where  uservoice_contact_link is called.*/
		

 