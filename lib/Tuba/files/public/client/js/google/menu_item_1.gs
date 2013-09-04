
function() {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = SpreadsheetApp.getActiveSheet();
    var api_base = CacheService.getPrivateCache().get('api_base');

     
    var range = SpreadsheetApp.getActiveRange();
    var rows = range.getLastRow();
    var values = range.getValues();
    var cols=range.getLastColumn();
    var val = values[0][0];
    if (!val || !val.match(/figure/)) {
        Browser.msgBox('Please select a cell which contains /figure/:identifier');
        return;
    }

    var url = api_base + '/report/nca3draft' + val;
    var res = UrlFetchApp.fetch(url + '.json');
    var txt = res.getContentText();
    var json = JSON.parse(txt);
    if (!json || !json.images) {
        Browser.msgBox('Cannot find any images for figure ' + val);
        return;
    }
    var first_image = json.images[0].identifier;
    var img_txt = UrlFetchApp.fetch(api_base + '/image/' + first_image + '.json');
    var img_json = JSON.parse(img_txt);
    var file = img_json.file[0].file;
    var img_url = '<img src="' + api_base + '/img/' + file + '" width="400" height="300">';
     
    var htmlApp = HtmlService
        .createHtmlOutput('<a href="' + url + '">' + json.identifier + '</a>' + img_url + '<hr><p>' + json.caption + '</p>')
        .setTitle('Figure ' + json.chapter.number + '.' + json.ordinal + ' : ' + json.title)
        .setWidth(500)
        .setHeight(500);
    ss.show(htmlApp);
}

