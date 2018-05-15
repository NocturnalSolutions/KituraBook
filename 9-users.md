# Chapter 9: User Sessions and Authentication

HTTP is a stateless protocol. That means that each HTTP transaction is (broadly speaking) made independently of any other transaction; the client (like a web browser) connects to a server and sends data to make a request; the server sends the response data in reply, then disconnects the client. If the client needs another resource from the server, it needs to reconnect to the server all over again. (This is not *entirely* true, but close enough for the purposes of this chapter.) This differs from protocols like IRC, where clients maintain a constant connection to the server as they trade data back and forth.

Now this statelessness works just fine when a server is just dumbly serving static files to people who request them, but sometimes we, as web application developers, want to be able to track a user across requests, so that we can ascertain that a certain request was made by the same client that made a request earlier. For example, if we have a resource we want to customize for and/or restrict to certain users, we may ask them to log in by submitting a username and password, which we can then authenticate - but then we also want them to be able to see these resources on later requests as well without having to log in each time.

In the very early days of the web, HTTP authentication was developed to solve this problem. With HTTP authentication, the server tells a connecting client that a certain resource requires authentication to access; the browser then prompts the user for credentials and sends them in the request headers in the next and subsequent requests to that server. This served the purpose, but wasn’t very flexible; for example, there wasn’t a standard way to “log out” a user by telling their browser to stop sending the credentials. Also, there wasn’t an elegant way to track a user across requests *without* having them do the authentication first, which is sometimes desirable.

To address this, HTTP cookies were developed. A *cookie* is a small bit of text which a server will send to a client and request that the client send the cookie back to the server on all future requests to the server. The cookie data may include instructions on how long the client should hold on and send the cookie data; the server can also tell a client to delete a previous cookie instantly, thus fixing the “log out” issue of HTTP authentication.

Cookies can contain text-encoded data, but more frequently they contain a distinctly unique identifier key. Many web frameworks, including Kitura, can use these keys to store and restore *sessions,* which are basically collections of data relevant to the user that sent the key.

## Kitura-Session

Let’s see this working in practice with [Kitura-Session](https://github.com/IBM-Swift/Kitura-Session). Start a new project called SessionTest and use SPM to require Kitura and Kitura-Session.

To get sessions working in Kitura, we instantiate the Session middleware and add it to middleware to the routes we want to use it on; in the example below, I’m just going ahead and adding it to all routes, but you can be more particular and add it to only routes on which it will be used if you prefer. When we instantiate Session, we pass it a `secret` parameter which is a string used when generating the identifier in the cookie; to avoid cases where one user is able to guess another user’s cookie value, this should be a secret non-public string, and you should use a different one for each of your sites. Once the middleware is in place, incoming RouterRequest objects will have an optional `session` parameter which functions as a `[String: Any]` dictionary (it isn’t really, but it subscripts like one) into which we can stuff the data we want to persist across sessions.

Here’s some code to dump into your main.swift and play with.

```swift
import Foundation
import Kitura
import KituraSession

// Instantiate a Session.
// Note: Use a unique "secret" value on each of your projects/servers.
let session = Session(secret: "I love Kitura!")

// Instantiate a Router and add our Session middleware for all requests.
let router = Router()
router.all(middleware: session)

// Add the BodyParser middleware for all POST requests.
router.post(middleware: BodyParser())


router.get("/") { request, response, next in
    // Can we find a "name" value in the existing session data?
    // Remember that `request.session` is effectively a [String: Any]
    // dictionary, so we need to cast the "name" value to a String.
    if let name = request.session?["name"] as? String {
        // Name found, so let's say hello.
        let hello = """
<!DOCTYPE html>
<html>
    <body>
        <h1>Hello, \(name)!</h1>
    </body>
</html>
"""
        response.send(hello)
    }
    else {
        // Name not found, so prompt the user for their name.
        let logInForm = """
<!DOCTYPE html>
<html>
    <body>
        <p>What is your name?</p>
        <form method="post" action="/submit">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
"""
        response.send(logInForm)
    }
    next()
}

router.post("/submit") { request, response, next in
    // Extract the name from the submitted data.
    guard let body = request.body?.asURLEncoded, let name = body["name"] else {
        try response.status(.unprocessableEntity).end()
        return
    }
    // Save the name in the session data.
    request.session?["name"] = name
    // Redirect the user back to the front page.
    try response.redirect("/")
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
```

Fire up your favorite web browser and head to `http://localhost:8080/`. You’ll be prompted with a page asking your name. After submitting the form, you’ll be taken back to the `/` path, except instead of seeing the form you just submitted, you’ll be greeted by name - but note that the browser isn’t sending your name to the server in any way. That data was stored server-side in the session data.

What you probably didn’t notice is that, when Kitura sent the response for the `/submit` path, it sent a response header to your browser telling it to store a cookie. When the browser then requested the `/` path immediately after, it sent that cookie in its request. When Kitura-Session saw that cookie, it was able to restore the session data into `request.session`.

Now try reloading the browser page while it’s on the `/` path. The browser will once again send the cookie it has stored as part of the request, and Kitura-Session will again use it to restore the session, so you’ll once again see the “Hello” message rather than the name prompt form. But if you open up a separate web browser program (or, if you don’t have one, a new window using the private mode of your current browser) and request the `/` path, you’ll be prompted for your name again - cookies aren’t shared across browsers, so the server can’t use it to determine who you are.

So now you’re “logged in” in your main browser and will see the “Hello” message when you visit the `/` path. But what if you want to be anonymous again? We can destroy the session, which causes all the data saved for the session to be deleted and to not be recreated on future requests from the browser, even if the browser continues to send the cookie it has stored. To do this, we call the `destroy` method on `request.session`. This method takes a callback to handle a case where an error occurs during session destruction, though this is incredibly unlikely. Go back to your code editor and add the following.

```swift
router.get("/log-out") { request, response, next in
    // Destroy the session and redirect the user back to the front page
    request.session?.destroy { error in
        if let error = error {
            print("Session destruction failed: \(error.localizedDescription)")
        }
    }
    try response.redirect("/")
    next()
}
```
Then go back and add a link to our new route in the HTML sent in the `/` handler.

```swift
router.get("/") { request, response, next in
    // ...
        let hello = """
<!DOCTYPE html>
<html>
    <body>
        <h1>Hello, \(name)!</h1>
        <p><a href="/log-out">Log out</a></p>
    </body>
</html>
"""
        response.send(hello)
        // ...
```

Now restart your application and try things again in your browser. When you go to the `/` path, you’ll be prompted for your name. After entering it, you’ll see the “Hello” message, but now you’ll also see the “Log out” link. After clicking that, you’ll again be redirected to the front page, but this time you’ll be prompted for your name again.

### More on Cookies

The HTTP cookie specification is a broadly-supported specification with lots of ins and outs, of which I won’t be covering in depth here. But if you’re unfamiliar with them, you may want to read up on them for future knowledge. The [HTTP cookie Wikipedia article](https://en.wikipedia.org/wiki/HTTP_cookie) isn’t a bad place to start.

You can watch how cookies are sent back and forth using Curl. Use the `-c` flag to specify a “cookie jar” file to which cookie data sent from a server is stored; you can then use a `-b` flag to specify the same file, and data from that file will be used to determine what cookies to send to a server. You can, as we’ve done before, use the `-i` flag to show response headers from the server, but there’s no equivalent to show the request headers that Curl builds when it makes requests; instead, you’ll have to use the `-v` flag, which kicks off verbose mode and will show you both request and response headers as well as other data. As we have before, you can use the `-d` flag to specify data sent in the body of a POST request, and, finally, we can use the `-L` flag to have Curl automatically follow redirect headers sent from the server. Here’s an example of all that stuff in action; note the `Set-Cookie` headers sent from the server, and the `Cookie` headers sent by Curl in subsequent requests. In short, try the following lines in your terminal and see what the result looks like (I decided to forego pasting my own results for example’s sake as they are quite verbose).

```shell
$ curl -b /tmp/cookies.txt -c /tmp/cookies.txt -v http://localhost:8080/

$ curl -b /tmp/cookies.txt -c /tmp/cookies.txt -d "name=foobar" -L -v http://localhost:8080/submit
```

### Kitura-Session Internals

So you see above how session data is stored by Kitura-Session between page requests. How exactly is this data stored? By default, it’s just stored in memory like any other variable in your program. This is quite fast, but there are a couple issues with this. For one, if you have a lot of sessions created for your users (lots of users “logged in”) and/or a lot of data stored in your sessions, the memory usage of your program can quickly balloon out of control. Secondly, if your web app stops or crashes, all of that session data is lost with it and all of your users will have to log in again.

To alleviate these issues, it’s possible to have Kitura-Session use an external storage system for session data. As I write this, there are currently integration plugins for Kuery (which in turn lets you use any database Kuery supports as a back-end) and the Redis No-SQL database system. Check out the [“Plugins” section in the Kitura-Session documentation](https://github.com/IBM-Swift/Kitura-Session#plugins) for links to these plugins. For simplicity, sake, I won’t be using one of them in the examples in this chapter, but you should definitely use one if you’re going to be writing a real web app.

Now while using one of these plugins will more permanently store the data you store in a session, it should be noted that it’s a best practice to not use a session’s data storage as a primary data storage location anyway. For example, after a user logs in to your site, you may load their name and email address from your site’s database and store it in a session for easy retrieval, but if they later change their name or email address, you should update *the database* with that new information and not only the session. After all, remember that that session will be destroyed when the user logs out - and all of the data stored in it will go with it.

## Kitura-Credentials and Authentication

So by now you should have an idea of how you can use sessions to track a logged-in user between requests, and how they can log out. But what’s a good way to handle logging them in in the first place?

Well, please try to contain your shock as I tell you that the Kitura project has a solution for that in the form of a middleware package called [Kitura-Credentials](https://github.com/IBM-Swift/Kitura-Credentials) which provides a framework by which various plugins can implement various ways to authenticate users. There are plugins for allowing users to log in via their Facebook and GitHub accounts, among others, as well as plugins that handle authentication via local databases of usernames and passwords; you’ll find a list of existing plugins on the Kitura-Credentials repo page. It’s possible to use more than one plugin on your site; so, for example, you can allow users to log in to your site with their Facebook account, or to create a new account on your site and then log in with the username and password they used when creating an account. This sort of thing is generally a good idea because, despite what it may seem or what Mr. Zuckerburg would like, not *everyone* on the internet has a Facebook account, and those that do may not wish to grant your web site access to it.

Originally I was planning to give a walkthrough of implementing Kitura-Credentials here, but since the method of implementing each method of authentication on your site can be quite different, there’s a good chance that any code I give you will be useless at best and confusion-inducing at worst. So instead I will speak of how Credentials works in general and then ask you to have a look at the instructions in the Git repos for the specific implementations you are interested in.

Implementing Kitura-Credentials should be quite familiar at this point. You instantiate `Credentials`; you instantiate the Credentials plugin; you register the latter as a plugin to the former; then you add the `Credentials` instance as middleware to the relevant paths.

Kitura-Credentials provides the `UserProfile` class. This is a class which contains many properties for a user’s display name, real name, email address, profile photos, and other arbitrary data. Kitura-Credentials plugins will instantiate one of these classes and pass it to your application when a user successfully authenticates, though of course not all of these properties will be populated in all cases. It will also handle storing the instance into the session storage and restoring it on future page loads from that user; you’ll find it in the `userProfile` property of the `RouterRequest` object that your route handlers will receive.

Using Kitura-Credentials may or may not actually be the best way to authenticate users for your site, given its circumstances. As with Kitura’s other pluggable middleware, you can write your own Kitura-Credentials plugin if the existing ones don’t match your needs - but you can use what you learned above with Kitura-Session to bypass it entirely. This may be desirable if you don’t want to be forced to use the (needlessly comprehensive, in my opinion) `UserProfile` class. Just remember that, if you’re storing user passwords locally, you need to [securely hash those passwords](https://crackstation.net/hashing-security.htm)!
