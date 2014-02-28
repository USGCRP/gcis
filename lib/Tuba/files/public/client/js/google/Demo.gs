function identify_figure() {
 var ss = SpreadsheetApp.getActiveSpreadsheet();
 var sheet = SpreadsheetApp.getActiveSheet();
  
 var range = SpreadsheetApp.getActiveRange();
 var rows = range.getLastRow();
 var values = range.getValues();
 var cols=range.getLastColumn();
 var val = values[0][0];
 var url = 'http://data.globalchange.gov/report/nca3draft' + val;
 var res = UrlFetchApp.fetch(url + '.json');
 var txt = res.getContentText();
 var json = JSON.parse(txt);
 var first_image = json.image[0].identifier;
 var img_txt = UrlFetchApp.fetch('http://data.globalchange.gov/image/' + first_image + '.json');
 var img_json = JSON.parse(img_txt);
 var file = img_json.file[0].file;
 var img_url = '<img src="http://data.globalchange.gov/assets/' + file + '" width="400" height="300">';
  
 var htmlApp = HtmlService
     .createHtmlOutput('<a href="' + url + '">' + json.identifier + '</a>' + img_url + '<hr><p>' + json.caption + '</p>')
     .setTitle('Figure ' + json.chapter.number + '.' + json.ordinal + ' : ' + json.title)
     .setWidth(500)
     .setHeight(500);
 ss.show(htmlApp);

}

// add menu items
function onOpen() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet();
  var entries = [
  {
    name : "Identify figure",
    functionName : "identify_figure"
  },
  ];
  sheet.addMenu("GCIS", entries);
};
