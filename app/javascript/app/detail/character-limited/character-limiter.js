// Finds elements that have the 'character-limited' class assigned to them
// and adds a new CharacterLimited instance to those elements.
import CharacterLimited from './CharacterLimited';

// 'Constants'
var SHOW_CHAR = 400;
var SOFT_LIMIT = 100;
var MORE_TEXT = 'Show more';
var LESS_TEXT = 'Show less';
var ELLIPSES_TEXT = '…';

function init() {
  var defaults = {
    SHOW_CHAR: SHOW_CHAR,
    SOFT_LIMIT: SOFT_LIMIT,
    MORE_TEXT: MORE_TEXT,
    LESS_TEXT: LESS_TEXT,
    ELLIPSES_TEXT: ELLIPSES_TEXT
  };
  var charLimitedElms = document.querySelectorAll('.character-limited');
  var numberElms = charLimitedElms.length;
  while (numberElms > 0) {
    CharacterLimited.create(charLimitedElms[--numberElms], defaults);
  }
}

export default {
  init: init
};
