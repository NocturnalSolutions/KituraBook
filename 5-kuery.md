> TODO
> - Support Postgres once it's available
> - Linux

# Chapter 4: Database connectivity with Kuery

Pretty much any web application with more than a trivial level of complexity will be interfacing with a database. Consider a massive site like Wikipedia or a lowly WordPress blog; both are, when you get down to it, interfaces for a database of articles.

There are various types of databases, but for historical reasons, the type most commonly used by web applications is SQL databases. It is certainly possible to connect to others from within Swift, such as key-value stores like Redis and NoSQL databases like CouchDB, but primarily due to the historical precedent, I will stick with covering SQL database connectivity for this book.

IBM provides a library called Swift Kuery for communicating with SQL databases from within Swift. Kuery is not actually a Kitura dependency, so you can use Kuery from non-Kitura applications; also, there are other ways to connect to various SQL databases than using Kuery. However, since Kuery is part of the Swift@IBM ecosystem along with Kitura, you will typically see the two used together.

## Selecting and installing an SQL database type

Swift Kuery supports two types of SQL databases: MySQL and PostgreSQL. (SQLite was also previously supported, but sadly has been deprecated; this is unfortunate, as SQLite is a great choice for simple projects and prototypes, as well as full production projects in many cases.)

MySQL is historically the most commonly used SQL database for web development, but PostgreSQL has more high-end features of the sort that won’t be covered in this book. Both of these databases work on a client-server model, meaning you must start a server application to host the database (this can be either on the same machine as your web application or a different one), and your web application then acts as a client that connects to the database server via an IP connection (or a Unix socket if you are running both on the same machine). Both of these databases hold the actual data spread across various not-safe-for-humans files in a certain directory on the server’s filesystem.

Both of these options use slightly different dialects of SQL. Fortunately, Kuery has an “abstraction layer” which makes it possible to interact with databases without actually directly writing SQL. That means that almost all of the code in this chapter will work no matter which SQL system you choose to use; only the code which is used to connect to or open the database will change. 

This theoretically means you can go ahead and use whichever of these you feel comfortable with. However, at the time I write this, IBM has not yet updated their PostgreSQL plugin for Kuery for Swift 4. To that end, I will be focusing on MySQL for this chapter; however, understand that 99% of it will be applicable to PostgreSQL as well.

If you haven’t already, go ahead and install and set MySQL (or a compatible fork, like MariaDB or Percona). If you’re on a Mac, you won’t just be able to install a binary application; you’ll need to use a package manager like MacPorts or Homebrew to install it so that the libraries for the servers are installed in a predictable place as well. If you are not familiar with using the database system you chose, now’s the time to learn before you move on to the next paragraph.

## Building projects with Kuery

Start a new project and add Swift-Kuery-PostgreSQL to it via Swift Package Manager. This is going to be the first project in the book which uses code which isn't itself entirely written in Swift, so things are going to get tricky.

### On the Mac

First, if you are on a Mac and prefer to use MacPorts rather than Homebrew, you will need to take a step to help the compiler find your MySQL header files. Create the directory `/opt/local/include` and symlink the `mysql` directory from under `/opt/local/include` under it. The precise path of that directory will depend on which variant of MySQL you installed; for example, I installed version 10 of the MariaDB fork of MySQL, so I had to run `ln -s /opt/local/include/mariadb-10.0/mysql/ /opt/local/include/`.

Don't worry about any other code for now; try to build your project from the CLI with `swift build` as is. (Don't use Xcode for building yet, Mac users.) It will fail with an error which includes something like this:

    ld: library not found for -lmysqlclient for architecture x86_64
    <unknown>:0: error: link command failed with exit code 1 (use -v to see invocation)

Aside from the header files, we also need to tell Kuery where to find the MySQL (in this case) libraries themselves. If you are using Homebrew, this directory will always be `/usr/local/lib`. If you're using MacPorts, the path will again vary depending on which type and version of MySQL you installed; it should be the same path you had to symlink as above, but with `include` swapped for `lib`; so `/opt/local/lib/mariadb-10.0/mysql` in my case. At any rate, now that you have this path, here’s how you pass them to the Swift compiler so your project builds:

    swift build -Xlinker -L[the path found above]

So, for Homebrew users:

    swift build -Xlinker -L/usr/local/lib

And for me, with my `mariadb-10` variant of MySQL:

    swift build -Xlinker -L/opt/local/lib/mariadb-10.0/mysql

What a pain! Fortunately, there’s a couple things you can do to make things easier. First, if you are using Xcode, you can pass those extra flags to `swift package generate-xcodeproj` too, and it will automatically add the magic pixie dust to the generated Xcode project so that it builds just by hitting that “Build” button. (If you generate an Xcode project with the extra flags omitted, your project will fail to build just as it will on the CLI.) So in my case, I do the following:

    swift package generate-xcodeproj -Xlinker -L/opt/local/lib/mariadb-10.0/mysql

Just remember to include those flags when you generate a new Xcode project, for example after adding new packages.

If you still prefer to build from the CLI, you can create a shell script that includes all that junk in it and then just invoke that script instead of `swift build`:

    echo "swift build -Xlinker -L/opt/local/lib/mariadb/mysql" > build.sh
    chmod +x build.sh
    ./build.sh

### On Linux

Congratulations, Linux fans; life is easier for you in this case. Just install the `libmysqlclient-dev` package (you’ll need to install this in addition to the actual MySQL server), and the Swift toolchain will know where to find the libraries. `swift build` is still all you need.

## Importing some data

Now that we can build a project that includes Swift-Kuery-MySQL, start up your MySQL server and connect to it with either the `mysql` command line tool or a graphical database manager of some sort. Take note of whatever credentials and network hostnames and ports and so on you need to use, because we’re going to put them in our code later.

Let’s populate our database with some data we can work with in this and later chapters. For this purpose, we’re going to use the Chinook Database, a database populated with music and movie information originally sourced from an iTunes playlist. Clone the repository at https://github.com/lerocha/chinook-database.git. (Don’t make it a dependency of a Kitura project; just clone the repository by itself.)

The repository contains SQL dumps for various SQL systems in the `ChinookDatabase/DataSources` directory. Create a new database and import the `Chinook_MySql.sql` dump. Once you’ve got all the data imported, feel free to poke around and familiarize yourself with what the schema of the tables look like and what sort of data is in them.

Once you’ve done that, let’s see about connecting to our database from Kuery.

## Back to Kitura (finally!)

Now let’s connect to our MySQL server from our code. We are going to instantiate a `MySQLConnection` object. The `init()` function for this class has a lot of parameters, but they are all optional. Let’s see its signature:

    public required init(host: String? = nil, user: String? = nil, password: String? = nil, database: String? = nil, port: Int? = nil, unixSocket: String? = nil, clientFlag: UInt = 0, characterSet: String? = nil, reconnect: Bool = true) 

But here’s the thing; when instantiating, you should only pass the parameters necessary. In my case, my MySQL server is locally installed, and I want to connect with the standard root user, for whom I have not configured a password (I would never do such a stupid thing on a public server, and neither will you, right?). Also, I imported my data into a database called `Chinook`. So my instantiation looks like this:

    let cxn = MySQLConnection(user: "root", database: "Chinook")

Now perhaps you’ve created a new user to connect to the database, and you’re hosting your MySQL instance on the non-standard port 63306 locally. Your instantiation might look like this:

    let cxn = MySQLConnection(user: "chinookuser", password: "swordfish", database: "Chinook", port: 63306)

You get the idea. At any rate, in the following code, don’t forget to swap out my instantiation code with what is necessary for your server.

Now go back to your project, delete what’s in `main.swift`, and add the following. (Note we’re not instantiating an instance of `Kitura` yet.)

    import SwiftKuery
    import SwiftKueryMySQL
    import Foundation
    
    // Don't forget to change this!
    let cxn = MySQLConnection(user: "root", database: "Chinook")
    
    cxn.connect() { error in
        if error != nil {
            print("Error connecting to database.")
            exit(1)
        }
        else {
            print("Success!")
        }
    }

Did you see the “Success!” message? If not, tweak your `MySQLConnection()` call until your parameters are right - we’re not going to have much fun moving forward if things aren’t working so far.

Okay, now let’s try doing some more interesting things. We’ll make a page which lists every album in the database. Put this in your `main.swift`.

    import SwiftKuery
    import SwiftKueryMySQL
    import Kitura
    import Foundation
    
    // Don't forget to change this!
    let cxn = MySQLConnection(user: "root", database: "Chinook")
    
    cxn.connect() { error in
        if error != nil {
            print("Error connecting to database.")
            exit(1)
        }
    }
    
    let router = Router()
    router.get("/albums") { request, response, next in
        cxn.execute("SELECT Title FROM Album ORDER BY Title ASC") { queryResult in
            if let rows = queryResult.asRows {
                for row in rows {
                    let title = row["Title"] as! String
                    response.send(title + "\n")
                }
            }
        }
    }
    
    Kitura.addHTTPServer(onPort: 8080, with: router)
    Kitura.run()

Now build your project and watch what happens when you visit the “/albums” path.

    > curl localhost:8080/albums 
    ...And Justice For All
    20th Century Masters - The Millennium Collection: The Best of Scorpions
    A Copland Celebration, Vol. I
    A Matter of Life and Death
    A Real Dead One
    A Real Live One
    [continued…]

So you can probably see what happened here, but just in case, let’s go over that router handler bit by bit.

        cxn.execute("SELECT Title FROM Album ORDER BY Title ASC") { queryResult in

The `execute()` method here takes a string containing an SQL query and an escaping closure that is executed after the query is made. The closure is passed a `QueryResult` enum which we name `queryResult`.

            if let rows = queryResult.asRows {

`asRows` is a computed parameter on `QueryResult` objects which returns the results of a select query as an array of `[String: Any?]` dictionaries where the keys are the selected field names. Most of the examples in this book will use this parameter, but there are others; `asError` is one you’re probably going to want to get familiar with if your queries don’t seem to be working.

                for row in rows {
                    let title = row["Title"] as! String
                    response.send(title + "\n")
                }
            }
        }
    }

The rest of this should be self-explanatory at this point.

## Abstracting SQL queries

Now if you’re familiar with other database libraries in various other frameworks and languages, you may have bristled when you saw above that we used an actual SQL query string to make our query. Isn’t there a better way than basically embedding ugly SQL (which is itself its own programming language, in a way) into our beautiful Swift projects? Yes, there is! We’ll learn how to use it next.

(Now, on the other hand, I’m sure there are people who are highly familiar with SQL and would rather just stick to SQL query strings rather than abstracting things away under Swift code. I don’t think this mindset is necessarily wrong, so if you’d prefer to just use Kuery this way, more power to you. This book will use the abstracts, however.)

The first thing we need to do is define the schemas of the tables for Kuery. This is done by subclassing the `Table` class. We add a property named `tableName` which is a string containing the table name. Other properties are instances of the `Column` class corresponding to columns on the table. Note that we only have to define the columns we intend to use, and we don’t have to give any information about the field types of the columns; it’s pretty simple.

To make things neat, I like to keep my schemas in a separate file from the rest of my code. Add a new file to your project called `Schemas.swift`. Add the following.

    import SwiftKuery
    import SwiftKueryMySQL
    
    class Album: Table {
        let tableName = "Album"
        let Title = Column("Title")
    }

It’s that simple. Again, we’re only defining the columns we need to use in our code, and right now, we’re only using Title; as we go on and use other columns, we’ll add them to the schema.

Go back to `main.swift` and modify your router handler code to match the following.

    router.get("/albums") { request, response, next in
        let albumSchema = Album()
        let titleQuery = Select(albumSchema.Title, from: albumSchema)
            .order(by: .ASC(albumSchema.Title))
        cxn.execute(query: titleQuery) { queryResult in
            if let rows = queryResult.asRows {
                for row in rows {
                    let title = row["Title"] as! String
                    response.send(title + "\n")
                }
            }
        }
    }


Build and run your project and access the “/albums” path, and you should see the same result as before.

Can you see what we did here? First, we instantiated our new `Album` class so we could reference tables from it. Then we built a `Select` query. `Select` is a substruct of the `Query` struct, and as you can probably guess, there are `Insert` and `Delete` and `Update` ones too - but in due time. Let’s look at the signature of `Select`’s constructor.

    public init(_ fields: Field..., from table: Table)

If you can’t recall what that ellipsis means, it means we can pass an arbitrary number of `Field` parameters for that first parameter. But the final parameter must be a `Table`.

Now this is pretty much the simplest example of how Kuery’s database API can be used without using direct SQL strings. But wanna know a not-so-surprising secret? Kuery is just taking all this API stuff and making SQL strings out of it anyway. As we continue with more elaborate examples, you may run into times when your queries aren’t working as expected, and in those cases you may find it useful to see what SQL Kuery is compiling for your query. The query instance, like our `Select` in the code above, has a method called `build` with a signature like this:

    public func build(queryBuilder: QueryBuilder) throws -> String

Huh. What’s a `QueryBuilder`? Don’t worry about it too much; just know that we can easily get one by using the `queryBuilder` parameter on our connection object.

Go back to your router handler and try adding the following right before the call to `cxn.execute()`.

    print(try! titleQuery.build(queryBuilder: cxn.queryBuilder))

Now, if you build and run your project, you should see the following appear in the console when a request for the “/albums” path is made.

    SELECT Album.Title FROM Album ORDER BY Album.Title ASC

Yep, that SQL looks about right to me.

## A more complicated but more useful query

Okay, so right now, we have a router handler that returns a list of all albums. That’s a lot of albums. Let’s make things a little more practical by setting up a route where, for example, if the path “albums/t” is requested, we return all albums with titles that start with the letter T. In SQL this is done by using a “LIKE” condition on a “WHERE” clause, such as `“SELECT Title FROM Album WHERE Title LIKE "t%"`. We can do this kind of query with Kuery too by using a `like()` method on the field in the schema of the desired table. (If you’re like me, the code will make more sense than that sentence.)

However, this introduces a complication in that we are going to use an arbitrary string provided by a visitor as part of our SQL query. Just as with any other web-facing database-backed app, we need to be careful of SQL injection issues of the [Bobby Tables](https://www.xkcd.com/327/) variety. (If you are not familiar with the concept of SQL injection, please stop reading this right now and go research it before you build a web application, with Kitura or otherwise.)

Fortunately, Kuery has a pretty simple solution to help us avoid SQL injection. But since we sometimes need to learn how to do something wrong before we learn how to do something right, let’s do it wrong first.

    router.get("/albums/:letter") { request, response, next in
        guard let letter = request.parameters["letter"] else {
            response.status(.notFound)
            return
        }

        let albumSchema = Album()
    
        let titleQuery = Select(albumSchema.Title, from: albumSchema)
            .where(albumSchema.Title.like(letter + "%"))
            .order(by: .ASC(albumSchema.Title))

        cxn.execute(query: titleQuery) { queryResult in
            // As above…
        }
    }

Do you see where we’re taking unsanitized user input and putting it into an SQL query - or, more precisely, some code that will be compiled into an SQL query? Yeah, that’s bad. So how can we avoid that? Well, first, in the query part, we instantiate a `Parameter` instance where the user input needs to go after it’s sanitized; we pass its `init()` method a name for the parameter. Then, in the `execute()` method on the connection object, we pass a new parameter that consists of a `[String: Any?]` dictionary of the unsanitized parameters keyed by the name we gave our parameter. Let’s go to the code.

    router.get("/albums/:letter") { request, response, next in
        guard let letter = request.parameters["letter"] else {
            response.status(.notFound)
            return
        }
    
        let albumSchema = Album()
    
        let titleQuery = Select(albumSchema.Title, from: albumSchema)
            .where(albumSchema.Title.like(Parameter("searchLetter")))
            .order(by: .ASC(albumSchema.Title))
    
        let parameters: [String: Any?] = ["searchLetter": letter + "%"]
    
        cxn.execute(query: titleQuery, parameters: parameters) { queryResult in
            // As above…
        }
    }

There we go. Now Kuery will automatically sanitize the parameter values when the query is built, and Bobby Tables’ mother will have to go have fun elsewhere.

(Dear smart aleck: Yes, we could have also sanitized the user input by using a regular expression in our route path to make sure that the incoming value was a single letter, as in:

    router.get("/albums/:letter([a-z])") { request, response, next in

And certainly, that’s not a bad thing to do *in addition to* the sanitized, parameterized query construction in order to be doubly safe. Your cleverness has been duly noted. However, this chapter is about Kuery, so we’re learning about Kuery today, okay? Okay. Now sit back down.)

*Note: This chapter is not yet incomplete, but since it was taking me weeks and weeks to write, I figured I’d go ahead and finally just publish what I had so far. Please come back again for more.*
