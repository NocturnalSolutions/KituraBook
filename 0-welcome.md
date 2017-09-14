# Welcome to Kitura!

## What is Kitura?

Kitura is a lightweight web development framework written in the Swift programming language. It was developed by a team at IBM and released as open source software under the Apache 2.0 license (the same as Swift itself) in early 2016.

Though Kitura has received continued attention and promotion from Big Blue, Kitura hasn't quite caught the world on fire yet. Perhaps the world does not need Yet Another Web Framework. Even if you decide to use Swift to write your server-side application, Kitura has competition among other Swift web frameworks like Vapor and Perfect. That, and Kitura’s documentation is sort of all over the place, and of uneven quality and coverage among its various sister packages like Kuery (for database connectivity) and Kitura-TemplateEngine (for templating). Well, I can’t fix all those other problems, but I can fix that last one.

## Why Kitura?

* Because Swift is a great programming language. Originally announced by Apple in 2014 to replace the aging, eternally-quirky Objective-C in the Apple ecosystem, it is modern, friendly, sleek, and fun.
* Because it’s backed by IBM, who perhaps is second only to Apple in terms of adoption and promotion of Swift in the enterprise space. IBM provides Swift application hosting on their Bluemix cloud platform and is supporting it on their enterprise Linux and Unix operating systems like PowerLINUX and z/OS - seriously heavy iron stuff. IBM is likely to continue supporting Swift and Kitura for the foreseeable future.
* As Swift is a compiled language, web applications written in Kitura will generally run much faster than those written in scripting languages like PHP, Python, Perl, or Ruby (though things like opcode caches for those languages can close the gap when used).

## Why not Kitura?

* Because Kitura and Swift in general is still rather new, you may occasionally run into libraries and such which do not yet have great Swift support. While this isn’t such a problem if you’re the type that doesn’t mind writing code to integrate Swift with C or C++ libraries (and I’m definitely not one of those people), it’s still more work to do.
* Kitura is a very low-level framework, along the lines of Laravel or Ruby on Rails, so while it’s very quick to implement something like a REST interface that provides JSON responses for consumption by, say, a client app on iOS, building something like a blog will take considerably more work than it would using a more full-featured web framework or content management system like WordPress, Drupal, or Alfresco. That being said, building full-featured web sites with Kitura is certainly possible, as later examples in this book will show.
* Because compiling Swift code is currently not widely supported outside of macOS, Ubuntu Linux, and the IBM operating systems mentioned above. Most notably, Windows support is missing, and I sincerely hope there are some people from Apple and/or Microsoft and/or IBM working on that. There are *unofficial* ports of Swift to Windows and other Linux flavors, as well as FreeBSD, but your mileage may vary on the effectiveness of these systems.

## What you should know

This book makes some assumptions about what you already know about software development and the workings of the web. Please review the list below. If anything in the list is unfamiliar to you, I suggest you bone up on those things before diving deep into this book.

* **Software development with Swift.** Though this book will periodically teach or review certain aspects of Swift which may be unexpected or unusual for those not strongly familiar with it, it is not intended as a thorough introduction to Swift programming. At the least, you should have read Apple’s *The Swift Programming Language* book, though I’ll accept just reading the “A Swift Tour” section of the book if you’re already familiar with contemporary object-oriented programming languages such as C# or Java. You should already have Swift installed on your development machine and know how to build and run a basic command-line application. You do *not* need to be an experienced iOS or macOS developer; in fact, if you are, there’s actually probably a few things you will need to *unlearn* to become an effective Kitura developer. See the [CLI Swift for Cocoa developers](appendices/a-savvy-devs.md) appendix for more information if this applies to you.
* **General knowledge about HTTP.** The Hypertext Transfer Protocol is how web clients and web servers talk to each other. You should know about the different parts of a URL. You should know the meaning and usage of common HTTP status codes like 200 OK and 404 Not Found, as well as common client and server HTTP headers.
* **HTML.** The Hypertext Markup Language is how a simple text file can be interpreted by a web browser as a functional web page. You should know common HTML tags and page structure. Earlier chapters in this book will not deal with server responses in HTML, but later ones will.
* **SQL and associated concepts.** Structured Query Language is used by relational database systems such as PostgreSQL, MySQL, SQLite, or Microsoft SQL Server to read and manipulate data. You should understand common database structures such as tables, rows, and columns.
* **Swift Package Manager.** This is the modern way to add “packages” of additional code to your project. As I expect a major part of the audience of this book will be Cocoa developers who are familiar with using CocoaPods or Carthage for this purpose, this book includes an [appendix chapter introducing SPM](appendices/b-spm.md). Additionally, you should understand the concept of semantic versioning; the appendix will cover this as well.
* **Git.** You should know how to create new repositories, commit changes, and tag commits. You should have Git installed on your development server. If you wish to use a different version control system for your sites, that’s fine, but the chapter in this book on creating middleware will involve creating a new Swift Package Manager package, which requires experience with Git.

## Getting help

You are not alone. As you go along, if you get stumped by something, don’t hesitate to reach out for help and clarification.

The Swift@IBM team site has a public Slack instance at http://swift-at-ibm-slack.mybluemix.net/ . (Slack is a somewhat obnoxious chat application targeted towards teams and workgroups.) There are several channels including #kitura for Kitura discussion and #general which is good for general Swift development or other topics in the ecosystem. You can find me there under the username “nocturnal.” Feel free to reach out to me if you’re having any trouble with something in this book.

If Slack’s not your thing, you can also join the Freenode IRC network. It doesn’t have any Kitura-specific channels currently (unfortunately), but it does have #swift-lang which is great for general Swift discussion; there’s lots of smart people there. There may be other Swift-related channels in the IRC universe, but I like Freenode because its focus on open-source software means that if you need help with any other open-source (and some not-so-open-source) software you use throughout the day, you can probably find a channel related to it on Freenode. If you’re a Cocoa developer, #iphonedev and/or #macdev may also be of interest; #iphonedev-chat is a fun channel to hang out and shoot the stuff with others in the community. On Freenode, you can find me using the “_Nocturnal.” Again, feel free to reach out and say hi! You can find more information about Freenode at https://freenode.net .

If you’re interested in another ebook that focuses on Kitura, consider *Server-Side Swift* by Paul Hudson. I haven’t read it myself, but I presume that, while his book is US$30 and mine is free, you will probably get what you paid for in both cases. Check out https://www.hackingwithswift.com/store/server-side-swift for more information and a sample of the book.

Finally, don’t forget about the GitHub Issues queues on most projects hosted there. They’re generally intended for reporting bugs and such, but you’re generally welcome to ask for help with usage there too.
