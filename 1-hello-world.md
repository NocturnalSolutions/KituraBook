# Chapter 1: Hello World

> TODO
> * Test on Ubuntu
> * Confirm `--server-response` is the right wget flag

Let’s create a classic [Hello World](http://www.catb.org/jargon/html/H/hello-world.html) example.

Create a new Swift project by doing the following in a command line shell:

    $ mkdir hello-world
    $ cd hello-world
    $ swift package init --type=executable

Now open up the `Package.swift` file and add a dependency for Kitura. It will have a bit of boilerplate in there that you’ll have to modify to add a dependency to Kitura. The end result should look like this.

    // swift-tools-version:4.0
    // The swift-tools-version declares the minimum version of Swift required to build this package.
    
    import PackageDescription
    
    let package = Package(
        name: "hello-world",
        dependencies: [
            // Dependencies declare other packages that this package depends on.
            // .package(url: /* package url */, from: "1.0.0"),
            .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.0.0")
        ],
        targets: [
            // Targets are the basic building blocks of a package. A target can define a module or a test suite.
            // Targets can depend on other targets in this package, and on products in packages which this package depends on.
            .target(
                name: "hello-world",
                dependencies: ["Kitura"]),
        ]
    )



Have the Swift Package Manager resolve Kitura and its dependencies and add them to your project.

    $ swift package resolve

If you’re on macOS and wish to use Xcode as your code editor, now’s the time to create a new Xcode project and open it up. (If you’re not on macOS or not using Xcode, ignore the following.)

    $ swift package generate-xcodeproj
    $ open hello-world.xcodeproj

Now note that your project won’t build properly in Xcode unless you change the scheme to be your real application. I don’t know why this is; if it’s a glitch in Swift Package Manager, Xcode, or both. At any rate, you have to do it every time you use `generate-xcodeproj`. From the scheme menu to the right of the “stop” button, change the scheme from “hello-world-Package” to just “hello-world.”

![Scheme selection](../images/scheme-select.png)

Okay, let’s add some code. Open up the `Sources/main.swift` file in your editor. Delete what SPM has put in there by default and enter the following:

    import Kitura
    
    let router = Router()
    
    router.get("/") { request, response, next in
        response.send("Hello world!\n")
        next()
    }
    
    Kitura.addHTTPServer(onPort: 8080, with: router)
    Kitura.run()

(Note: If you already have a network service running on IP port 8080 on your development machine, try another port number, such as 8081 or 8888. Remember to substitute that number for 8080 in all examples throughout this book.)

Now build and run your project. Back in your console window, enter:

    $ swift build

If all goes well, the last line will be:

    Linking ./.build/[Your hardware architecture and OS]/debug/hello-world
    
That’s where your compiled binary was saved. So let’s run that.

    $ ./.build/[Your hardware architecture and OS]/debug/hello-world

If all goes well, the program will execute without any output.

Now open up a second terminal window and hit your new Kitura site!

    $ curl localhost:8080/
    Hello world!

Note that I will use the Curl command line client for this and other examples in this book, but you can of course use wget if you prefer it or simply don’t have Curl installed.

    $ wget localhost:8080/
    Hello world!

Aside from just the body of your response, your Kitura site is sending standard HTTP headers. You can check this by adding the `--include` flag to your Curl command. (If you’re using wget, add a `--server-response` flag.)

    $ curl --include localhost:8080/
    HTTP/1.1 200 OK
    Date: Sun, 27 Aug 2017 03:37:28 GMT
    Content-Length: 13
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99

    Hello world!

Now just for fun, let’s see what happens if we access a path other than “/“ on our server. Let’s try the “/hello” path:

    $ curl --include localhost:8080/hello
    HTTP/1.1 404 Not Found
    Date: Sun, 27 Aug 2017 03:39:23 GMT
    Content-Length: 18
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    Cannot GET /hello.

Oh, we got a 404 error. You may be able to guess why, but if not, I’ll explain it later in this chapter.

Back in the terminal window that’s running your program, you can stop execution by typing Control-C, or ^C in standard Unix notation.

Note that Xcode users can run your project by using the “Run” command in the “Product” menu or by pressing the “Play” button in the toolbar rather than using the command line to build and execte your compiled project, and indeed this process is generally faster for Xcode users. You should also know how to do it via the command line, however. You can try it now, but don’t forget to halt the program in the terminal first.

## So what did we do?

First, we created a new project with Swift Package Manager. The full scope of what SPM can do is outside the scope of this book; if you are unfamiliar with it, have a look at the “[Swift Package Manager basics](../appendices/spm-basics/spm-basics.md)” appendix in this book for the basics as far as Kitura development is concerned. As fair warning, later chapters in this book will not give you a step-by-step process for adding new packages to your project and instead merely say something like “add package X to your project.”

Then we added some code. Let’s go through it line by line.

    import Kitura

We are importing the Kitura module into the scope of `main.swift` for further use by our code.

    let router = Router()

We are instantiating a new Router object, which is provided by Kitura. Routers will be covered in more depth in a future chapter. For now, know that routers are how we define paths that our site will listen for and what happens when a request for that path is made to the server.

    router.get("/") { request, response, next in

We are creating a handler for the “/“ path; specifically, for GET HTTP requests made to the “/“ path. (We’ll learn how to handle other types of requests in a later chapter.) Note that in our code, this is the only path for which we are creating a handler. This is why we got a 404 error when we tried the “/hello” path above. (Up for a bit of experimentation? Try changing this to “/hello” or any other path and rebuild your project. Just remember to keep that slash at the beginning of the path.)

The part that begins with a curly brace is an escaping closure parameter. It’s actually a closure which is passed as a parameter to the “get()” method on the Router object instance, even though it is outside of the parentheses. If you’re like me, this syntax is pretty bizarre, but you’re going to want to get used to it, because Kitura uses it everywhere. Have a look at the “Escaping Closures” section of *The Swift Programming Language* for more information on what’s being done here. For now, if it helps, think of this line being functionally equivalent to:

    router.get("/", handler: (request: RouterRequest, response: RouterResponse, next: RouterHandler) {

…even though that code won’t actually work.
    
Finally, `request, response, next in` specifies that our closure that we just began has three parameters passed to it: `request`, which is a Kitura RouterRequest instance with information about the incoming request; `response`, which is a Kitura RouterResponse object with information about the response we want to send to the client that made the request; and `next`, which is itself a closure. I’ll explain that `next` parameter more later in this chapter; first, we should explain the rest of the code in this example.

        response.send("Hello world!\n")

The first line in our handler simply sends a string composed of “Hello world!” followed by a standard line break character to the client. It does this by invoking the `send()` method of the RouterResponse instance that was passed to our handler.

        next()

Call the next handler that can respond to this route. Again, I will go further in depth to the `next` parameter later in this chapter.

    }

End our route handler closure.

    Kitura.addHTTPServer(onPort: 8080, with: router)

Tell Kitura that we want to start an HTTP server that’s listening on port 8080, and we want it to use the paths and handlers we defined to our Router instance `router`.

    Kitura.run()

Finally, start the HTTP server. The server will continue running until either a major error occurs or the process is interrupted (as you do when you type Control-C into the terminal where Kitura is running).

Congratulations, you are now a Kitura hacker! The rest of the book will basically just be expanding on what we’ve learned here.

## About that `next` parameter…

The `next` parameter needs further explanation. In Kitura, it’s perfectly valid to have more than one handler for a given route. You can think of each handler which is going to respond to a request as being in a chain. The next link in the chain - the next handler that should be invoked for the route - is passed in as the `next` parameter. That’s why it’s important to remember to always include `next()` after normal execution of the code in your handler. The exception - when you do *not* want to invoke `next` - is when an error has happened and we want to abort any further “normal” response to the client; for example, if the user is trying to access a resource they don’t have access to, we should send their client a 403 error and stop any further execution.

You can test this “chain” behavior by adding a second handler to our code. Add this right before the `Kitura.addHTTPServer(onPort: 8080, with: router)` line:

    router.get("/") { request, response, next in
        response.send("And hello again!\n")
        next()
    }

Our code now has two simple handlers for the “/“ path. (If you experimented by changing “/“ to “/hello” or some other path in the first route handler above, either change it back or have this handler use that same new path; either way, make sure the first parameter to the `get` method is equivalent). Now do another request in the command line, and check out how the output has changed.

    $ curl localhost:8080/
    Hello world!
    And hello again!

See? Our handlers fired one after the other, as expected. But now go back to the first handler and comment out or delete the `next()` line. Build your project and test your site again:

    $ curl localhost:8080/
    Hello world!

Oops. As you can see, failing to call `next()` from our first handler means our second one didn’t get invoked. So don’t forget your `next()` line!

To help them not forget, many coders will wrap their `next()` lines in a `defer` block at the beginning of their callbacks, like this:

    router.get("/") { request, response, next in
        defer {
            next()
        }
        response.send("Hello world!\n")
    }

Code in the `defer` block is executed right before the function returns, no matter where or how the function returns, so the code in this handler closure is functionally equivalent to the first one we wrote above. (See the “Defer Statement” section in *The Swift Programming Language* for more information on this structure.) However, since we don’t *always* want to call `next()` - as above, there will be important exceptions - I don’t want you to get in the habit of using `defer` blocks in your handlers this way, and will not use it in further examples in this book. You will see this pattern used frequently in others’ Kitura code around the web, however, so I feel it’s important to explain what’s happening in that code.

## Kitura serves itself?!

Now if you’re familiar with web development with scripted languages like Ruby and PHP, you may be surprised right now that our Kitura application is serving itself directly to the browser without having to connect to a web server daemon like Apache or Nginx through FastCGI or SCGI. Yes, this is a feature inherent in Kitura; it itself is a web server, and unlike PHP or Ruby’s built-in web servers, it’s fully performant enough to use in production environments.

That being said, it’s trivial to have Kitura to operate as a FastCGI application served through a web server as well. Reasons this may be desirable is for ease of SSL certificate configuration, integration of both Kitura and non-Kitura applications on one server, and higher-performance static file serving, among countless others. Simply replace the line:

    Kitura.addHTTPServer(onPort: 8080, with: router)

…with one like this:

    Kitura.addFastCGIServer(onPort: 9000, with: router)
    
And then configure your web daemon accordingly. See the [Kitura FastCGI](http://www.kitura.io/en/resources/tutorials/fastcgi.html) page on IBM’s official Kitura site for more information.

For consistency and simplicity’s sake, however, all examples in this book will use Kitura’s built-in server functionality.

## Adding logging with HeliumLogger

Logging can be quite helpful when developing web applications. To that end, IBM has developed [LoggerAPI](https://github.com/IBM-Swift/LoggerAPI), an API for logging implementations, and [HeliumLogger](https://github.com/IBM-Swift/HeliumLogger), a lightweight implementation of a logger for that API.

Try adding the HeliumLogger package to your project now. (You don’t need to add the LoggerAPI package, as it is already a dependency of Kitura.) Run `swift package resolve` again so that SPM downloads HeliumLogger and adds it to your project. Import LoggerAPI and HeliumLogger into your `main.swift` file, then add the following lines immediately following the `import` statements:

    let helium = HeliumLogger(.verbose)
    Log.logger = helium

(If you’re using Xcode and it’s giving you trouble, don’t forget to run `swift package xcode-generateproj` and reset the build scheme as outlined earlier in this chapter.)

Now build and run your project instead. This time, instead of seeing nothing in the console as your project runs, you should see something similar to the following:

    [2017-08-28T23:16:52.182-00:00] [VERBOSE] [Router.swift:74 init(mergeParameters:)] Router initialized
    [2017-08-28T23:16:52.198-00:00] [VERBOSE] [Kitura.swift:72 run()] Starting Kitura framework...
    [2017-08-28T23:16:52.198-00:00] [VERBOSE] [Kitura.swift:82 start()] Starting an HTTP Server on port 8080...
    [2017-08-28T23:16:52.200-00:00] [INFO] [HTTPServer.swift:117 listen(on:)] Listening on port 8080

Yep! Kitura is logging stuff now. Try accessing your server with a client and note how Kitura also logs page requests with lines such as the following:

    [2017-08-28T23:22:40.488-00:00] [VERBOSE] [HTTPServerRequest.swift:215 parsingCompleted()] HTTP request from=127.0.0.1; proto=http;

You can, of course, implement your own logging. Inside one of the router handlers in your project, try adding the following line:

    Log.info("About to send a Hello World response to the user.")

Build your project, do a page request, and note that your line is dutifully logged to the console.

As you may have guessed, LoggerAPI supports logging messages of varying severity levels, which are, in order of least to most severe: debug, verbose, info, warning, and error. Just call the corresponding static method on the `Log` object. Try adding some lines like the following to your routes:

    Log.verbose("Things are going just fine.")
    Log.warning("Something looks fishy!")
    Log.error("OH NO!")

You can also use these severity levels to determine which log messages you want to see when initializing HeliumLogger. We used the following line to initialize HeliumLogger above:

    let helium = HeliumLogger(.verbose)

This means that HeliumLogger will show messages of verbose severity and higher, but ignore debug messages. If you only want to show messages of the warning and error severity levels and ignore those of info severity and lower, simply do:

    let helium = HeliumLogger(.debug)

Later examples in this book will periodically use logging, and you are of course free to add your own logging to help you trace through the code.

So logging to the console is great and all, but can’t HeliumLogger log to stderr or files on disk as most other logging systems can? The answer is yes, but not out of the box; you need to write an implementation of TextOutputStream that writes data where you want it to go, then pass it as a parameter as you instantiate a HeliumStreamLogger object rather than a HeliumLogger one. This is less painful than it sounds; nonetheless, I will leave it as an exercise to the reader.
