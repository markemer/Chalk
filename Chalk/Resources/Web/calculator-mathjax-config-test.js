function callExternal_config(args)
{
  var functionName = args[0];
  var functionArgs = (args.length <= 1) ? [] : args.slice(1);
  if ((typeof calculatorDocument !== 'undefined') && (calculatorDocument != null))
    calculatorDocument[functionName].apply(calculatorDocument, functionArgs);
  else if (window.calculatorDocument != null)
    window.calculatorDocument[functionName].apply(window.calculatorDocument, functionArgs);
  else if ((typeof webkit !== 'undefined') && (webkit != null) && (webkit.messageHandlers != null) && (webkit.messageHandlers.calculatorDocument != null))
  {
    try{
      webkit.messageHandlers.calculatorDocument.postMessage(args);
    }
    catch(err){
      console.log('can not reach native code');
    }
  }
}
//end callExternal_config()

var enableDOMLog_config = true;
var enableConsoleLog_config = true;
var enableObjCConsoleLog_config = true;

function debugLog_config(message)
{
  if (enableDOMLog_config)
  {
    var logger = document.getElementById('logger');
    if (logger != null)
      logger.appendChild(document.createTextNode(message+'\n'));
  }//end if (enableDOM_log)
  if (enableConsoleLog_config)
    console.log(message);
  if (enableObjCConsoleLog_config)
    callExternal(['jsConsoleLog_', message]);
}
//end debugLog_config()

function configureMathJax(path)
{
  window.MathJax = {
    loader: {
      ready: function () {
        window.MathJax.loader.defaultReady();
      },
      failed: function (err) {
        debugLog_config('# Loader failed: ' + err.message);
      }
    },
    options: {
      renderActions: {
        addMenu: [],
        checkLoading: [],
        assistiveMml: []
      },
      ignoreHtmlClass: 'tex2jax_ignore',
      processHtmlClass: 'tex2jax_process',
      compileError: function (doc, math, err) {
        debugLog_config('compile:'+'doc'+'<'+doc+'>'+'math'+'<'+math+'>'+'err'+'<'+err+'>');
        callExternal_config(['mathjaxReportedError_', 'compile:'+'doc'+'<'+doc+'>'+'math'+'<'+math+'>'+'err'+'<'+err+'>']);
      },
      typesetError: function (doc, math, err) {
        debugLog_config('typeset:'+'doc'+'<'+doc+'>'+'math'+'<'+math+'>'+'err'+'<'+err+'>');
        callExternal_config(['mathjaxReportedError_', 'compile:'+'doc'+'<'+doc+'>'+'math'+'<'+math+'>'+'err'+'<'+err+'>']);
      }
    },
    startup: {
      typeset: true,
      ready: function() {
        window.MathJax.startup.defaultReady();
        window.MathJax.startup.promise.then(function () {
          callExternal_config(['mathjaxDidFinishLoading']);
        });
      }
    },
    svg: { fontCache : 'none'},
  };
  
  var script = document.createElement('script');
  script.src = path;
  script.async = true;
  script.onload = function () {
  }
  script.onerror = function (err) {
    debugLog_config('MathJax failed to load: ' + err.message + '\n>');
  }
  document.head.appendChild(script);
}
//end configureMathJax()

