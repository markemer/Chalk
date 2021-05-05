var _localizedStringsTable = {};

function callExternal(args)
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
  $('html')[0].onclick = function(event) {
    selectionSetEntry(null, null);
    event.stopPropagation();
  };//end divEntry.onclick()

  $.fn.scrollMinimal = function(smooth) {
    var cTop = this.offset().top;
    var cHeight = this.outerHeight(true);
    var windowTop = $(window).scrollTop();
    var visibleHeight = $(window).height();

    if (cTop < windowTop) {
      if (smooth) {
        $('body').animate({'scrollTop': cTop}, 'slow', 'swing');
      } else {
        $(window).scrollTop(cTop);
      }
    } else if (cTop + cHeight > windowTop + visibleHeight) {
      if (smooth) {
        $('body').animate({'scrollTop': cTop - visibleHeight + cHeight}, 'slow', 'swing');
      } else {
        $(window).scrollTop(cTop - visibleHeight + cHeight);
      }
    }
  };//end $.scrollMinimal()
  $.fn.observe = function(eventName, callback) {
      return this.each(function(){
          var el = this;
          $(document).on(eventName, function(){
              callback.apply(el, arguments);
          })
      });
  };//end $.fn.observe()
}
//end preload()

function isNullOrEmpty(string)
{
  var result = (string == null) || (string.length == 0);
  return result;
}
//end isNullOrEmpty()

function isSimpleString(string)
{
  var result = isNullOrEmpty(string);
  if (!result)
  {
    var re = /^([\s\w\+\-\*\!\&\|\.\u00B1\u1D70B\u221E\u2026]|(\^\^)|(\\ )|(\&nbsp\;))+$/;
    result = re.test(string);
  }//end if (!result)
  return result;
}
//end isSimpleString()

function clip(inf, value, sup)
{
  var result = (value<inf) ? inf : (sup<value) ? sup : value;
  return result;
}
//end clip()

function isDescendantOf(elementChild, elementParent)
{
  var result = false;
  var currentElement = elementChild;
  if (currentElement && elementParent)
  while(!result && (currentElement != null))
  {
    result = (currentElement == elementParent);
    currentElement = currentElement.parentNode;
  }
  return result;
}
//end isDescendantOf()

function getLocalizedString(key)
{
  var result = key;
  if (key != null)
    result = _localizedStringsTable[key];
  if (result == null)
    result = key;
  return result;
}
//end getLocalizedString()

function setLocalizedString(key, value)
{
  if (key != null)
    _localizedStringsTable[key] = value;
}
//end setLocalizedString()

function switchEntryContent(divEntryContentHTML, divEntryContentTeX)
{
  var isContentHTMLHidden = (divEntryContentHTML.style.display == 'none');
  if (isContentHTMLHidden)
  {
    divEntryContentHTML.style.display = 'block';
    divEntryContentTeX.style.display = 'none';
  }//end if (isContentHTMLHidden)
  else//if (!isContentHTMLHidden)
  {
    divEntryContentHTML.style.display = 'none';
    divEntryContentTeX.style.display = 'block';
  }//end if (!isContentHTMLHidden)
}
//end switchEntryContent()

var selectionAge = 0;
var mathjaxGroupIndex = 0;

function selectionGetEntry()
{
  return selectionGetEntryForAge(selectionGetAge());
}
//end selectionGetEntry()

function selectionSetEntry(entry, flag)
{
  var $entries = $('div.entry');
  var count = ($entries == null) ? 0 : $entries.length;
  selectionAge = 0;
  $.each($entries, function(index, value) {
    if (value == entry)
    {
      $(value).addClass('entry_selected');
      selectionAge = count-index;
    }//end if (value == entry)
    else//if (value != entry)
    {
      $(value).removeClass('entry_selected');
    }//end if (value != entry)
  });//end for each entry

  if (entry != null)
    $(entry).scrollMinimal();

  callExternal(['webViewEntrySelectionDidChangeToAge_flag_', selectionAge, flag]);
}
//end selectionSetEntry()

function selectionGetAge()
{
  return selectionAge;
}
//end selectionGetAge()

function selectionSetAge(args)
{
  var value = Array.isArray(args) ? args[0] : args;
  if (value != selectionAge)
  {
    selectionAge = value;
    var entry = selectionGetEntry();
    selectionSetEntry(entry, null);
  }//end if (value != selectionAge)
}
//end selectionSetAge()

function selectionGetEntryForAge(age)
{
  var $entries = $('div.entry');
  var count = ($entries == null) ? 0 : $entries.length;
  var entry = (age>0) && (age<=count) ? $entries[count-age] : null;
  return entry;
}
//end selectionGetEntryForAge()

function selectionSetEntryForAge(age)
{
  var $entries = $('div.entry');
  var count = ($entries == null) ? 0 : $entries.length;
  var entry = (age>0) && (age<=count) ? $entries[count-age] : null;
  selectionSetEntry(entry, null);
}
//end selectionSetEntryForAge()

function selectionSetAgeOlder()
{
  var $entries = $('div.entry');
  var nextSelectionAge = clip(0, selectionAge+1, $entries.length)
  if (selectionAge != nextSelectionAge)
  {
    selectionSetEntryForAge(nextSelectionAge);
  }//end if (selectionAge != nextSelectionAge)
  return nextSelectionAge;
}
//end selectionSetAgeOlder()

function selectionSetAgeNewer()
{
  var $entries = $('div.entry');
  var nextSelectionAge = clip(0, selectionAge-1, $entries.length)
  if (selectionAge != nextSelectionAge)
  {
    selectionSetEntryForAge(nextSelectionAge);
  }//end if (selectionAge != nextSelectionAge)
  return nextSelectionAge;
}
//end selectionSetAgeNewer()

function getAgeForEntry(entry)
{
  var $entries = $('div.entry').toArray();
  var count = ($entries == null) ? 0 : $entries.length;
  var index = $entries.indexOf(entry);
  var age = count-index;
  return age;
}
//end getAgeForEntry()

function getEntryForAge(age)
{
  var $entries = $('div.entry').toArray();
  var count = ($entries == null) ? 0 : $entries.length;
  var index = (count-age);
  return $entries[index];
}
//end getEntryForAge()

function getEntryForUid(uid)
{
  var result = this.document.getElementById('entry'+'_'+uid.toString());
  return result;
}
//end getEntryForUid()

function getUidForEntry(divEntry)
{
  var result = null;
  var idAsString = divEntry.id.toString();
  var myRegexp = /entry\_([0-9]+)/g;
  var match = myRegexp.exec(idAsString);
  result = match[1];
  return result;
}
//end getUidForEntry()

function getEntryIndexForUid(uid)
{
  var entry = getEntryForUid(uid);
  var $entries = $('div.entry').toArray();
  var index = $entries.indexOf(entry);
  return index;
}
//end getEntryIndexForUid()

function webViewEntryDidSwitchDisplay()
{
  callExternal(['webViewEntryDidSwitchDisplay']);
}
//end webViewEntryDidSwitchDisplay()

function removeAllEntries()
{
  var $entries = $('div.entry').each(function(index) {
      var divEntry = this;
      divEntry.remove();
  });
  numerateEntries();
  selectionSetEntryForAge(0);
}
//end removeAllEntries

var disableTypesetting = false;

function addEntries(args)
{
  var entries = (args.length > 0) && Array.isArray(args[0]) ? args[0] : args;
  disableTypesetting = true;
  beginMathjaxGroup();
  var count = entries.length;
  for(var i = 0 ; i<count ; ++i)
  {
    var entry = entries[i];
    addEntry([0, entry]);
  }//end for each entry
  disableTypesetting = false;
  try{
    window.MathJax.typeset();
  }
  catch(err){
    debugLog('typeset error : '+error.message()+'\nstack:'+error.stack);
  }
  endMathjaxGroup();
}
//end addEntries()

function addEntry(args)
//age, entryDict
{
  beginMathjaxGroup();
  
  var argsArray = (args.length > 1) ? args : args[0];
  var age = argsArray[0];
  var entryDict = argsArray[1];

  var uid = null;
  var customAnnotation = null;
  var customAnnotationVisible = null;
  var inputRawHTMLString = null;
  var inputInterpretedHTMLString = null;
  var inputInterpretedTeXString = null;
  var outputHTMLString = null;
  var outputTeXString = null;
  var outputHtmlCumulativeFlags = null;
  var output2HTMLString = null;
  var output2TeXString = null;
  var output2HtmlCumulativeFlags = null;

  var isObjecEntry = (entryDict != null) && (entryDict.objectForKey_ != null);
  if (!isObjecEntry)
  {
    uid = entryDict['uid'];
    customAnnotation = entryDict['customAnnotation'];
    customAnnotationVisible = entryDict['customAnnotationVisible'];
    inputRawHTMLString = entryDict['inputRawHTMLString'];
    inputInterpretedHTMLString = entryDict['inputInterpretedHTMLString'];
    inputInterpretedTeXString = entryDict['inputInterpretedTeXString'];
    outputHTMLString = entryDict['outputHTMLString'];
    outputTeXString = entryDict['outputTeXString'];
    outputHtmlCumulativeFlags = entryDict['outputHtmlCumulativeFlags'];
    output2HTMLString = entryDict['output2HTMLString'];
    output2TeXString = entryDict['output2TeXString'];
    output2HtmlCumulativeFlags = entryDict['output2HtmlCumulativeFlags'];
  }//end if (!isObjecEntry)
  else//if (isObjecEntry)
  {
    uid = entryDict.objectForKey_('uid');
    customAnnotation = entryDict.objectForKey_('customAnnotation');
    customAnnotationVisible = entryDict.objectForKey_('customAnnotationVisible');
    inputRawHTMLString = entryDict.objectForKey_('inputRawHTMLString');
    inputInterpretedHTMLString = entryDict.objectForKey_('inputInterpretedHTMLString');
    inputInterpretedTeXString = entryDict.objectForKey_('inputInterpretedTeXString');
    outputHTMLString = entryDict.objectForKey_('outputHTMLString');
    outputTeXString = entryDict.objectForKey_('outputTeXString');
    outputHtmlCumulativeFlags = entryDict.objectForKey_('outputHtmlCumulativeFlags');
    output2HTMLString = entryDict.objectForKey_('output2HTMLString');
    output2TeXString = entryDict.objectForKey_('output2TeXString');
    output2HtmlCumulativeFlags = entryDict.objectForKey_('output2HtmlCumulativeFlags');
  }//end if (isObjecEntry)
  
  var divEntries = this.document.getElementById('entries');
  var divEntry = addElement(divEntries, 'div', 'entry'+'_'+uid.toString(), 'entry', null, null);
  $(divEntry).remove();
  if ((age === 0) || ($(divEntries).children().length === 0))
    $(divEntries).append(divEntry);
  else if (age > $(divEntries).children().length)
    $(divEntries).prepend(divEntry);
  else
    $(divEntries).children().eq(-age).after(divEntry);

  var divEntryHeader = addElement(divEntry, 'div', null, 'entry_header', null, null);
  var divEntryAnnotationReveal = addElement(divEntryHeader, 'div', null, 'entry_annotation_reveal', null, null);
  var divEntryNumber = addElement(divEntryHeader, 'div', null, 'entry_number', null, null);
  var divEntryOutputFlags = addElement(divEntryHeader, 'div', null, 'entry_flags', null, null);
  if (outputHtmlCumulativeFlags != null)
    divEntryOutputFlags.innerHTML = outputHtmlCumulativeFlags;
  var divEntryClose = addElement(divEntryHeader, 'div', null, 'entry_close', null, null);
  var customAnnotationVisibleStyle = ((customAnnotationVisible == true) ? 'block' : 'none');
  var divEntryAnnotation = addElement(divEntry, 'div', null, 'entry_annotation', {'display':customAnnotationVisibleStyle}, null);
  var divEntryAnnotationTextArea = addElement(divEntryAnnotation, 'textarea', null, null, null, (customAnnotation == null) ? null : customAnnotation.toString());
  divEntryAnnotationTextArea.placeholder = getLocalizedString('type any custom annotation here')+'...';
  annotationUpdateReveal(divEntry);

  divEntry.onclick = function(event) {
    if (event.target != divEntryAnnotationTextArea)
    {
      selectionSetEntry(event.metaKey && $(divEntry).hasClass('entry_selected') ? null : divEntry);
      event.stopPropagation();
    }
  };//end divEntry.onclick()

  var divEntryInput = addElement(divEntry, 'div', null, 'entry_input', null, null);
  divEntryInput.onclick = function(event) {
    selectionSetEntry(event.metaKey && $(divEntry).hasClass('entry_selected') ? null : divEntry, 1);
    event.stopPropagation();
  };//end divEntryInput.onclick()

  var divEntryInputSwitchButton = addElement(divEntryInput, 'div', null, 'entry_input_switch', {'opacity':0}, null);
  divEntryInputSwitchButton.innerHTML = '&nbsp;';

  $(divEntryInput).observe('mouseover', function(event) {
    var dst = event.toElement;
    var isEntryInputChild = isDescendantOf(dst, divEntryInput);
    divEntryInputSwitchButton.style.opacity = !isEntryInputChild ? 0 : 1;
  });
  
  divEntryAnnotationReveal.onclick = function(event) {
    var elementTextArea = event.target;
    var elementAnnotation = elementTextArea.parentNode;
    var elementEntry = elementAnnotation.parentNode;
    annotationToggleVisible(elementEntry);
    event.stopPropagation();
  };
  
  $(divEntryAnnotationTextArea).on('keyup change input', function(event) {
    var elementTextArea = event.target;
    var elementAnnotation = elementTextArea.parentNode;
    var elementEntry = elementAnnotation.parentNode;
    var customAnnotation = $(elementTextArea).val();
    var customAnnotationVisible = annotationGetVisible(elementEntry);
    callExternal(['webViewEntryWithUid_didChangeCustomAnnotation_visible_', uid, customAnnotation, customAnnotationVisible]);
    var offset = elementTextArea.offsetHeight - elementTextArea.clientHeight;
    $(elementTextArea).css('height', 'auto').css('height', elementTextArea.scrollHeight + offset);
    elementAnnotation.style.height = elementTextArea.style.height;
    annotationUpdateReveal(elementEntry);
  });

  divEntryClose.onclick = function(event) {
    closeEntry(divEntry);
    event.stopPropagation();
  };
  
  var divEntryInputRawHTML = addElement(divEntryInput, 'div', null, 'entry_input_raw_html', {'display':'none'}, null);
  if (inputRawHTMLString != null)
    divEntryInputRawHTML.innerHTML = inputRawHTMLString;
  var divEntryInputInterpretedHTML = addElement(divEntryInput, 'div', null, 'entry_input_interpreted_html', {'display':'block'}, null);
  if (inputInterpretedHTMLString != null)
    divEntryInputInterpretedHTML.innerHTML = inputInterpretedHTMLString;
  var divEntryInputInterpretedTeX = addElement(divEntryInput, 'div', null, 'entry_input_interpreted_tex', {'display':'none'},
    (inputInterpretedTeXString != null) ? ('\\('+inputInterpretedTeXString+'\\)') : '\\(\\)');
  if (!disableTypesetting)
    window.MathJax.typeset([divEntryInputInterpretedTeX]);
  if (isNullOrEmpty(inputInterpretedHTMLString))
  {
    divEntryInputSwitchButton.style.display = 'none';
    divEntryInputRawHTML.style.display = 'block';
    divEntryInputInterpretedHTML.style.display = 'none';
  }//end if (isNullOrEmpty(inputInterpretedHTMLString))
  if (!isNullOrEmpty(inputInterpretedTeXString) && !isSimpleString(inputInterpretedHTMLString))
  {
    divEntryInputInterpretedHTML.style.display = 'none';
    divEntryInputInterpretedTeX.style.display = 'block';
  }//end if (!isNullOrEmpty(inputInterpretedTeXString) && !isSimpleString(inputInterpretedHTMLString))

  var divHr = addElement(divEntry, 'div', null, 'hruler', null, getLocalizedString('output'));
  
  var divEntryOutput = addElement(divEntry, 'div', null, 'entry_output', null, null);
  divEntryOutput.onclick = function(event) {
    selectionSetEntry(event.metaKey && $(divEntry).hasClass('entry_selected') ? null : divEntry, 2);
    event.stopPropagation();
  };//end divEntryOutput.onclick()

  var divEntryOutputSwitchButton = addElement(divEntryOutput, 'div', null, 'entry_output_switch', {'opacity':0}, null);

  divEntryOutputSwitchButton.innerHTML = '&nbsp;';
  $(divEntryOutput).observe('mouseover', function(event) {
    var dst = event.toElement;
    var isEntryOutputChild = isDescendantOf(dst, divEntryOutput);
    divEntryOutputSwitchButton.style.opacity = !isEntryOutputChild ? 0 : 1;
  });

  var divEntryOutputHTML = addElement(divEntryOutput, 'div', null, 'entry_output_html', {'display':'block'}, null);
  if (outputHTMLString != null)
    divEntryOutputHTML.innerHTML = outputHTMLString;
  var divEntryOutputTeX = addElement(divEntryOutput, 'div', null, 'entry_output_tex', {'display': 'none'},
    (outputTeXString != null) ? ('\\('+outputTeXString+'\\)') : '\\(\\)');
  if (!disableTypesetting)
    window.MathJax.typeset([divEntryOutputTeX]);
  if (isNullOrEmpty(outputTeXString) || isSimpleString(outputTeXString))
  {
    divEntryOutputSwitchButton.style.display = 'none';
  }//end if (isNullOrEmpty(outputTeXString) || isSimpleString(outputTeXString))
  if (!isNullOrEmpty(outputTeXString) && !isSimpleString(outputHTMLString))
  {
    divEntryOutputHTML.style.display = 'none';
    divEntryOutputTeX.style.display = 'block';
  }//end if (!isNullOrEmpty(outputTeXString) && !isSimpleString(outputHTMLString))
  
  var divEntryOutput2 = addElement(divEntry, 'div', null, 'entry_output2', {'display':'none'}, null);
  var divHr2 = addElement(divEntryOutput2, 'div', null, 'hruler', null, getLocalizedString('output from bits inspector'));
  var divEntryOutput2Flags = addElement(divEntryOutput2, 'div', null, 'entry_flags', null, null);
  if (output2HtmlCumulativeFlags != null)
    divEntryOutput2Flags.innerHTML = output2HtmlCumulativeFlags;
  var divEntryOutput2SwitchButton = addElement(divEntryOutput2, 'div', null, 'entry_output2_switch', {'opacity':0}, null);

  divEntryOutput2SwitchButton.innerHTML = '&nbsp;';
  $(divEntryOutput2).observe('mouseover', function(event) {
    var dst = event.toElement;
    var isEntryOutput2Child = isDescendantOf(dst, divEntryOutput2);
    divEntryOutput2SwitchButton.style.opacity = !isEntryOutput2Child ? 0 : 1;
  });

  if (!isNullOrEmpty(output2HTMLString) || !isNullOrEmpty(output2TeXString))
  {
    divEntryOutput2.style.display = 'block';
  }//end if (!isNullOrEmpty(output2HTMLString) || !isNullOrEmpty(output2TeXString))

  var divEntryOutput2HTML = addElement(divEntryOutput2, 'div', null, 'entry_output2_html', {'display':'block'}, null);
  if (output2HTMLString != null)
    divEntryOutput2HTML.innerHTML = output2HTMLString;
  var divEntryOutput2TeX = addElement(divEntryOutput2, 'div', null, 'entry_output2_tex', {'display': 'none'},
    (output2TeXString != null) ? ('\\('+output2TeXString+'\\)') : '\\(\\)');
  if (!disableTypesetting)
    window.MathJax.typeset([divEntryOutput2TeX]);
  if (!isNullOrEmpty(output2TeXString) && !isSimpleString(output2HTMLString))
  {
    divEntryOutput2HTML.style.display = 'none';
    divEntryOutput2TeX.style.display = 'block';
  }//end if (!isNullOrEmpty(output2TeXString))
  
  divEntryInputSwitchButton.onclick = function(event) {
    switchEntryContent(divEntryInputInterpretedHTML, divEntryInputInterpretedTeX);
    webViewEntryDidSwitchDisplay();
    event.stopPropagation();
  };
  divEntryOutputSwitchButton.onclick = function(event) {
    switchEntryContent(divEntryOutputHTML, divEntryOutputTeX);
    webViewEntryDidSwitchDisplay();
    event.stopPropagation();
  };
  divEntryOutput2SwitchButton.onclick = function(event) {
    switchEntryContent(divEntryOutput2HTML, divEntryOutput2TeX);
    webViewEntryDidSwitchDisplay();
    event.stopPropagation();
  };

  numerateEntries();
  var age = getAgeForEntry(divEntry);
  endMathjaxGroup();
  return age;
}
//end addEntry()

function removeEntryFromAge(age)
{
  var result = null;
  var divEntry = (age == null) ? null : getEntryForAge(age);
  result = removeEntry(divEntry);
  return result;
}
//end removeEntryFromAge()

function removeEntryFromUid(args)
//uid
{
  var uid = Array.isArray(args) ? args[0] : args;
  
  var result = null;
  var divEntry = (uid == null) ? null : getEntryForUid(uid);
  result = removeEntry(divEntry);
  return result;
}
//end removeEntryFromUid()

function removeEntry(entry)
{
  var age = getAgeForEntry(entry);
  entry.remove();
  numerateEntries();
  selectionSetEntryForAge((age == 1) ? 1 : (age-1));
}
//end removeEntry()

function closeEntryFromUid(uid)
{
  var result = null;
  var divEntry = (uid == null) ? null : getEntryForUid(uid);
  if (divEntry != null)
  {
    $(divEntry).animate({height:'0px',opacity:'0'}, 'fast', 'swing', function() {
      _closeEntry(divEntry);
    });
    result = true;
  }//end if (age != null)
  return result;
}
//end closeEntryFromUid()

function closeEntry(divEntry)
{
  var result = null;
  if (divEntry != null)
  {
    $(divEntry).animate({height:'0px',opacity:'0'}, 'fast', 'swing', function() {
      _closeEntry(divEntry);
    });
    result = true;
  }//end if (age != null)
  return result;
}
//end closeEntry()

function _closeEntry(divEntry)
{
  if (divEntry != null)
  {
    var age = getAgeForEntry(divEntry);
    callExternal(['webViewEntryShouldRemoveAge_',age]);
    if (updateQueues != null)
      delete updateQueues[divEntry];
    selectionSetEntryForAge((age == 1) ? 1 : (age-1));
  }//end if (divEntry != null)
}
//end _closeEntry()

function annotationUpdateReveal(divEntry, optionalTargetValue)
{
  var divEntryAnnotation = $(divEntry).find('div.entry_annotation')[0];
  var divEntryAnnotationTextArea = $(divEntryAnnotation).find('textarea')[0];
  var divEntryAnnotationReveal = $(divEntry).find('div.entry_annotation_reveal')[0];
  var hasText = (divEntryAnnotationTextArea != null) && !isNullOrEmpty($(divEntryAnnotationTextArea).val());
  var isVisible = (optionalTargetValue == null) ? annotationGetVisible(divEntry) : optionalTargetValue;
  if (isVisible)
  {
    if (hasText)
      divEntryAnnotationReveal.style.background = '-webkit-image-set( url(\'images/triangle-down.png\') 1x, url(\'images/triangle-down@2x.png\') 2x )';
    else//if (!hasText)
      divEntryAnnotationReveal.style.background = '-webkit-image-set( url(\'images/triangle-down-empty.png\') 1x, url(\'images/triangle-down-empty@2x.png\') 2x )';
  }//end if (isVisible)
  else//if (!isVisible)
  {
    if (hasText)
      divEntryAnnotationReveal.style.background = '-webkit-image-set( url(\'images/triangle-right.png\') 1x, url(\'images/triangle-right@2x.png\') 2x )';
    else//if (!hasText)
      divEntryAnnotationReveal.style.background = '-webkit-image-set( url(\'images/triangle-right-empty.png\') 1x, url(\'images/triangle-right-empty@2x.png\') 2x )';
  }//end if (!isVisible)
}
//end annotationUpdateReveal()

function annotationGetVisible(divEntry)
{
  var result = false;
  var divEntryAnnotation = $(divEntry).find('div.entry_annotation')[0];
  result = (divEntryAnnotation != null) && (divEntryAnnotation.style.display != 'none');
  return result;
}
//end annotationGetVisible()

function annotationSetVisible(divEntry, value)
{
  var result = false;
  var divEntryAnnotation = $(divEntry).find('div.entry_annotation')[0];
  if (divEntryAnnotation != null)
  {
    var oldValue = annotationGetVisible(divEntry);
    if (oldValue != value)
    {
      annotationUpdateReveal(divEntry, value);
      var animationDidEnd = function() {
        var divEntryAnnotation = $(divEntry).find('div.entry_annotation')[0];
        var divEntryAnnotationTextArea = $(divEntryAnnotation).find('textarea')[0];
        var uid = getUidForEntry(divEntry);
        var customAnnotation = $(divEntryAnnotationTextArea).val();
        var customAnnotationVisible = value;
        callExternal(['webViewEntryWithUid_didChangeCustomAnnotation_visible_', uid, customAnnotation, customAnnotationVisible]);
      };
      if (value)
      {
        divEntryAnnotation.style.display = 'block';
        $(divEntryAnnotation).animate({height:divEntryAnnotation.scrollHeight.toString()+'px'}, 'fast', 'linear', function() {
          animationDidEnd();
        });
      }
      else//if (!value)
      {
        $(divEntryAnnotation).animate({height:'0px'}, 'fast', 'linear', function() {
          divEntryAnnotation.style.display = 'none';
          animationDidEnd();
        });
      }//end if (!value)
    }//end if (oldValue != value)
  }//end if (divEntryAnnotation != null);
  return result;
}
//end annotationSetVisible()

function annotationToggleVisible(divEntry)
{
  annotationSetVisible(divEntry, !annotationGetVisible(divEntry));
}
//end annotationToggleVisible()

var updateQueues = {};
function getUpdateQueueFor(entry)
{
  var updateQueue = (updateQueues == null) || (entry == null) ? null : updateQueues[entry];
  if ((updateQueue == null) && (entry != null) && (updateQueues != null))
  {
    updateQueue = new Array();
    updateQueues[entry] = updateQueue;
  }//end if ((updateQueue == null) && (entry != null) && (updateQueues != null))
  return updateQueue;
}
//end getUpdateQueueFor()

function updateDequeueFor(entry)
{
  var updateQueue = getUpdateQueueFor(entry);
  if (updateQueue.length > 0)
  {
    var lastItem = updateQueue[updateQueue.length-1];
    updateQueue = [];
    updateQueues[entry] = updateQueue;
    setTimeout(lastItem, 0)
  }//end if (updateQueue.length > 0)
}
//end updateDequeueFor()

function updateEntryAnnotation(args)
  //[uid, customAnnotation, customAnnotationVisible]
{
  var argsArray = (args.length > 1) ? args : args[0];
  var uid = argsArray[0];
  var customAnnotation = argsArray[1];
  var customAnnotationVisible = argsArray[2];
  var divEntry = getEntryForUid(uid);
  var divEntryAnnotation = $(divEntry).find('div.entry_annotation')[0];
  var divEntryAnnotationTextArea = $(divEntryAnnotation).find('textarea')[0];
  var oldCustomAnnotation = (divEntryAnnotationTextArea == null) ? null : $(divEntryAnnotationTextArea).val();
  var oldCustomAnnotationVisible = annotationGetVisible(divEntry);
  if (divEntry != null)
  {
    if (customAnnotation != oldCustomAnnotation)
      $(divEntryAnnotationTextArea).val(customAnnotation);
    divEntryAnnotation.style.display = (customAnnotationVisible == true) ? 'block' : 'none';
    annotationUpdateReveal(divEntry);
  }//end if (divEntry != null)
}
//end updateEntryAnnotation()

function updateEntry(args)
//uid, inputRawHTMLString, inputInterpretedHTMLString, inputInterpretedTeXString, outputHTMLString, outputTeXString, outputHtmlCumulativeFlags, output2HTMLString, output2TeXString, output2HtmlCumulativeFlags
{
  var argsArray = (args.length > 1) ? args : args[0];
  var uid = argsArray[0];
  var inputRawHTMLString = argsArray[1];
  var inputInterpretedHTMLString = argsArray[2];
  var inputInterpretedTeXString = argsArray[3];
  var outputHTMLString = argsArray[4];
  var outputTeXString = argsArray[5];
  var outputHtmlCumulativeFlags = argsArray[6];
  var output2HTMLString = argsArray[7];
  var output2TeXString = argsArray[8];
  var output2HtmlCumulativeFlags = argsArray[9];

  _updateEntry(uid,
             inputRawHTMLString, inputInterpretedHTMLString, inputInterpretedTeXString,
             outputHTMLString, outputTeXString, outputHtmlCumulativeFlags,
             output2HTMLString, output2TeXString, output2HtmlCumulativeFlags);
}
//end updateEntry()

function _updateEntry(uid, inputRawHTMLString, inputInterpretedHTMLString, inputInterpretedTeXString,
                      outputHTMLString, outputTeXString, outputHtmlCumulativeFlags,
                      output2HTMLString, output2TeXString, output2HtmlCumulativeFlags)
{
  var entry = getEntryForUid(uid);
  var updateQueue = getUpdateQueueFor(entry);
  
  var divEntryInput = $(entry).find('div.entry_input')[0];
  var divEntryInputSwitchButton = $(divEntryInput).find('div.entry_input_switch')[0];
  
  var divEntryInputRawHTML = $(divEntryInput).find('div.entry_input_raw_html')[0];
  if (inputRawHTMLString != null)
    divEntryInputRawHTML.innerHTML = inputRawHTMLString;

  var divEntryInputInterpretedHTML = $(divEntryInput).find('div.entry_input_interpreted_html')[0];
  if (inputInterpretedHTMLString != null)
    divEntryInputInterpretedHTML.innerHTML = inputInterpretedHTMLString;

  var divEntryInputInterpretedTeX = $(divEntryInput).find('div.entry_input_interpreted_tex')[0];
  var inputMath = getAllJax(divEntryInputInterpretedTeX)[0];
  
  var divEntryOutput = $(entry).find('div.entry_output')[0];
  var divEntryOutputSwitchButton = $(divEntryOutput).find('div.entry_output_switch')[0];
  divEntryOutputSwitchButton.innerHTML = '&nbsp;';

  var divEntryOutputFlags = $(entry).find('div.entry_flags')[0];
  if (outputHtmlCumulativeFlags != null)
    divEntryOutputFlags.innerHTML = outputHtmlCumulativeFlags;

  var divEntryOutputHTML = $(divEntryOutput).find('div.entry_output_html')[0];
  divEntryOutputHTML.innerHTML = outputHTMLString;
  var divEntryOutputTeX = $(divEntryOutput).find('div.entry_output_tex')[0];
  var outputMath = getAllJax(divEntryOutputTeX)[0];

  var divEntryOutput2 = $(entry).find('div.entry_output2')[0];
  var divEntryOutput2SwitchButton = $(divEntryOutput2).find('div.entry_output2_switch')[0];
  divEntryOutput2SwitchButton.innerHTML = '&nbsp;';
  
  var divEntryOutput2Flags = $(entry).find('div.entry_flags')[1];
  if (output2HtmlCumulativeFlags != null)
    divEntryOutput2Flags.innerHTML = output2HtmlCumulativeFlags;

  var divEntryOutput2HTML = $(divEntryOutput2).find('div.entry_output2_html')[0];
  divEntryOutput2HTML.innerHTML = output2HTMLString;
  var divEntryOutput2TeX = $(divEntryOutput2).find('div.entry_output2_tex')[0];
  var output2Math = getAllJax(divEntryOutput2TeX)[0];
  
  if (!isNullOrEmpty(inputRawHTMLString) && !isNullOrEmpty(inputInterpretedHTMLString) &&
      !isNullOrEmpty(inputInterpretedTeXString))
  {
    divEntryInputSwitchButton.style.display = 'none';
    divEntryInputRawHTML.style.display = 'none';
    divEntryInputInterpretedHTML.style.display = 'block';
    divEntryInputInterpretedTeX.style.display = 'none';
  }//end if (!isNullOrEmpty(inputRawHTMLString) && (!isNullOrEmpty(inputInterpretedHTMLString) && !isNullOrEmpty(inputInterpretedTeXString))
  
  if (!isNullOrEmpty(outputHTMLString) && !isNullOrEmpty(outputTeXString))
  {
    divEntryOutputSwitchButton.style.display = 'none';
    divEntryOutputHTML.style.display = 'block';
    divEntryOutputTeX.style.display = 'none';
  }//end if (!isNullOrEmpty(outputHTMLString) && !isNullOrEmpty(outputTeXString))

  if (!isNullOrEmpty(output2HTMLString) || !isNullOrEmpty(output2TeXString))
  {
    divEntryOutput2.style.display = 'block';
  }//end if (!isNullOrEmpty(output2HTMLString) || !isNullOrEmpty(output2TeXString))

  if (!isNullOrEmpty(output2HTMLString) && !isNullOrEmpty(output2TeXString))
  {
    divEntryOutput2SwitchButton.style.display = 'none';
    divEntryOutput2HTML.style.display = 'block';
    divEntryOutput2TeX.style.display = 'none';
  }//end if (!isNullOrEmpty(output2HTMLString) && !isNullOrEmpty(output2TeXString))

  if (!isNullOrEmpty(inputInterpretedTeXString) || !isNullOrEmpty(outputTeXString) || !isNullOrEmpty(output2TeXString))
  {
    updateQueue.push(function () {
      if (!isNullOrEmpty(inputInterpretedTeXString))
      {
        inputMath.innerHTML = '\\('+inputInterpretedTeXString+'\\)';
        window.MathJax.typeset([inputMath]);
        divEntryInputRawHTML.style.display = 'none';
        divEntryInputInterpretedHTML.style.display = 'none';
        divEntryInputInterpretedTeX.style.display = 'block';
        divEntryInputSwitchButton.style.display = 'block';
      }//end if (!isNullOrEmpty(inputInterpretedTeXString))
      if (!isNullOrEmpty(outputTeXString))
      {
        outputMath.innerHTML = '\\('+outputTeXString+'\\)';
        window.MathJax.typeset([outputMath]);
        if (!isSimpleString(outputHTMLString))
        {
          divEntryOutputHTML.style.display = 'none';
          divEntryOutputTeX.style.display = 'block';
          divEntryOutputSwitchButton.style.display = 'block';
        }//end if (!isSimpleString(outputHTMLString))
      }//end if (!isNullOrEmpty(outputTeXString))
      if (!isNullOrEmpty(output2TeXString))
      {
        output2Math.innerHTML = '\\('+output2TeXString+'\\)';
        window.MathJax.typeset([output2Math]);
        if (!isSimpleString(output2HTMLString))
        {
          divEntryOutput2HTML.style.display = 'none';
          divEntryOutput2TeX.style.display = 'block';
          divEntryOutput2SwitchButton.style.display = 'block';
        }//end if (!isSimpleString(output2HTMLString))
      }//end if (!isNullOrEmpty(output2TeXString))
    });//end updateQueue.push()
    updateDequeueFor(entry);
  }//end if (!isNullOrEmpty(inputInterpretedTeXString) || !isNullOrEmpty(outputTeXString) || !isNullOrEmpty(output2TeXString))
  if (isNullOrEmpty(output2TeXString))
  {
    output2Math.Text(output2TeXString);
    divEntryOutput2HTML.style.display = 'block';
    divEntryOutput2TeX.style.display = 'none';
    divEntryOutput2SwitchButton.style.display = 'none';
  }//end if (isNullOrEmpty(output2TeXString))
}
//end _updateEntry()

function beginMathjaxGroup()
{
  ++mathjaxGroupIndex;
}
//end beginMathjaxGroup()

function endMathjaxGroup()
{
  --mathjaxGroupIndex;
  if (mathjaxGroupIndex == 0)
  {
    numerateEntries();
    selectionSetEntry(null, null);
    callExternal(['mathjaxGroupDidEnd']);
    callExternal(['mathjaxDidEndTypesetting']);
    $("html, body").scrollTop($(document).height());
  }//end if (mathjaxGroupIndex == 0)
}
//end endMathjaxGroup()

function numerateEntries()
{
  var $entries = $('div.entry');
  var count = $entries.length;
  for(var i = 0 ; i<count ; ++i)
  {
    var entry = $entries[i];
    var $divEntryNumber = $(entry).find('div.entry_number');
    $divEntryNumber.text(count-i);
  }//end for each entry
  return count;
}
//end numerateEntries()
