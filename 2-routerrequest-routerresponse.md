# Chapter 2: Ins and Outs of RouterRequest and RouterResponse

> TODO: 
> - Follow my own advice and test on Linux
> - How do you do a POST with Wget?

Let’s look back at that router handler we wrote in the last chapter.

    router.get("/") { request, response, next in
        response.send("Hello world!\n")
        next()
    }

You may recall that I mentioned that `request` was a RouterRequest object and that `response` was a RouterResponse object. Every route and middleware handler that we write will receive instances of these two objects. In this chapter, we’ll take a closer look at these objects and what we can do with them.

## RouterRequest

RouterRequest contains information about the incoming HTTP request. Here’s a non-exhaustive example of some things we can find there. Try adding this to your project from the last chapter. (Or create a new project, if you prefer; just don’t forget you need to instantiate the `router` variable and initiate Kitura at the end.)


    router.all("/request-info") { request, response, next in
        response.send("You are accessing \(request.hostname) on port \(request.port).\n")
        response.send("You're coming from \(request.remoteAddress).\n")
        // request.method contains the request method as a RouterMethod enum
        // case, but we can use the rawValue property to get the method as a
        // printable string.
        response.send("The request method was \(request.method.rawValue).\n")
        // Request headers are in the headers property, which itself is an instance
        // of a Headers struct. The important part is that it's subscriptable, so
        // go ahead and treat it like a simple [String: String] dictionary.
        if let agent = request.headers["User-Agent"] {
            response.send("Your user-agent is \(agent).\n")
        }
    }

Note that we’re using the `all()` method here instead of the `get()` one as we’ve used before. Using `get()` tells Kitura we want our handler to fire only on GET requests, whereas using `all()` tells Kitura we want it to fire on *all* request methods - GET, POST, and so on. These methods and Router objects in general will be examined in more depth later in this book.

Now we’ll request the path using Curl’s `-d` flag to post an empty string to our request path.

    $ curl -d "" localhost:8080/request-info 
    You are accessing localhost on port 8080.
    You're coming from 127.0.0.1.
    The request method was POST.
    Your user-agent is curl/7.54.0.

The `queryParameters` property is a [String: String] dictionary of the query parameters.

    router.get("/hello-you") { request, response, next in
        if let name = request.queryParameters["name"] {
            response.send("Hello, \(name)!\n")
        }
        else {
            response.send("Hello, whoever you are!\n")
        }
    }

And the result:

    $ curl localhost:8080/hello-you
    Hello, whoever you are!
    $ curl "localhost:8080/hello-you?name=Nocturnal"
    Hello, Nocturnal!

There are a few more things that RouterRequest contains that are of varying level of interest, but these are the most relevant ones in my not so humble opinion. For now, have a look at `RouterRequest.swift` in the Kitura project if you’re curious what else you can find there - but then come right back, because things will get more interesting soon.

## RouterResponse

The flip side to RouterRequest, which manages data coming in, is RouterResponse, which manages data going out. You’ve already seen in previous examples how we used the `send()` method to output strings that are sent to the user-agent; strictly speaking, each of those calls to `send()` is appending the string to the body of the HTTP response.

We can use RouterResponse’s `status()` method to set a custom status code. Pass it a case from the `HTTPStatusCode` struct (defined in KituraNet’s `HTTP/HTTP.swift` file). Let’s have a little bit of fun with that.

    router.get("/admin") { request, response, next in
        response.status(.forbidden)
        response.send("Hey, you don't have permission to do that!")
    }

When we test with Curl, we get the expected status code.

    $ curl --include localhost:8080/admin
    HTTP/1.1 403 Forbidden
    Date: Wed, 30 Aug 2017 20:50:44 GMT
    Content-Length: 42
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    Hey, you don't have permission to do that!

RouterResponse has a `headers` property that works just like the one on RouterResponse.

    router.get("/custom-headers") { request, response, next in
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        response.headers["X-Generator"] = "Kitura!"
        response.send("Hello!")
    }

Here’s the response. Note the new headers.

    $ curl --include localhost:8080/custom-headers
    HTTP/1.1 200 OK
    Date: Wed, 30 Aug 2017 21:09:49 GMT
    Content-Type: text/plain; charset=utf-8
    Content-Length: 6
    X-Generator: Kitura!
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    Hello!

We could set a 301 Moved Permanently or 308 Moved Temporarily status and a “Location” header to redirect the user from one path to another, but RouterRequest provides some shorthand to do that.

    router.get("/redirect") { request, response, next in
        // Redirect the client to the home page.
        try! response.redirect("/", status: .movedPermanently)
    }

(Confused by `try!` above? See the “Error Handling” section of *The Swift Programming Language* for more information.)

We’ll test by using Curl’s `--location` flag to tell it to follow “Location” headers when encountered.

    $ curl --include --location localhost:8080/redirect
    HTTP/1.1 301 Moved Permanently
    Date: Wed, 30 Aug 2017 20:46:24 GMT
    Location: /
    Content-Length: 0
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    HTTP/1.1 200 OK
    Date: Wed, 30 Aug 2017 20:46:24 GMT
    Content-Length: 13
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=98
    
    Hello world!

Really, though, the star of the show is RouterResponse’s `send()` method - or, should I say, *methods.* The one we’ve used in this book so far has had the following signature:

    @discardableResult public func send(_ str: String) -> RouterResponse

(That’s right; this whole time, the method has been returning a reference to the RouterResponse object itself, for chaining purposes. We’ve been ignoring it thus far and will probably continue to do so in this book, but just know this basically means you can do something like `response.send("foo").send("bar")` if you wish.)

RouteResponse has many other `send()` methods, though. For example, if we wanted to send binary data to the server - say, an image generated by an image library - we can use this one:

    @discardableResult public func send(data: Data) -> RouterResponse

Or we can send a file read from the disk:

    @discardableResult public func send(fileName: String) throws -> RouterResponse

This book will not demonstrate these methods, but it might be handy to know they exists in the future.

For those of you interested in using Kitura to build a REST API server, you might be glad to know that RouterResponse has many methods for sending JSON responses, including the following two for sending a response currently in the form of a Foundation JSON object and a [String: Any] dictionary, respectively:

    @discardableResult public func send(json: JSON) -> RouterResponse
    
    @discardableResult public func send(json: [String: Any]) -> RouterResponse

Later chapters in this book *will* give examples of sending JSON responses to the client, so let’s play with that last one now.

    router.get("/stock-data") { request, response, next in
        // Completely made up stock value data
        let stockData = ["AAPL": 120.44, "MSFT": 88.48, "IBM": 74.11, "DVMT": 227.44]
        response.send(json: stockData)
    }

And here’s the output:

    $ curl --include localhost:8080/stock-data
    HTTP/1.1 200 OK
    Date: Wed, 30 Aug 2017 21:23:12 GMT
    Content-Type: application/json
    Content-Length: 75
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    {
      "MSFT" : 88.48,
      "DVMT" : 227.44,
      "IBM" : 74.11,
      "AAPL" : 120.44
    }

Note how Kitura automatically added a “Content-Type: application/json” header for us.

## Bringing it together

Let’s make a route with a path of “/calc” that takes two query parameters, “a” and “b,” adds them together, and returns the response. Let’s have our handler respond accordingly in the case that one or both parameters are missing or could not be converted to numbers (in this case, Float objects).

If you’ve been doing all right following along so far, I challenge you to stop reading now and go ahead and try to implement this yourself before peeking at the code sample below. My code doesn’t use anything that hasn’t been covered in this book so far. This time I’m going to show you my code’s output when I test it with Curl first, and show you the code later.

    $ curl --include localhost:8080/calc
    HTTP/1.1 400 Bad Request
    Date: Wed, 30 Aug 2017 21:55:57 GMT
    Content-Length: 33
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    "a" and/or "b" parameter missing
    $ curl --include "localhost:8080/calc?a=7&b=kitura"
    HTTP/1.1 400 Bad Request
    Date: Wed, 30 Aug 2017 21:56:18 GMT
    Content-Length: 57
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    "a" and/or "b" parameter could not be converted to Float
    $ curl --include "localhost:8080/calc?a=7&b=8"
    HTTP/1.1 200 OK
    Date: Wed, 30 Aug 2017 21:56:24 GMT
    Content-Length: 19
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    The result is 15.0
    $ curl --include "localhost:8080/calc?a=12.44&b=-88.2"
    HTTP/1.1 200 OK
    Date: Wed, 30 Aug 2017 21:56:42 GMT
    Content-Length: 21
    Connection: Keep-Alive
    Keep-Alive: timeout=60, max=99
    
    The result is -75.76

Okay, here’s my code. How does yours compare? (Of course, if yours is quite different, that doesn’t mean it’s wrong!)

    router.get("/calc") { request, response, next in
        guard let aParam = request.queryParameters["a"], let bParam = request.queryParameters["b"] else {
            response.status(.badRequest)
            response.send("\"a\" and/or \"b\" parameter missing\n")
            Log.error("Parameter missing from client request")
            return
        }
        guard let aVal = Float(aParam), let bVal = Float(bParam) else {
            response.status(.badRequest)
            response.send("\"a\" and/or \"b\" parameter could not be converted to Float\n")
            Log.error("Parameter uncastable")
            return
        }
        let sum = aVal + bVal
        Log.info("Successful calculation: \(sum)")
        response.send("The result is \(sum)\n")
    }


If you’re an experienced web developer, you may be cringing at the use of query parameters. Can’t Kitura let us use a nice pretty path with no query parameters instead - maybe something like “/calc/12.44/-88.2”? Well, of course it can, and we’ll find out how when we examine Kitura’s Router object in the next chapter.
