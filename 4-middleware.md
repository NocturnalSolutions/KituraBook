# Chapter 4: Middleware

When it comes to web applications, middleware is code which provides functionality that router handlers can take advantage of, but which doesn't necessarily output anything on its own like the router handlers do.

For example, I myself wrote a package called Kitura Language Negotiation which provides Kitura middleware that investigates various aspects of a client’s request and attempts to determine what human language (English, Spanish, French, etc.) the visitor wants to be served. A router handler on the site can then use KLN's calculation to serve content to a user in their desired language. Another example, which we will examine more closely later in this book, is Kitura Session from IBM themselves, which manages and maintains data associated with particular users which persists between page requests.

Let’s write some simple middleware, then see how we would use it on a site.

## Writing middleware

An important thing to note when starting a new project which will contain only middleware and no router handlers itself is that, when you run `swift package init`, you want to use `library` for your `--type` option instead of `executable`. In other words, instead of running `swift package init --type=executable` as you would for new Kitura site, you use `swift package init --type=library`. This is because we are building a bit of code which can be used in other sites which will be actual executables, but we aren’t building anything that should be built as an executable itself. Go ahead and do that now; start a new library project in a directory called KituraFirefoxDetector.

To create Kitura middleware, we create an object which conforms to Kitura’s RouterMiddleware protocol. This protocol requires one function, with this signature:

    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws

Wow. That looks pretty familiar, doesn’t it? Yep, just like with router handlers, our “handler” gets passed RouterRequest and RouterResponse objects, as well as a `next` function. 

Our example here will detect if the user is using Firefox as a browser. One property on Kitura’s RouterRequest object that I didn’t mention previously is a `userInfo` property. This is a [String: Any] dictionary which is useful for storing data that we’ve calculated in a middleware handler so that it can be accessed by router handlers (or, theoretically, other middleware handlers, though of course those middleware handlers need to be executed after the handler which sets the data). So our middleware handler will set `userInfo["usingFirefox"]` to true if the user is using Firefox, and false otherwise.

Okay, now that we’ve set the table, let’s start writing code. Add Kitura as a dependency to your new project and fetch it. Open up `Sources/KituraFirefoxDetector.swift`, delete what SPM put there by default, and add the following.

    import Kitura
    import Foundation
    
    public class FirefoxDetector: RouterMiddleware {
        public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
            if let ua = request.headers["User-Agent"], ua.contains("Firefox") {
                request.userInfo["usingFirefox"] = true
            }
            else {
                request.userInfo["usingFirefox"] = false
            }
            next()
        }
    
        public init () {
        }
    }

Let’s analyze this a bit.

First, note that we called the new class `FirefoxDetector` instead of `KituraFirefoxDetector`. This is something of a standard - more of a loose custom - in Kitura development; the project name contains “Kitura” at the beginning, but the actual class does not.

Next, note the `public` all over the place here. This is an important thing which still trips me up all the time; if you don’t specify an access level to the classes, methods, and properties, Swift gives them an implicit access level of `internal`, which means that those things are not accessible from other modules (or, in our case here, packages). Our middleware is not going to work unless everything involved is explicitly defined as `public` - and that includes making an empty `init` method as here. It looks silly, but if not done, Swift creates its own implicit `init` method - with an `internal` access level.

Finally, note how we need to call `next()` at the end of our code just as with a route handler. If you write middleware and omit `next()`, your route handlers actually won’t be called either!

Create a new Git repository in your project’s directory, but before you commit anything, edit the `.gitignore` file and add the `Pacakge.pins` file - we don’t want that file included in repositories for libraries like Kitura middleware. Commit your code and tag it as version `0.0.1`.

## Using middleware

Now create a new Kitura project and add KituraFirefoxDetector as a dependency. (Remember, you don’t need to push the project to GitHub or some other hosting service first; give it a URL comprised of “file://” followed by the absolute path to your UA-Detector directory (including the initial slash) and it will work just fine.) Fetch the dependencies.

Okay, now that our new project has the new middleware package we’ve created, let’s actually use it. This is done by instantiating an object of the middleware’s class and then adding it to a path by way of our friend the Router object. We’ll then create a route handler which shows a different message depending on whether our middleware detected the user was using Firefox or not. Place the following in `Sources/main.swift`.

    import Foundation
    import Kitura
    import KituraFirefoxDetector
    
    let router = Router()
    
    let detector = FirefoxDetector()
    
    // Declare middleware for a path.
    router.get("/ffclub", middleware: detector)
    // Now add a handler.
    router.get("/ffclub") { request, response, next in
        guard let clubStatus = request.userInfo["usingFirefox"] as? Bool else {
            response.send("Oops! Our middleware didn't run.")
            next()
            return
        }
        if clubStatus {
            response.send("Congrats! You're in the club!")
        }
        else {
            response.send("Hey! You need to use Firefox to be in the club.")
        }
        next()
    }
    
    Kitura.addHTTPServer(onPort: 8080, with: router)
    Kitura.run()

(An aside: This is a simple and contrived example for the sake of teaching middleware usage. In reality, it is a *very* bad practice to alter your site’s content or restrict access based on what browser a visitor is using. Please have fun experimenting, but *never* do this sort of thing on a real site. Thank you.)

So we added the middleware to the path with `router.get("/ffclub", middleware: detector)`. More on that later. The only other thing I’ll mention about this bit of code is a reminder that `request.userInfo` is a [String: Any] dictionary, which is why we need to cast it to a useful type (`as? Bool`). The rest should be straightforward.

Build and run the site, and try visiting it with both Firefox and other clients. (If you don’t have Firefox, you can usually use the developer tools of other browsers to make them pretend to be Firefox.)

Okay, so that was interesting, but why did we bother using middleware to do this? We could have just put the same code that’s in the middleware handler into the standard route handler. Well, one of the benefits of middleware is that it is simple to reuse the code for different paths. Say we had a route with a path of `/admin` and we want to check that visitors to that path are using Firefox too.

    router.get("/admin", middleware: detector)
    router.get("/admin") { request, response, next in
        // …
    }

And just like that, we will also have `request.userInfo["usingFirefox”]` available for this route handler too. (Note we don’t have to instantiate a new FirefoxDetector object; we can reuse the one we already created.)

As with route handlers, we can use different methods on the Router object corresponding to different HTTP methods to apply our middleware to paths, as in the following.

    router.post("/admin", middleware: detector)
    
    router.all("/admin", middleware: detector)

We can also have middleware fire for *all* requests to a site regardless of path by omitting the path parameter. The first line below will have our middleware fire for all HTTP GET requests, regardless of path, and the second will have the middleware fire for all requests, regardless of path *or* method.

    router.get(middleware: detector)
    
    router.all(middleware: detector)

But back to our project. What were to happen if we added another handler that looks like this?

    router.get("/admin/subpath") { request, response, next in
        guard let clubStatus = request.userInfo["usingFirefox"] as? Bool else {
            response.send("Oops! Our middleware didn't run.")
            next()
            return
        }
        response.send("The middleware ran.")
        next()
    }

Well, we didn’t do `router.get("/admin/subpath“, middleware: detector)`, so if we try to access `http://localhost:8080/admin/subpath`, we’ll get the “Our middleware didn’t run” message, right? Go ahead and try it, and you’ll see that we actually see the “The middleware ran” message. What’s happening?

Well, there is one difference between how handler closures and how middleware are assigned to routes. By default, middleware will run for the path given, plus any and all subpaths. So when we did `router.get("/admin", middleware: detector)` above, we implicitly told Kitura to run that middleware for any subpaths of `/admin` too, of which `/admin/subpath` is an example. This can be quite handy at times. For example, say you have a section of your site that should only be accessible to site administrators. You can write some middleware which checks that the current user is logged in and has an administrator account and bind it to the `/admin` path. Now just have all the paths for that secret administrator-only section of your site have a path under `/admin`. There you go.

Should you wish to disable this subpath behavior and bind a middleware handler to a path without also allowing it to run on subpaths, you can add an `allowPartialMatch` parameter and explicitly set it to false. The following example will have our middleware fire when the `/admin` path is accessed regardless of HTTP method, but will *not* have it fire on any subpaths.

    router.all("/admin", allowPartialMatch: false, middleware: detector)

## Subrouters

I won’t spend too much time on subrouters as they’re kind of an unusual feature which may not be widely useful, but you should at least know about them. The gist is that Kitura Router objects themselves conform to the RouterMiddleware protocol, so you can actually add a router as middleware to another router. What do you think the effect of the following is?

    let router = Router()
    let subrouter = Router()
    
    subrouter.get("/apple") { request, response, next in
        response.send("Hello world!")
        next()
    }
    
    router.get("/banana", middleware: subrouter)
    
    Kitura.addHTTPServer(onPort: 8080, with: router)
    Kitura.run()

The answer is that you’ll see the “Hello World!” message at the `/banana/apple` path. What good is that? For one use case, I again bring up my own Kitura Language Negotiation project. It’s possible to configure KLN so that the language the site should use is defined by a path prefix; for example, the paths `/en/news`, `/es/news` and `/fr/news` can show the news page in English, Spanish, and French, respectively. But developers using my middleware just develop a `/news` route and put it in a router, and KLN simplifies defining the `/en`, `/es`, and `/fr` paths in another router which then uses the developer’s router as a subrouter.

Confused by that? Hm. Okay. Don’t sweat it too much. Let’s move on.
