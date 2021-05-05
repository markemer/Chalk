function callExternal(args)
{
  var functionName = args[0];
  var functionArgs = (args.length <= 1) ? [] : args.slice(1);
  if ((typeof rendererDocument !== 'undefined') && (rendererDocument != null))
    rendererDocument[functionName].apply(rendererDocument, functionArgs);
  else if (window.rendererDocument != null)
    window.rendererDocument[functionName].apply(window.rendererDocument, functionArgs);
  else if ((typeof webkit !== 'undefined') && (webkit != null) && (webkit.messageHandlers != null) && (webkit.messageHandlers.rendererDocument != null))
  {
    try{
      webkit.messageHandlers.rendererDocument.postMessage(args);
    }
    catch(err){
      console.log('can not reach native code');
    }
  }
}
//end callExternal()

var enableDOMLog = false;
var enableConsoleLog = false;
var enableObjCConsoleLog = false;

function debugLogEnable(args)
//enableConsoleLog, enableObjCConsoleLog
{
  var argsArray = (args.length > 1) ? args : args[0];
  enableConsoleLog = argsArray[0];
  enableObjCConsoleLog = argsArray[1];
}
//end debugLogEnable()

function debugLog(message)
{
  if (enableDOMLog)
  {
    var logger = document.getElementById('logger');
    if (logger != null)
      logger.appendChild(document.createTextNode(message+'\n'));
  }//end if (enableDOMLog)
  if (enableConsoleLog)
    console.log(message);
  if (enableObjCConsoleLog)
    callExternal(['jsConsoleLog_', message]);
}
//end debugLog()

function addElement(parent, tag, idName, className, cssProperties, content)
{
  var element = document.createElement(tag);
  $(parent).append(element);
  if (idName != null)
    element.id = idName;
  if (className != null)
    $(element).addClass(className);
  if (cssProperties != null)
    $(element).css(cssProperties);
  if (content != null)
    element.innerHTML = content;
  return element;
}
//end addElement()

function getAllJax(parent)
{
  var result = MathJax.startup.document.getMathItemsWithin(parent);
  return result;
}
//end getAllJax()

function preload()
{
  var entry = this.document.getElementById('entry');
  var divEntryInputTeX = addElement(entry, 'div', null, 'input', {'display':'block'}, '\\(\\)');
}
//end preload()

function render(inputTeXString)
{
  var entry = this.document.getElementById('entry');
  var divEntryInput = $(entry).find('div.input')[0];
  if (divEntryInput != null)
  {
    divEntryInput.innerHTML = inputTeXString;
    try{
      window.MathJax.typeset([divEntryInput]);
    }
    catch(err){
      debugLog('typeset error : '+error.message()+'\nstack:'+error.stack);
    }
    callExternal(['mathjaxDidEndTypesetting_', $(divEntryInput).html()]);
  }//end if (divEntryInput != null)
}
//end render()
