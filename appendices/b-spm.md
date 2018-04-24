# Swift Package Manager Basics

For those new to cross-platform Swift, using the Swift Package Manager (SPM) is often a major point of confusion - especially when something goes wrong. This appendix will attempt to teach you just enough about SPM to make it work for you without overloading you with minutiae and details.

## Package Managers

What is a package manager? For the purpose of this book, it is a tool which helps us manage dependencies of a code project. A *dependency* is a bit of code, often (but not necessarily) written by someone else, that our project is going to leverage to do what it needs to do. In all of the examples of this book, Kitura is a dependency; in later chapters, other projects like the Kuery database integration tool and the Stencil templating engine are used, so those become dependencies as well. These dependencies in the form of bundles of code are called *libraries;* the term *package* is a more generalized term that applies to the code itself as well as the “wrapping” that makes it usable by a package manager, which is called a *manifest* in SPM. (More on manifests later.)

Technically we could “manage” these dependencies ourselves by just copying the files we need manually, or by using Git submodules. But package managers simplify this by doing a lot of the manual work for us, and also make it simpler to use a new version of a dependency with our code if one becomes available - or, alternatively, specify an older version of a dependency if the newest one “breaks” things.

If you are using Swift to write Cocoa applications, you may be familiar with [CocoaPods](https://cocoapods.org/) or [Carthage](https://github.com/Carthage/Carthage), two package managers in common use in that environment. However, both of those are not intended to run on platforms other than macOS; SPM, on the other hand, is built into Swift itself and runs on all platforms that Swift itself does.

SPM expects all dependencies to be stored in Git repositories, though your project itself does not need to be - at least not unless you want your project to itself be a package.

## The Package.swift File

A project utilizing Swift Package Manager will need a file named Package.swift. This is what SPM uses as the manifest. Package.swift serves many purposes.

* It defines *targets,* or things the compiler can build. The examples in this book have all only had one target, and why you would need more than one is outside the scope of this book; what you need to know for now is that different targets can have different dependencies.
* It defines the dependency packages; both paths to their Git repositories as well as information on what versions of those packages are needed.
* It defines the project itself as a package (regardless of whether you intend the project to be used as a dependency of something else).

Let’s start a new project and see all of these things in play. Create a directory named `SPMTest` and initialize a new project inside of it. You can do so by opening up a terminal prompt, moving to a nice path to put a new project, and then running: 

```
> mkdir SPMTest
> cd SPMTest
> swift package init --type=executable
```

That last command is itself a command directed at SPM telling it to start a new Swift project with boilerplate code. (All SPM commands will begin with `swift package`.) Among the files it creates is a basic Package.swift file which looks like the below:

```swift
// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMTest",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SPMTest",
            dependencies: []),
    ]
)
```

So when SPM does stuff, it basically executes this code file, checks out what gets stored in `package`, a `Package` struct, and uses that data to figure out what it needs to do. You can see that it used the directory name to create a `name` for our package, as well as a `target`. In the array given to the `dependencies` parameter, dependencies are defined; for the other `dependencies` parameter in the target definition, we associate the dependency with the target. 

That might have been a bit confusing, so let’s try to clarify it. In SPM, a package can, in its Package.swift file, declare itself to be a library; a bit of code which is not intended to be an end product, but instead to be used in other end products. Kitura itself is a library. Let’s see what the Package.swift file in a bare-bones library looks like. Go back to your console, `cd` up a level, and run the following:

```
> mkdir SPMLibraryTest
> cd SPMLibraryTest
> swift package init --type=library
```

Note that instead of using `--type=executable` as we did with our previous example, we’re using `--type=library` when running `swift package init`.

The resulting Package.swift file will appear as follows:

```swift
// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMLibraryTest",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SPMLibraryTest",
            targets: ["SPMLibraryTest"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SPMLibraryTest",
            dependencies: []),
        .testTarget(
            name: "SPMLibraryTestTests",
            dependencies: ["SPMLibraryTest"]),
    ]
)
```

Well, it looks mostly similar to our previous example. The two biggest differences is that it automatically added a new target in the top-level `targets` array (which we’ll ignore for now), and there’s now a top-level `products` array. That `.library` bit is what defines the project as a library and gives it the name as defined in the following `name` parameter.

This is all very boring and you may be wondering where I’m going with this. I’m getting there, I promise. Your patience is appreciated.

## Adding a Dependency to Your Project

To properly add a library as a dependency of your project, you need to know three pieces of information which you then need to express in your Package.swift file. They are:

1. The URL of a Git repository which contains the dependency.
2. The desired version of the code you wish to add to your project. In most cases, “version” is expressed as a tagged commit in the repository, and you may want to actually specify a *minimum* version; for example, “version 2.1.0 or later.”
3. The name of the library. This is separate from the URL of the repository or other associated names, as will be shown later.

Let’s say we want to create an app which interacts with an SQLite database (as we do in [chapter 5](../5-kuery.md)). So we want to add the [Swift-Kuery-SQLite](https://github.com/IBM-Swift/Swift-Kuery-SQLite) library to our “SPMTest” project. Let’s go over this step-by-step.

1. First, check out the documentation for any special installation instructions. If the project is hosted on GitHub, as Swift-Kuery-SQLite is (and almost all other libraries you will use in the Kitura ecosystem will be), there may be special instructions on the front page of the repository. In this case there are special instructions on how to install SQLite to your system first.
2. Once those special instructions, if any, are satisfied, open up the Package.swift file for your project. In the `dependencies` section, copy the commented-out line that begins with `// .package`, paste it on a new line right afterwards, then uncomment it. Your resultant `dependencies` section should appear as:
```swift
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: /* package url */, from: "1.0.0"),
    ],
```
We will now “fill in the blanks” on our new line.
3. We need to get the URL to the Git repository itself. Fortunately, GitHub makes this very easy. We can just take the URL of the front page of the repository as hosted on GitHub and append “.git” to the end. So you can just copy the address of the [Swift-Kuery-SQLite project on GitHub](https://github.com/IBM-Swift/Swift-Kuery-SQLite) and paste it into the new line we just created in our Package.swift file, replacing the `/* package url */` part and appending “.git”. We want this to be a string, so we’ll add double-quote characters to the beginning and end as well. The resulting line will appear as:
```swift
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", from: "1.0.0"),
```
4. Now we also want to tell SPM what version of Swift-Kuery-SQLite we want to use. Generally, the easiest way to do this is to click on the “releases” link on the GitHub repo page. This link can be a little bit easy to miss; here’s a screenshot highlighting where you can find it given GitHub’s current UI.
![“Releases” link on GitHub repository](../github-releases.png)
On the resultant page, find the top-most (most recent) release. It will be titled with a version number in a format similar to “1.2.3” - so three numbers separated by dots. Copy that version number, then go back to your code editor and paste that in place in the version number in the `from` parameter. In this case, as I write this, the most recent release of Swift-Kuery-SQLite really is “1.0.0,” so there’s nothing I need to change here, but there may be a newer release by the time you read this.
5. Finally, we want to add our new dependency to the `dependencies` array for our “SPMTest” target. But what do we add to that array? You might think we can just use the name of the repository, so “Swift-Kuery-SQLite” in this case, but I’m afraid it’s not that simple. To get the name of the library to put in here, we actually need to look at the Package.swift file for the corresponding library. Here’s what [Swift-Kuery-SQLite’s Package.swift](https://github.com/IBM-Swift/Swift-Kuery-SQLite/blob/master/Package.swift) looks like - again, as I write this, anyway:
```swift
import PackageDescription
let package = Package(
    name: "SwiftKuerySQLite",
    products: [
        .library(
            name: "SwiftKuerySQLite",
            targets: ["SwiftKuerySQLite"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftKuerySQLite",
            dependencies: ["SwiftKuery", "CSQLite"]
        ),
        .target(
            name: "CSQLite",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftKuerySQLiteTests",
            dependencies: ["SwiftKuerySQLite"]
        )
    ]
)
```
The specific relevant part for us is the `products` attribute:
```swift
    products: [
        .library(
            name: "SwiftKuerySQLite",
            targets: ["SwiftKuerySQLite"]
        )
    ],
```
So that `name` part is what we want to put in the array. What a pain in the butt! Copy that, go back to your Package.swift file, and add it in the `dependencies` array of the `SPMTest` target. Again, don’t forget the double-quotes.
```swift
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SPMTest",
            dependencies: ["SwiftKuerySQLite"]),
    ]
```

All the above done, your final Package.swift file should appear similar to this (the version number may be different):

```swift
// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMTest",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SPMTest",
            dependencies: ["SwiftKuerySQLite"]),
    ]
)
```

Now go back to your terminal window and run `swift package resolve`. This tells SPM to attempt to fetch your dependencies and copy them to your project. Your console should have output which looks something like:

```
Fetching https://github.com/IBM-Swift/Swift-Kuery-SQLite.git
Fetching https://github.com/IBM-Swift/Swift-Kuery.git
Cloning https://github.com/IBM-Swift/Swift-Kuery.git
Resolving https://github.com/IBM-Swift/Swift-Kuery.git at 1.3.0
Cloning https://github.com/IBM-Swift/Swift-Kuery-SQLite.git
Resolving https://github.com/IBM-Swift/Swift-Kuery-SQLite.git at 1.0.0
```

Again, the version numbers might be slightly different.

But wait… Where did that Swift-Kuery bit come from? We didn’t add Swift-Kuery to our Package.swift project; just Swift-Kuery-SQLite. Well, our dependencies can, and often do, have their own dependencies. Go back up and check out the Package.swift file for Swift-Kuery-SQLite; you’ll notice it specifies Swift-Kuery as a dependency. So when the `swift package resolve` command downloads our dependencies, it also checks to see if any of those dependencies have their own dependencies, and so on. This entire structure of dependencies is called the *dependency tree.*

If you check out your SPMTest directory, you might be surprised to see that nothing appears to have changed about it. Where did SPM put the stuff it just downloaded? SPM actually creates an “invisible” subdirectory called “.build” where it stores the code it downloads, among other things. Feel free to look around in there, but be careful that you can “confuse” SPM if you change anything in there manually.

### Specifying Versions

Let’s look at the line where we added the Swift-Kuery-SQlite dependency one more time.

```swift
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", from: "1.0.0"),
```

Note the second parameter, the `from` parameter. What this is saying is that you want to use the newest available release in this repository starting from and including the “1.0.0” release up to, but not including, the “2.0.0” release. So if and when a release with a version number of “1.0.1” becomes available, `swift package resolve` will fetch that version without any change in the Package.swift file necessary - and same with “1.0.2” and “1.1.0 and “1.5.7” and so on. However, since it’s presumed that a “2.0.0” release will have changes so major that it’s possible your project will severely break if that release is used.

There’s a couple other options we can use in place of the “from” parameter. Consider the following:

```swift
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", .exact("1.0.0")),
```

This tells SPM that you *only* want to use the “1.0.0” release. So no matter what new releases may become available - whether “1.0.1” or “1.1.0” or “2.0.0” - SPM will not fetch that new release. This can be useful if you know that a new minor release of a dependency is going to break your project. Similarly, you can use `.revision()` to identify an exact Git commit which you want the dependency checked out to, as below; this can be useful if the desired commit does not have an associated release tag.

```swift
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", .revision("2b65669e24b661787ffdb5c9a5019d7f19e2e8b9")),
```

Finally, you can use `.branch()` to tell SPM to check out the most recent commit (which will not always be the most recent *release)* in the given branch, as follows.

```swift
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", .branch("MyExperimentalBranch")),
```

This can be useful if you’re developing the dependency yourself, as in the case of middleware, and you want SPM to just always fetch the most recent available code in that dependency for you to test against.

There are actually other sorts of parameters you can use here, but these are the most common and useful ones.

## Other Stuff SPM Can Do

### Start a New Project

It was covered above, but just to clarify; you should use SPM to start a new cross-platform Swift project. Don’t do it via Xcode, as you may be used to if you’ve previously written Cocoa applications. (See the [Cross-Platform Swift for Cocoa Developers](a-savvy-devs.md) chapter for more.) Use `swift pacakge init --type=executable` to start a new standard application, or `swift package init --type=library` to start a new library.

### Generate an Xcode project file

If you’re using a Mac, you’ll probably want to use Xcode for your code editor. `swift package init` will not create an Xcode project file for you, and creating one “manually” via Xcode will be messy. Instead, simply run `swift package generate-xcodeproj` and a new Xcode project file will be created for you. You’ll also want to do this whenever you add or update dependencies using `swift package resolve` to make sure Xcode can “see” the newest code.

Note that if you clone someone else’s cross-platform Swift project, customarily the repository will not include an Xcode project file (the .gitignore file `swift packagte init` creates for you actually blocks Xcode project files from being added to the repository). But you can use `swift package generate-xcodeproj` on others’ projects too to get a useful Xcode project file out of it.

Note that the Xcode project file’s name will be based on the name of the directory you run the `generate-xcodeproj` command in; so, for example, if you run the command in our SPMTest project directory, the Xcode project file name will be “SPMTest.xcodeproj”. However, for some reason (not sure if it’s a bug or something even weirder), if the directory name contains a space, the Xcode project file will not be usable; Xcode will tell you that a bunch of stuff is missing and such. Fortunately, there’s an easy fix here; use the `--output` option on the `generate-xcodeproj` command to manually specify a filename for the Xcode project which does not contain a space. For example, I have a project in a directory called “Midnight Post”. To generate a usable Xcode project file for this project, I have to use the command `swift package generate-xcodeproj --output=MidnightPost.xcodeproj` so that the filename of the Xcode project file does not contain a space.

### Get Some Possibly Useful Information

`swift package describe` will have SPM parse your Package.swift file and tell you what it “sees” there. This may be useful if you think SPM is not parsing something in your Package.swift file as it should be.

`swift package show-dependencies` will generate the dependency tree for your project and print it out. This can be useful if you can’t figure out how a certain dependency, or a certain version of a dependency, got added to your project.

### And More!

If you want to go further into SPM’s functionality, check out [its documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation) on GitHub. Specifically, the [documentation for the PackageDescription API](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md), which covers what you’ll find in the Package.swift file, is particularly useful. 

## Troubleshooting

If something goes wrong when you run `swift package resolve`, the following tips should help you find the issue.

* Check that all of the paths to Git repositories in your Package.swift file end with `.git`; for example, `https://github.com/IBM-Swift/Kitura.git` instead of `https://github.com/IBM-Swift/Kitura`. If you try to access the latter as a Git repository, GitHub’s servers will dutifully represent it as a Git repository and let you get away with it - but then if some other project in your dependency tree depends on the same repository and its Package.swift *does* include the path with `.git`, SPM might get confused and think it’s looking at two separate packages.
* Try narrowing down which line in your `dependencies` array is “broken” by commenting them out one by one and running `swift package resolve` after each. Once `swift package resolve` works, the problem probably lies with the last line you commented out.
* Ensure that the release number you are trying to reference actually exists. Sometimes people copy-and-paste a line in the `dependencies` array and change the repo URL, but forget to change the release part and end up referencing releases that don’t exist.
* Using Xcode and not seeing the dependency you added appear in your Xcode project? Remember that you have to re-run `swift package generate-xcodeproj` whenever you add or update a dependency. If you *do* see the dependency in Xcode but Xcode still shows you an error about the module not being available, try building your project anyway - it might just work. Xcode sometimes gets confused about what code it actually has available.
* If a dependency is not being added to your project when you run `swift package resolve`, that you not only added the path and version information under the top-level `dependencies` parameter but also added the library name to the `dependencies` array in the target definition.
* The Delete Freakin’ Everything approach: If at any time you think SPM might be confused about its own state, `swift package reset; rm Package.resolved; swift package resolve` will delete everything SPM has checked out so far and what tags/releases/commits it thinks it needs to check out based on the Package.swift file. It will then re-parse the Package.swift file and try again.
