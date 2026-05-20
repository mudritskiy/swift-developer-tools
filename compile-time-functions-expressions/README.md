# Compile time. Functions and Expressions

## Manual check

Should add flags here:
- Open Project setting 
- Build Settings
- Swift Compiler 
- Custom Flags 
- Other Swift Flags

<img src="compile-time-flags-setup.png" width="60%">

Add this flags to debug configuration, where **limit** set to ms of lower accessible compile time
``` console
-Xfrontend -warn-long-function-bodies=limit
-Xfrontend -warn-long-expression-type-checking=limit
```
Better insert it as a single line, as in example:
``` console
-Xfrontend -warn-long-function-bodies=100 -Xfrontend -warn-long-expression-type-checking=100
```
As a result you will see in Issue Navigator you will see such warnings:
``` console 
Instance method '_content()' took 125ms to type-check (limit: 100ms)
```
You can solve solid compile issues and then reduce limit to solve minor issues.

## Save to file Script
You can go even further and run in console this script, that build project with this flag and saving sorted result into file to work with it later.

``` console
xcodebuild -workspace ProjectName.xcworkspace \
-scheme ProjectSchemeName \
OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies -Xfrontend -debug-time-expression-type-checking" build | \
grep -E '[0-9]+\.[0-9]+ms' | \
grep -vE 'Pods/|Carthage/|SourcePackages/|\.build/' | \
sort -nr > slow_functions.txt
```