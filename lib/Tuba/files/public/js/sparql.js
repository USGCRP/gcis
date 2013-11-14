function linkify (str) {
        var regex = /(^|\s)(https?:\/\/\S+)($|\s)/ig;
        return str.replace(regex,'$1<a href="$2" target="_blank">$2</a>$3')
}

$(document).ready(function() {
        $('#sparql_results > tbody > tr > td').each(
            function(i,r) {
                var h = $(this).html();
                $(this).html(linkify(h));
          } )
});


