String.prototype.htmlEscape = function() {
     return $('<div/>').text(this.toString()).html();
};
(function($) {
    $.fn.hasScrollBar = function() {
        if (this.height() < 0) {
            return false;
        }
        return this.get(0).scrollHeight > this.height();
    }
})(jQuery);

