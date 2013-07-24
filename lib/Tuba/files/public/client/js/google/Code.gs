
/*
 * To use this : open a google spreadsheet, choose 'script editor' and
 * then copy and paste this file into "Code.gs".
 */

function onOpen() {
  var ss = SpreadsheetApp.getActive();
  var items = [
      {name: 'dev',  functionName: 'connect_to_dev'},
      {name: 'test', functionName: 'connect_to_test'},
      {name: 'prod', functionName: 'connect_to_prod'},
     ];
  ss.addMenu('Connect to GCIS', items);
}

/*
 * The list of menu items is configured with a GET /client/js/google/menuitems.json.
 * The code for each menu item is retrieved with GET /client/js/google/menu_item_1.gs (or 2, 3, ...etc )
 */
 
function connect_to(which) {
  var api_base = (
      which == 'dev'  ? 'http://data.gcis-dev-front.joss.ucar.edu'
    : which == 'test' ? 'http://data.gcis-test-front.joss.ucar.edu'
    : which == 'prod' ? 'http://data.globalchange.gov'
    : '' );
  var ss = SpreadsheetApp.getActive();
  ss.removeMenu('Connect to GCIS');
  CacheService.getPrivateCache().put('api_base',api_base);
  var res = UrlFetchApp.fetch(api_base + '/client/js/google/menuitems.json');
  var items = Utilities.jsonParse(res.getContentText());
  ss.addMenu('GCIS (dev)',items);
}


function runit(what) {
   var api_base = CacheService.getPrivateCache().get('api_base');
   var fun = eval(UrlFetchApp.fetch(api_base + '/client/js/google/' + what + '.gs').getContentText());
   fun();
}

function connect_to_dev()  { connect_to('dev'); }
function connect_to_test() { connect_to('test'); }
function connect_to_prod() { connect_to('prod'); }

function menu_item_1() {  runit('menu_item_1'); }
function menu_item_2() {  runit('menu_item_2'); }
function menu_item_3() {  runit('menu_item_3'); }
function menu_item_4() {  runit('menu_item_4'); }
function menu_item_5() {  runit('menu_item_5'); }
function menu_item_6() {  runit('menu_item_6'); }
function menu_item_7() {  runit('menu_item_7'); }
function menu_item_8() {  runit('menu_item_8'); }
function menu_item_9() {  runit('menu_item_9'); }
function menu_item_10() {  runit('menu_item_10'); }


