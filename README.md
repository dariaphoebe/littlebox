LittleBox
=========

Little Box, Big iOS Tools

LittleBox is a grab-bag of single-purpose tools which will be useful in some
way or another in almost any iOS application. The code originated as internal
supporting classes and utilities written at Klout for use in our iPhone
application. We chose the pieces of code that were the best encapsulated and
most useful, then teased them out of our application and into this library. We
also added substantial documentation in the form of well-formatted comments
throughout the code.  Read on for a detailed list of what's inside.

Please note: this release (v0.9) is considered unstable. We do use all of these
classes in our production application, however not every use case has the
benefit of being hardened in that context. The public interfaces are also
subject to change as we iterate and gather feedback. Please be sure to test
your usage thoroughly, and we welcome your fixes, improvements, and
suggestions.

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

* **LBBaseEventLogger** provides a central singleton for the collection of debug log
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

If you like the LBLog and LBLogRaw macros, you should add an import statement
for LBLog.h into your project's precompiled header prefix file, which is
usually named something like "YourProjectName-Prefix.pch" somewhere in your
XCode project. This will allow you to use the macros without having to
explicitly import LBLog.h in each source file.

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

