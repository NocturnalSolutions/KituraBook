# Appendix: Using MySQL with Kuery {#mysql-kuery}

> Note: This chapter covers the 2.x release of Kuery. The current 3.x release of Kuery greatly changes the Kuery API, and thus the code featured in this chapter will no longer work. A second edition of Kitura Until Dawn which will cover Kuery 3.x is under way. Please keep an eye on [the web site](https://learnkitura.com/) or [the GitHub repository](https://github.com/NocturnalSolutions/KituraBook) for more information when available.

What follows was originally part of the [standard Kuery chapter](5-kuery.md) of the book before I decided to rewrite it to use SQLite instead of MySQL, as the former is much simpler than the latter. It covers getting Kuery and MySQL to talk to each other. I include it for the benefit of those already familiar with MySQL who would prefer to continue using it rather than using SQLite. If that doesn’t sound like you, I strongly suggest sticking with using SQLite as outlined in the original chapter, as it's generally much simpler to work with.

## Building Projects with Kuery

Start a new project and add SwiftKueryMySQL to it via Swift Package Manager. This is going to be the first project in the book which uses code which isn't itself entirely written in Swift, so things are going to get tricky.

### On macOS

First, if you are on a Mac and prefer to use MacPorts rather than Homebrew, you will need to take a step to help the compiler find your MySQL header files. Create the directory `/opt/local/include` and symlink the `mysql` directory from under `/opt/local/include` under it. The precise path of that directory will depend on which variant of MySQL you installed; for example, I installed version 10 of the MariaDB fork of MySQL, so I had to run `ln -s /opt/local/include/mariadb-10.0/mysql/ /opt/local/include/`.

Don't worry about any other code for now; try to build your project from the CLI with `swift build` as is. (Don't use Xcode for building yet, Mac users.) It will fail with an error which includes something like this:

```shell
ld: library not found for -lmysqlclient for architecture x86_64
<unknown>:0: error: link command failed with exit code 1 (use -v to see invocation)
```

Aside from the header files, we also need to tell Kuery where to find the MySQL libraries themselves. If you are using Homebrew, this directory will always be `/usr/local/lib`. If you're using MacPorts, the path will again vary depending on which type and version of MySQL you installed; it should be the same path you had to symlink as above, but with `include` swapped for `lib`; so `/opt/local/lib/mariadb-10.0/mysql` in my case. At any rate, now that you have this path, here’s how you pass them to the Swift compiler so your project builds:

```shell
swift build -Xlinker -L[the path found above]
```

So, for Homebrew users:

```shell
swift build -Xlinker -L/usr/local/lib
```

And for me, with my `mariadb-10` variant of MySQL:

```shell
swift build -Xlinker -L/opt/local/lib/mariadb-10.0/mysql
```

What a pain! Fortunately, there’s a couple things you can do to make things easier. First, if you are using Xcode, you can pass those extra flags to `swift package generate-xcodeproj` too, and it will automatically add the magic pixie dust to the generated Xcode project so that it builds just by hitting that “Build” button. (If you generate an Xcode project with the extra flags omitted, your project will fail to build just as it will on the CLI.) So in my case, I do the following:

```shell
swift package generate-xcodeproj -Xlinker -L/opt/local/lib/mariadb-10.0/mysql
```

Just remember to include those flags when you generate a new Xcode project, for example after adding new packages.

If you still prefer to build from the CLI, you can create a shell script that includes all that junk in it and then just invoke that script instead of `swift build`:

```shell
echo "swift build -Xlinker -L/opt/local/lib/mariadb-10/mysql" > build.sh
chmod +x build.sh
./build.sh
```

### On Linux

Congratulations, Linux fans; life is easier for you in this case. Just install the `libmysqlclient-dev` package (you’ll need to install this in addition to the actual MySQL server), and the Swift toolchain will know where to find the libraries. `swift build` is still all you need.

## Importing Data

Now that we can build a project that includes Swift-Kuery-MySQL, start up your MySQL server and connect to it with either the `mysql` command line tool or a graphical database manager of some sort. Take note of whatever credentials and network hostnames and ports and so on you need to use, because we’re going to put them in our code later.

Let’s populate our database with some data we can work with in this and later chapters. For this purpose, we’re going to use the [Chinook Database](https://github.com/lerocha/chinook-database), a database populated with music and movie information originally sourced from an iTunes playlist. Clone the repository to your development machine. (Don’t make it a dependency of a Kitura project; just clone the repository by itself.)

The repository contains SQL dumps for various SQL systems in the `ChinookDatabase/DataSources` directory. Create a new database and import the `Chinook_MySql.sql` dump. Once you’ve got all the data imported, feel free to poke around and familiarize yourself with what the schema of the tables look like and what sort of data is in them.

Once you’ve done that, let’s see about connecting to our database from Kuery.

## Back to Kitura (Finally!)

Now let’s connect to our MySQL server from our code. We are going to instantiate a `MySQLConnection` object. The `init()` function for this class has a lot of parameters, but they are all optional. Let’s see its signature:

```swift
public required init(host: String? = nil, user: String? = nil, password: String? = nil, database: String? = nil, port: Int? = nil, unixSocket: String? = nil, clientFlag: UInt = 0, characterSet: String? = nil, reconnect: Bool = true)
```

But here’s the thing; when instantiating, you should only pass the parameters necessary. In my case, my MySQL server is locally installed, and I want to connect with the standard root user, for whom I have not configured a password (I would never do such a stupid thing on a public server, and neither will you, right?). Also, I imported my data into a database called `Chinook`. So my instantiation looks like this:

```swift
let cxn = MySQLConnection(user: "root", database: "Chinook")
```

Now perhaps you’ve created a new user to connect to the database, and you’re hosting your MySQL instance on the non-standard port 63306 locally. Your instantiation might look like this:

```swift
let cxn = MySQLConnection(user: "chinookuser", password: "swordfish", database: "Chinook", port: 63306)
```

You get the idea. At any rate, in the following code, don’t forget to swap out my instantiation code with what is necessary for your server.

Now go back to your project, delete what’s in `main.swift`, and add the following. (Note we’re not instantiating an instance of `Kitura` yet.)

```swift
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
```

Did you see the “Success!” message? If not, tweak your `MySQLConnection()` call until your parameters are right - we’re not going to have much fun moving forward if things aren’t working so far.

## There you are

Okay, that’s it for the MySQL stuff. Go ahead and go back to the original chapter and start from the “Selecting data” section; the rest of the code should work just fine for you, so long as you remember to substitute `import SwiftKueryMySQL` for `import SwiftKuerySQLite` and `MySQLConnection()` for `SQLiteConnection()`.
