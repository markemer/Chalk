function initialize()
{
  $('div').each(function(index) {
    var classes = this.className.split(/\s+/);
    if ($.inArray('entry', classes) >= 0)
    {
      classes = $.unique(classes.sort());
      classes.splice($.inArray('entry', classes), 1);
      var classesDisplay = new Array();
      $(classes).each(function(index) {
        classesDisplay.push('<span class="category">'+getCategoryDisplayName(this)+'</span>');
      });
      var classesDisplayString = classesDisplay.join(', ');
      $(this).append('<p class="categories">Categories : '+classesDisplayString+'</p>')
    }//end if ($.inArray('entry', $classes) >= 0)
  });
}
//end initialize()

var CategoryDisplayNames = {
  'linear-algebra':'Linear algebra'
};

function toTitleCase(str) {
    return str.replace(/(?:^|\s)\w/g, function(match) {
        return match.toUpperCase();
    });
}
//end toTitleCase()

function getCategoryDisplayName(category)
{
  var result = CategoryDisplayNames[category];
  if (result == null)
    result = toTitleCase(category);
  return result;
}
//getCategoryDisplayName()

function getCategories()
{
  var result = new Array();
  var categoryNames = new Array();
  $('div').each(function(index) {
    var classes = this.className.split(/\s+/);
    if ($.inArray('entry', classes) >= 0)
    {
      categoryNames = categoryNames.concat(classes);
      $.unique(categoryNames.sort());
    }//end if ($.inArray('entry', categories) >= 0)
  });
  categoryNames.splice($.inArray('entry', categoryNames), 1);
  $(categoryNames).each(function(index) {
    result.push({'name':this.toString(), 'displayName':getCategoryDisplayName(this)});
  });
  return result;
}
//end getCategories()

function getEntries()
{
  var result = new Array();
  $('div').each(function(index) {
    var classes = this.className.split(/\s+/);
    if ($.inArray('entry', classes) >= 0)
    {
      var name = null;
      $(this).find('p').each(function(index) {
        if ((name == null) && (this.className == 'name'))
          name = $(this).text();
      });
      result.push({'entry_id':$(this).attr('id'), 'entry_name':name});
    }//end if ($.inArray('entry', categories) >= 0)
  });
  return result;
}
//end getEntries()

function getEntriesForCategory(args)
{
  var result = new Array();
  var category = Array.isArray(args) ? args[0] : args;
  $('div').each(function(index) {
    var classes = this.className.split(/\s+/);
    if (($.inArray('entry', classes) >= 0) && ($.inArray(category, classes) >= 0))
    {
      var name = null;
      $(this).find('p').each(function(index) {
        if ((name == null) && (this.className == 'name'))
          name = $(this).text();
      });
      result.push({'entry_id':$(this).attr('id'), 'entry_name':name});
    }//end if (($.inArray('entry', classes) >= 0) && ($.inArray(category, classes) >= 0))
  });
  return result;
}
//end getEntriesForCategory()

function displayCategory(args)
{
  var category = Array.isArray(args) ? args[0] : args;
  $('div').each(function(index) {
    var classes = this.className.split(/\s+/);
    if ($.inArray('entry', classes) >= 0)
    {
      var shouldDisplay = ($.inArray(category, classes) >= 0);
      if (shouldDisplay)
        $(this).show();
      else
        $(this).hide();
    }//end if ($.inArray('entry', classes) >= 0)
  });
}
//end displayCategory()

function displayEntry(args)
{
  var entry_id = Array.isArray(args) ? args[0] : args;
  $('div').each(function(index) {
    var classes = this.className.split(/\s+/);
    if ($.inArray('entry', classes) >= 0)
    {
      var shouldDisplay = ($(this).attr('id') == entry_id);
      if (shouldDisplay)
        $(this).show();
      else
        $(this).hide();
    }//end if ($.inArray('entry', classes) >= 0)
  });
}
//end displayEntry()
