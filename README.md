LittleBox
=========

In developing Klout's iOS application, we ended up building a variety of
internal application classes that were not specific to Klout, but contained
behaviors that are broadly applicable to many iOS applications. We moved this
code out of the proprietary application and put it here in an external library
for release to the open source community. As such, the library doesn't
exclusively tackle any one major problem, nor does it provide a comphrehensive
framework for app development in general. Think of it as a grab-bag of useful,
single-purpose tools. Read on for an overview of what's inside.

Please note: this release (v0.9) is considered unstable. We do use all of these
classes our production application, however not every use case has the benefit
of being hardened in that context. The public interfaces are also subject to
change as we iterate and gather feedback. Please be sure to test your usage
thoroughly, and we welcome your fixes, improvements, and suggestions.

Included functionality:
-----------------------

### Singleton Management

* **LBBaseSingleton** makes declaring and managing app singletons easier and more
  robust.
  
* **LBBaseMultiDelegateSingleton** allows singletons to broadcast messages to
  multiple delegates/observers without the limitations of NSNotificationCenter
  or KVO.

* **LBSingletonResetManager** provides the ability to reset state on all your
  singletons at once.

### Utility Singletons

* **LBBaseEventlogger** provides a central singleton for the collection of debug log
  and analytics event data, fanning the information out to various destinations
  such as the console, third party analytics SDKs (think Flurry, Mixpanel, etc),
  as well as a custom backend event collector endpoint if you have one.

* **LBGlobalFullScreenSpinner** centrally manages a full-screen activity indicator
  that can be triggered from anywhere in the app.

* **LBNetworkStatusSpinnerManager** centrally manages the state of the network
  status indicator in the iOS status bar among multiple simultaneous application
  network activites.

### Views

* **LBAnnotatedUIButton** extends UIButton with an extra userInfo NSDictionary
  property, and has handy methods for using it to create tap targets that
  overlay UILabels or other views.

* **LBStyledActivityIndicator** simplifies the presentation of an activity indicator
  in a few different standard visual styles.

### Other Utilities

* **LBLog.h** defines simple macros, **LBLog()** and **LBLogRaw()**, that you should use
  instead of NSLog for console debugging.

* **LBUtils** is a collection of one-off utility methods that cover:
  * string processing
  * date processing
  * image manipulation
  * OAuth 1.0a header and signature generation
  * CGRect and UIView geometry manipulation

* **LBTimer** is a wrapper for NSTimer that avoids the problematic retain cycle
  typically associated with use of NSTimer.

* **LBZeroingWeakContainer** is an object reference wrapper class useful for storing
  objects in an NSArray or other container without retaining those objects.

* **LBCLLocationManagerProxy** is an experimental mock object that can simulate
  location changes on a device for use in testing region monitoring or other
  location tracking code.

Project Requirements
--------------------

* ARC. (To those not using it yet: why not just change your project over to ARC
  and apply the -fno-objc-arc compiler flag to all your unmigrated files?)

* iOS 5.0+ deployment targets. Various iOS 5+ features are used such as zeroing
  weak references.

* If you want to use LBCLLocationManagerProxy you will need the CoreLocation
  framework. See installation below.

Installation
------------

The easiest way to install this library is to simply copy the LittleBox folder
into a location in your project folder via the filesystem, then add the new
folder to your project via XCode.

Note: if you want to use LBCLLocationManagerProxy, you will need to link the
CoreLocation framework to your project and you will also need to add a
declaration to your project build settings to enable the compilation of the
class: go to your project build settings and add
"DEFINE_LBCLLOCATIONMANAGERPROXY=1" (without quotes) to the "Preprocessor Macros
Not Used In Precompiled Headers" section. See LBCLLocationManagerProxy.h for
more info.

Contributors
------------

* Josh Whiting (@yetanotherjosh), https://github.com/jwhiting
* Mustafa Furniturewala, https://github.com/mustafa
* Ian Kallen (@spidaman),https://github.com/spidaman

