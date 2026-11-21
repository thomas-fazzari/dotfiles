ObjC.import("Foundation");

$.NSBundle.bundleWithPath("/System/Library/PrivateFrameworks/SkyLight.framework").load;
ObjC.bindFunction("SLSMainConnectionID", ["int", []]);
ObjC.bindFunction("SLSSetMenuBarInsetAndAlpha", ["int", ["int", "double", "double", "float"]]);

const error = $.SLSSetMenuBarInsetAndAlpha($.SLSMainConnectionID(), 0, 1, 0);
if (error !== 0) {
  throw new Error(`SLSSetMenuBarInsetAndAlpha failed: ${error}`);
}
$.NSRunLoop.currentRunLoop.run;
