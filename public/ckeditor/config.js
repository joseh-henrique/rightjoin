CKEDITOR.editorConfig = function( config )
{
  config.height = 350;
  config.toolbar_Basic =
  [
      [ 'Bold','Italic','TextColor','FontSize','-','NumberedList','BulletedList','-','Outdent','Indent','-','Maximize' ]
  ];  
  config.toolbar = 'Basic';
  config.fontSize_sizes = '16/16px;24/24px;36/36px;';
  config.uiColor = '#E4F5F5';
  config.removePlugins = 'elementspath,tabletools,liststyle,contextmenu';
  config.resize_enabled = false;
  config.forcePasteAsPlainText = true;
  config.disableNativeSpellChecker = false;
};
