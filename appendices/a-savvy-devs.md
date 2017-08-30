# CLI Swift for Cocoa developers: What to learn (and unlearn)

This chapter addresses developers who have experience using Swift to write graphical macOS or iOS applications, but are new to Kitura or to the concept of writing cross-platform CLI applications in Swift in general. Our community is young, but it has swiftly developed (terrible pun partially intended) its own best practices which, generally due to Swift’s much higher focus on cross platform compatibility compared to Objective-C, are often at odds with how experienced Cocoa developers do things. The changes you’ll need to make to ensure maximum compatibility of your code and minimum friction with the rest of the community may feel annoying and unnecessary, but all told, they’re really not that difficult.

## Don’t start a new project with Xcode.

To start a new CLI project, create a new directory, `cd` into that directory in a terminal, then run `swift package init --type=executable` if you’re developing a Kitura site or `swift package init --type=library` if you’re developing Kitura middleware. Then run `swift package generate-xcodeproj` to generate an Xcode project file you can then open in Xcode.

Among the files created by this process is a `.gitignore` file which stops various unnecessary files from making it into your Git repository (you will still manually have to initialize the repo with `git init`). If you plan to use Mercurial, Subversion, or some other version control system, please “port” this .gitignore file to the filename and format expected for that system. 

Note that the Xcode project file is one of those excluded in `.gitignore`; if you are collaborating with others on this project, they will need to run the `generate-xcodeproj` command after cloning your project in order to get their own Xcode project file.

## Use Swift Package Manager for package management.

Experienced Cocoa developers are likely familiar with using CocoaPods or Carthage for package management. While these systems will probably still work for Kitura projects, you should learn and use Swift Package Manager instead. SPM is part of the Swift project itself, so any system with Swift installed also has SPM installed, with no further software installation necessary; inherent in this is that SPM will work on macOS, Linux, and whatever other operating systems Swift may get ported to in the future. Nice!

For a quick boot camp in using Swift Package Manager, check out the [Swift Package Manager basics appendix](b-spm.md) in this book.

## You can only count on Foundation.

Swift’s standard library is pretty anemic; fortunately, the Foundation framework, which ships with Swift, fills the gaps and then some. However, it’s important to note that this is the *only* framework you can expect to be present on any system running Swift. GLKit, CloudKit, Metal, PDFKit, Core Image… you cannot expect any of these to be present on other machines running your project. Specifically, any code trying to use these frameworks on Linux will not compile. Speaking of which…

## Test on Linux.

It’s generally rare to run into cases where some bit of code that runs fine on your Mac will not build on Linux, but it’s not unheard of. Thus, I suggest you at least periodically test your code on an Ubuntu Linux system. (If you’re being disciplined about writing automated tests for your project - and you are, right? Right? - just running those tests and ensuring they all pass should suffice.)

If you don’t have a Linux machine handy, a virtual machine will do the job just fine; you can use the commercial Parallels Desktop or VMWare Fusion hypervisors, or Oracle’s open-source VirtualBox. If you’re not too afraid of the command line, I suggest you download and install Ubuntu Server instead of Ubuntu Desktop, then configure its SSH daemon to allow you to shell into the VM from macOS’s Terminal; the Server version of Ubuntu omits all of the graphical user elements present in the Desktop version, so your VM will need less RAM to run and will consume less disk space. (If you feel that your Mac is struggling to run even an Ubuntu Server VM, you may wish to consider getting a VPS account from one of the many server providers around the ‘net.)

Once you’re shelled in, you can find the surprisingly easy steps to install Swift [on the Kitura site](http://www.kitura.io/en/starter/settingup.html). (You can also find instructions on the official Swift site, but Kitura’s instructions will walk you through installing a couple more Linux system packages that Kitura will want to see.)

In the event that you encounter code that needs to be altered to run on Linux, you can use compiler control statements to make the relevant changes apply only when the code is compiled on Linux. For example, in my Kitura Language Negotiation project, I ran into a case where on Mac, the Foundation TextCheckingResult class has a method named `rangeAt(_ idx)`, but the equivalent function on Linux’s Foundation is `range(at: idx)`. (Why this discrepancy? I have no idea.) So the project has the following bit of code to work around that transparently.

    #if os(Linux)
        extension TextCheckingResult {
            /// Add the `rangeAt` method as a wrapper around the `range` method; the
            /// former is available on macOS, but the latter is available on Linux.
            func rangeAt(_ idx: Int) -> Foundation.NSRange {
                return self.range(at: idx)
            }
        }
    #endif
    
See the Compiler Control Statements section in *The Swift Programming Language* for more examples of the statements available in Swift.
