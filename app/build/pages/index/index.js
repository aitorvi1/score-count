/******/ (function() { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ 825:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var $app_template$ = __webpack_require__(31)
var $app_style$ = __webpack_require__(920)
var $app_script$ = __webpack_require__(768)
var options=$app_script$
 if ($app_script$.__esModule) {

      options = $app_script$.default;
 }
options.styleSheet=$app_style$
options.render=$app_template$;
module.exports=new ViewModel(options);

/***/ }),

/***/ 920:
/***/ (function(module) {

module.exports = {"classSelectors":{"container":{"flexDirection":"column","justifyContent":"center","alignItems":"center","left":0,"top":0,"width":466,"height":466,"backgroundColor":0},"title":{"fontSize":32,"color":16777215,"textAlign":"center","width":260,"height":60},"score-row":{"flexDirection":"row","justifyContent":"center","alignItems":"center","width":390,"height":210},"team":{"flexDirection":"column","justifyContent":"center","alignItems":"center","width":175,"height":210,"backgroundColor":1579032,"borderRadius":20},"team-name":{"fontSize":24,"color":13421772,"textAlign":"center","width":175,"height":40},"score":{"fontSize":80,"color":16777215,"textAlign":"center","width":175,"height":110},"separator":{"fontSize":52,"color":16777215,"textAlign":"center","width":40,"height":80},"undo":{"fontSize":28,"color":16777215,"textAlign":"center","width":220,"height":64,"marginTop":20,"backgroundColor":3158064,"borderRadius":20}}}

/***/ }),

/***/ 31:
/***/ (function(module) {

module.exports = function (vm) { var _vm = vm || this; return _c('div', {'staticClass' : ["container"]} , [_c('text', {'attrs' : {'value' : "FRONTENIS"},'staticClass' : ["title"]} ),_c('div', {'staticClass' : ["score-row"]} , [_c('div', {'staticClass' : ["team"],'onBubbleEvents' : {'click' : _vm.addPointA}} , [_c('text', {'attrs' : {'value' : "EQUIPO A"},'staticClass' : ["team-name"]} ),_c('text', {'attrs' : {'value' : function () {return _vm.scoreA}},'staticClass' : ["score"]} )] ),_c('text', {'attrs' : {'value' : "-"},'staticClass' : ["separator"]} ),_c('div', {'staticClass' : ["team"],'onBubbleEvents' : {'click' : _vm.addPointB}} , [_c('text', {'attrs' : {'value' : "EQUIPO B"},'staticClass' : ["team-name"]} ),_c('text', {'attrs' : {'value' : function () {return _vm.scoreB}},'staticClass' : ["score"]} )] )] ),_c('text', {'attrs' : {'value' : "Deshacer"},'staticClass' : ["undo"],'onBubbleEvents' : {'click' : _vm.undo}} )] ) }

/***/ }),

/***/ 768:
/***/ (function(__unused_webpack_module, exports) {

"use strict";


Object.defineProperty(exports, "__esModule", ({
  value: true
}));
exports["default"] = void 0;
var _default = {
  data: {
    scoreA: 0,
    scoreB: 0,
    history: []
  },
  addPointA: function addPointA() {
    this.history.push({
      scoreA: this.scoreA,
      scoreB: this.scoreB
    });
    this.scoreA += 1;
  },
  addPointB: function addPointB() {
    this.history.push({
      scoreA: this.scoreA,
      scoreB: this.scoreB
    });
    this.scoreB += 1;
  },
  undo: function undo() {
    if (this.history.length === 0) {
      return;
    }
    var previous = this.history.pop();
    this.scoreA = previous.scoreA;
    this.scoreB = previous.scoreB;
  }
};
exports["default"] = _default;

function requireModule(moduleName) {
  return requireNative(moduleName.slice(1));
}


/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module is referenced by other modules so it can't be inlined
/******/ 	var __webpack_exports__ = __webpack_require__(825);
/******/ 	
/******/ 	return __webpack_exports__;
/******/ })()
;
//# sourceMappingURL=index.js.map