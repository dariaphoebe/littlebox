/*
 
 Copyright 2013 Klout
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

// To make these methods universally available in your app, import this header
// using your project's "...-Prefix.pch" file.

// LBLog() is a replacement for NSLog, which will also log the function name and
// line number, and will only log in DEBUG mode. Logging in DEBUG mode only is
// useful to prevent verbose, sensitive, or otherwise problematic information
// from appearing on real customer phone console log streams.
#ifdef DEBUG
#define LBLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define LBLog(...)
#endif

// LBLogRaw doesn't print function and line number context and so is just like
// NSLog except that it will only log in DEBUG mode.
#ifdef DEBUG
#define LBLogRaw(fmt, ...) NSLog(fmt, ##__VA_ARGS__);
#else
#define LBLogRaw(...)
#endif
