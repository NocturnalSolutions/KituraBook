# Chapter 5: Database connectivity with Kuery

Pretty much any web application with more than a trivial level of complexity will be interfacing with a database. Consider a massive site like Wikipedia or a lowly WordPress blog; both are, when you get down to it, interfaces for a database of articles.

There are various types of databases, but for historical reasons, the type most commonly used by web applications is SQL databases. It is certainly possible to connect to others from within Swift, such as key-value stores like Redis and NoSQL databases like CouchDB, but primarily due to the historical precedent (as well as my own familiarity), I will stick with covering SQL database connectivity for this book.

IBM provides a library called Swift Kuery for communicating with SQL databases from within Swift. Kuery is not actually a Kitura dependency, so you can use Kuery from non-Kitura applications; also, there are other ways to connect to various SQL databases than using Kuery. However, since Kuery is part of the Swift@IBM ecosystem along with Kitura, you will typically see the two used together.

## Selecting and installing an SQL database type

Officially, Swift Kuery supports two types of SQL databases: MySQL and PostgreSQL. SQLite used to be officially supported, but when Swift 4 was released, IBM deprecated its Kuery integration library for SQLite. I felt this unfortunate, as SQLite is a great choice for simple projects and prototypes, as well as full production projects in many cases; thus, I personally forked IBM’s Git repository and updated it for Swift 4.

MySQL is historically the most commonly used SQL database for web development, but PostgreSQL has more high-end features and thus is slightly more common in high-demand environments. Both of these databases work on a client-server model, meaning you must start a server application to host the database (this can be either on the same machine as your web application or a different one), and your web application then acts as a client that connects to the database server via an IP connection (or a Unix socket if you are running both on the same machine). Both of these databases hold the actual data spread across various not-safe-for-humans files in a certain directory on the server’s filesystem. SQLite does not use a client-server model; instead of connecting to a server to use SQLite, you just give your code a path to a database file that SQLite reads from and writes to locally. This single file that SQLite uses makes it much easier to back up or copy the database than with client-server database systems; just copy that single file as you would any other file, and things will work just fine. Copying the files behind a MySQL or PostgreSQL database to a different location might not work as expected; you instead have to create a “dump” file which serializes the binary data in the database to a plain text list of operations.

Given that SQLite is substantially simpler to install and use for the reasons above, I will be using SQLite in this chapter. (Previous versions of this chapter used MySQL, before I decided to update Kuery’s SQLite support myself as described above; rather than destroy that information, I’ve moved it into [one of the appendices](appendices/c-mysql.md) for you to peruse if you prefer. However, if you have little to no previous experience with using databases in web development, I suggest you stick to using SQLite as outlined below.)

MySQL, PostgreSQL, and SQLite use slightly different dialects of SQL. (It wouldn’t be a standard if there weren’t differing implementations of it!) Fortunately, Kuery has an “abstraction layer” which makes it possible to interact with databases without actually directly writing SQL. That means that almost all of the code in this chapter will work no matter which SQL system you choose to use; only the code which is used to connect to or open the database will change. So if you start a project using SQLite and then later decide you want to switch to MySQL or PostgreSQL, in theory you’ll only have to change the parts of the code that initialize the connection to the database.

## Building projects with Kuery

Start a new project and add the Swift-Kuery-SQLite package to it via Swift Package Manager. Note that we will be using my forked and updated repository at https://github.com/NocturnalSolutions/Swift-Kuery-SQLite.git instead of the one from IBM. 

This is going to be the first project in the book which uses code which isn't itself entirely written in Swift, so things are going to be a little bit tricky - you’re going to need to install some additional libraries on your system so that your code can communicate with SQLite databases.

### On the Mac

On the Mac, your approach will depend on which package manager you decide to use.

If you’re using Homebrew, the package you’ll want to install is `sqlite`.

    brew install sqlite

On MacPorts, you’ll want to install the `sqlite3` port. Additionally, you’ll need to symlink some things into the places that Homebrew would put them, since Swift Kuery SQLite was written expecting you to have used Homebrew. The three commands below should do it.

    sudo port install sqlite3
    mkdir -p /usr/local/opt/sqlite/include
    ln -s /opt/local/include/sqlite3.h /usr/local/opt/sqlite/include/

(If you get permissions errors running any of the above commands, remember you probably need to prefix them with `sudo`.)

### On Linux

Assuming you’re on some variant of Ubuntu Linux (other versions of Linux are not officially supported by Apple as of this writing), you’ll want to install the `sqlite3` and `libsqlite3-dev` packages.

    apt-get install sqlite3 libsqlite3-dev

## Importing some data

Let’s get a database with some data we can work with in this and later chapters. For this purpose, we’re going to use the Chinook Database, a database populated with music and movie information originally sourced from an iTunes playlist. Clone the repository at https://github.com/lerocha/chinook-database.git. (Don’t make it a dependency of a Kitura project; just clone the repository by itself.)

The repository contains SQL dumps for various SQL systems in the `ChinookDatabase/DataSources` directory. Find the `Chinook_Sqlite.sqlite` file and copy it to a useful location. (We don’t want to use the `Chinook_Sqlite.sql` file; make sure you copy the one with an extension of `.sqlite`.) For the purposes of simplicity, I’m going to just copy it to my home folder, so the path I will use in the code samples below is `~/Chinook_Sqlite.sqlite`, but you can put it anywhere else you’d like.

## Back to Kitura (finally!)

Now let’s access that database file from our code. We are going to instantiate a `SQLiteConnection` object. Its simplest `init()` function takes a `filename` parameter which is a string to the file path where our database file resides. Here’s what it looks like on my end.

    import Foundation
    import Kitura
    import SwiftKuery
    import SwiftKuerySQLite
    
    // Using NSString below is gross, but it lets us use the very handy
    // expandingTildeInPath property. Unfortunately no equivalent exists in the
    // Swift standard library or elsewhere in Foundation.
    // Don't forget to change this path to where you copied the file on your system!
    let path = NSString(string: "~/Chinook_Sqlite.sqlite").expandingTildeInPath
    
    let cxn = SQLiteConnection(filename: String(path))
    
    cxn.connect() { error in
        if error == nil {
            print("Success opening database.")
        }
        else if let error = error {
            print("Error opening database: \(error.description)")
        }
    }

Adapt the above and build and run on your system. Did you see the success message? If not, confirm that the path to the database file is correct and that your user has read and write permissions to it and so on. You’re not going to be able to get much done until you get this part working, so don’t continue until you no longer get an error.

## Selecting data

Okay, now let’s try doing some more interesting things. We’ll make a page which lists every album in the database. Put this in your `main.swift`, right underneath the connection testing code.

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
        next()
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
        next()
    }

The rest of this should be self-explanatory at this point.

## Abstracting SQL queries

Now if you’re familiar with other database libraries in various other frameworks and languages, you may have bristled when you saw above that we used an actual SQL query string to make our query. Isn’t there a better way than basically embedding ugly SQL (which is itself its own programming language, in a way) into our beautiful Swift projects? Yes, there is! We’ll learn how to use it next.

(Now, on the other hand, I’m sure there are people who are highly familiar with SQL and would rather just stick to SQL query strings rather than abstracting things away under Swift code. I don’t think this mindset is necessarily wrong, so if you’d prefer to just use Kuery this way, more power to you. This book will use the abstractions, however.)

The first thing we need to do is define the schemas of the tables for Kuery. This is done by subclassing the `Table` class. We add a property named `tableName` which is a string containing the table name. Other properties are instances of the `Column` class corresponding to columns on the table. Note that we only have to define the columns we intend to use, and we don’t have to give any information about the field types of the columns; it’s pretty simple.

To make things neat, I like to keep my schemas in a separate file from the rest of my code. Add a new file to your project called `Schemas.swift`. Add the following.

    import SwiftKuery
    import SwiftKuerySQLite
    
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
        next()
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

However, this introduces a complication in that we are going to use an arbitrary string provided by a visitor as part of our SQL query. Just as with any other web-facing database-backed app, we need to be careful of SQL injection issues of the [Bobby Tables](https://www.xkcd.com/327/) variety. (If you are not familiar with the concept of SQL injection, please stop reading this right now and go research it before you ever build a database-powered web application, with Kitura or otherwise.)

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
            if let rows = queryResult.asRows {
                for row in rows {
                    let title = row["Title"] as! String
                    response.send(title + "\n")
                }
            }
        }
        next()
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
            if let rows = queryResult.asRows {
                for row in rows {
                    let title = row["Title"] as! String
                    response.send(title + "\n")
                }
            }
        }
        next()
    }

There we go. Now Kuery will automatically sanitize the parameter values when the query is built, and Bobby Tables’ mother will have to go have fun elsewhere.

(Dear smart aleck: Yes, we could have also sanitized the user input by using a regular expression in our route path to make sure that the incoming value was a single letter, as in:

    router.get("/albums/:letter([a-z])") { request, response, next in

And certainly, that’s not a bad thing to do *in addition to* the sanitized, parameterized query construction in order to be doubly safe. Your cleverness has been duly noted. However, this chapter is about Kuery, so we’re learning about Kuery today, okay? Okay. Now sit back down.)

## Complicating things further with a join

Let’s do something a little tricker. Let’s make a route which returns a list of songs (tracks) for a given letter, but along with the track name, we want to include the corresponding artist (composer) and album names for each track. This is a little trickier than our earlier example because while the track and artist names are in the respective `Name` and `Composer` fields in the `track` table, the album name is in the `Title` field in the `album` table. However, there is an `AlbumId` field in the `track` table with a numeric ID which corresponds to an `AlbumId` field in the `album` table. We need to do a *join* to associate information in the `track` table with corresponding information in the `album` table in order to get all the information we need in a single query.

What would that query look like if we wrote it in SQL? Here’s what I came up with to find all songs with titles that begin with the letter “N”.

    SELECT track.Name, track.Composer, album.Title FROM track
    INNER JOIN album ON track.AlbumID = album.AlbumID
    WHERE track.Name LIKE "k%"
    ORDER BY track.name ASC

Go ahead and give that query a try and check out the result.

So how would we replicate that in Kuery? Well, first note how we’re using other fields besides the `Title` field on the `album` table. In order to use those with Kuery, we need to update our schema definition for the `album` table, and we’ll go ahead and define a schema for the `track` table while we’re at it. Go back to `Schemas.swift` and update it to match the below.

    import SwiftKuery
    import SwiftKuerySQLite
    
    class Album: Table {
        let tableName = "Album"
        let AlbumId = Column("AlbumId")
        let Title = Column("Title")
    }
    
    class Track: Table {
        let tableName = "Track"
        let Name = Column("Name")
        let AlbumId = Column("AlbumId")
        let Composer = Column("Composer")
    }

Okay, now let’s define our route and make our query. A lot of this should look familiar at this point. The big change is that we’re using the the `.join()` method to define our inner join, passing it the schema of the table we wish to join to (`album` in this case), and we follow that with an `.on()` method where we define how the join should be done. (Yes, SQL nerds, Kitura also has `.leftJoin()` and `.naturalJoin()` and others, but we’ll just be using`.join` (inner join) for now.) Also, for many tracks, the `Composer` value is actually null; in this case, we want to use a string of “(composer unknown)” when we get a null value in that field. In the code below we’ll use the nil-coalescing operator, `??`, to do this; it basically says “if the value to the left of the `??` is nil, use the value to the right of it instead.“ See the “Nil-Coalescing Operator” section of the “Basic Operators” chapter of *The Swift Programming Language* for more information.

    router.get("/songs/:letter([a-z])") { request, response, next in
        let letter = request.parameters["letter"]!
    
        let albumSchema = Album()
        let trackSchema = Track()
    
        let query = Select(trackSchema.Name, trackSchema.Composer, albumSchema.Title, from: trackSchema)
            .join(albumSchema).on(trackSchema.AlbumId == albumSchema.AlbumId)
            .where(trackSchema.Name.like(letter + "%"))
            .order(by: .ASC(trackSchema.Name))
    
        cxn.execute(query: query) { queryResult in
            if let rows = queryResult.asRows {
                for row in rows {
                    let trackName = row["Name"] as! String
                    let composer = row["Composer"] as! String? ?? "(composer unknown)"
                    let albumName = row["Title"] as! String
                    response.send("\(trackName) by \(composer) from \(albumName)\n")
                }
            }
        }
        next()
    }

Let’s test.

    > curl localhost:8080/songs/k
    Karelia Suite, Op.11: 2. Ballade (Tempo Di Menuetto) by Jean Sibelius from Sibelius: Finlandia
    Kashmir by John Bonham from Physical Graffiti [Disc 1]
    Kayleigh by Kelly, Mosley, Rothery, Trewaves from Misplaced Childhood
    Keep It To Myself (Aka Keep It To Yourself) by Sonny Boy Williamson [I] from The Best Of Buddy Guy - The Millenium Collection
    [continued…]

Oh, that’s nice.

But wait a minute. Something about that code looks really, really strange.

            .join(albumSchema).on(trackSchema.AlbumId == albumSchema.AlbumId)

Why does that work? Why is the code behind `on()` able to see the components of what we’re passing it and not just receiving whatever `trackSchema.AlbumId == albumSchema.AlbumId` evaluates to?

The answer is… well, I have no idea. Even digging into the code, I’m stumped. I guess it has something to do with overloading of the == operator, maybe? But I intend to come back and update this part of the book once I figure it out and/or someone is able to explain it to me.

(Hey, I never said I was some god-tier Swift ninja rockstar Chuck Norris or anything.)

## We’re just getting started, baby.

This chapter was quite lengthy, but it really only scratches the surface of what Kuery is capable of. We didn’t even bother trying to insert or update data in this chapter, and of course Kuery is capable of doing that as well. For more examples of what you can do with Kuery and how to do it, check out the front page of the [Kuery GitHub repository](https://github.com/IBM-Swift/Swift-Kuery).

Don’t delete the Kuery project you worked with in this chapter just yet; we’re going to work with it more in the next one.
