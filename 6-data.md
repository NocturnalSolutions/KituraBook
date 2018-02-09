# Chapter 6: Publishing Data with JSON and XML

For the most part, our examples so far in this book have just been outputting plain text; printing unformatted data out to the client basically just so we can see that our code has been working correctly. In reality, very few web applications output plain text; they usually output either web pages to be viewed by humans, or structured data to be consumed by other applications. The web pages part will come next chapter; since it’s somewhat simpler to do and will tie in well with the database connectivity stuff we learned about in the last chapter, we’re going to cover the structured data part first.

What is structured data? It is data formatted in a predictable way. Consider the output of our track list route handler from the previous chapter.

    Karelia Suite, Op.11: 2. Ballade (Tempo Di Menuetto) by Jean Sibelius from Sibelius: Finlandia
    Kashmir by John Bonham from Physical Graffiti [Disc 1]
    Kayleigh by Kelly, Mosley, Rothery, Trewaves from Misplaced Childhood
    Keep It To Myself (Aka Keep It To Yourself) by Sonny Boy Williamson [I] from The Best Of Buddy Guy - The Millenium Collection

Now strictly speaking, this data *does* have a structure:

    [song name] by [composer] from [album title]

But nonetheless, it’s structured as an English sentence and not really intended to be easily “read” by a computer. For example, let’s say you wanted to write a smartphone app that would display your current music collection, and it got its data by requesting it from your Kitura-powered web site. If your data was formatted as above, you would have to write a custom parser in your smartphone app that would analyze each line returned by your Kitura app to determine the song name, composer, and album title for each line. “Oh, that’s easy!“ you might say. “I just split the line on the words ‘by’ and ‘from,’ and I know the first part will be the song name, the second will be the composer, and the third will be the album title!“ Okay, smarty pants; what do you do if you have a song named “Trial by Fire” on an album named “Miles from Milwaukee?“

    Trial by Fire by John Doe from Miles from Milwaukee

Now before you go too far down the rabbit hole of how you would then tweak your algorithm to work with a case like that… let’s just use structured data instead. That will let us send the data from our Kitura site to our smartphone app with a predictable structure that the phone app will easily be able to parse.

When it comes to structured data, there are two formats in common use on the web: JavaScript Object Notation, or JSON, and Extensible Markup Language, or XML. XML is older and far more powerful, but JSON has come into common use recently since it is simpler, yet still good enough for many common cases. We’ll implement both, starting with the simpler JSON. Before starting the respective JSON or XML sections below, I suggest you do a little research on them if you’re not already familiar with them, just so you have a better idea of what you’ll be looking at.

## Headings Up

There’s a common HTTP request header called “Accept” that lists content types that it’s hoping to see in the response. Similarly, there’s a “Content-Type” response header to specify the content type of the response. We’ll use the former to figure out whether our response should be in XML or JSON, and then the latter to clarify that that is the type we are responding with. Should the client request a type in its “Accept” header that we can’t satisfy, we’ll send a “406 Not Acceptable” response code. Finally, our response will also include a “Vary” header that will tell proxy servers and the like that the response clients are going to get from our server will be different depending on the request’s “Accept” header, so they need to take that into consideration when caching. We touched on headers back in chapter 2, but we’re going to do quite a bit more with them here. (All of this is pedantic HTTP protocol stuff that many building testing/demo apps, and often even full production apps, don’t generally worry about, but the idea here is to learn about Kitura functionality in this regard, and if you pick up some good HTTP habits while we’re at it, all the better.)

To start, I want to create a new Track struct for compartmentalizing information on tracks that are plucked from the database. I want to add an initializer to simplify creating a Track from a row we’ve plucked out of the database - which, you may recall, will be a `[String: Any?]` dictionary. Create a `Track.swift` file in your project and add the following.

    import Foundation
    
    struct Track {
        var name: String
        var composer: String?
        var albumTitle: String
    
        init(fromRow row: [String: Any?]) {
            name = row["Name"] as! String
            composer = row["Composer"] as! String?
            albumTitle = row["Title"] as! String
        }
    }

This should look fairly straightforward. One thing to note is that `composer` is an optional string (`String?`) because, as you may recall, some tracks have `NULL` as their composer column in our database.

Okay, now back to our main project file.  Let’s stub out some code first, and then we’ll look through it later. Open back up your Kuery test project and change the route callback for songs to match the below.

    router.get("songs/:letter") { request, response, next in
        let letter = request.parameters["letter"]!
    
        let albumSchema = albumTable()
        let trackSchema = trackTable()
    
        let query = Select(trackSchema.Name, trackSchema.Composer, albumSchema.Title, from: trackSchema)
            .join(albumSchema).on(trackSchema.AlbumId == albumSchema.AlbumId)
            .where(trackSchema.Name.like(letter + "%"))
            .order(by: .ASC(trackSchema.Name))
    
        cxn.execute(query: query) { queryResult in
            if let rows = queryResult.asRows {
                var tracks: [Track] = []
                for row in rows {
                    let track = Track(fromRow: row)
                    tracks.append(track)
                }
    
                response.headers["Vary"] = "Accept"
                let output: String
                switch request.accepts(types: ["text/json", "text/xml"]) {
                case "text/json"?:
                    response.headers["Content-Type"] = "text/json"
                    output = "Not yet implemented. :("
                    response.send(output)
                    break
                case "text/xml"?:
                    response.headers["Content-Type"] = "text/xml"
                    output = "Not yet implemented. :("
                    response.send(output)
                    break
                default:
                    response.status(.notAcceptable)
                    next()
                    return
                }
            }
    
            else if let queryError = queryResult.asError {
                let builtQuery = try! query.build(queryBuilder: cxn.queryBuilder)
                response.status(.internalServerError)
                response.send("Database error: \(queryError.localizedDescription) - Query: \(builtQuery)")
            }
        }
        next()
    }

Okay, let’s look at all the fun stuff we’re doing with headers here.

                response.headers["Vary"] = "Accept"

Here, and on other lines where we use `response.headers`, we are setting a response header. Pretty straightforward.

                switch request.accepts(types: ["text/json", "text/xml"]) {

The `.accepts` methods on the `RouterRequest` object is really handy here. We throw it an array of types that we can support to its `types` parameter, and it will find the best match and return a `String?` with the matched value, or `nil` if no value matched.

What do I mean by a “best match?“ Well, in the “Accept” header (and similar headers, like “Accept-Language”), the client can not only supply a list of types it wants to accept, but a sort of order in which it wants to accept them. For example, what follows is the “Accept” header that Firefox sends when it requests a web page.

    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8

In this header, commas separate the types. So Firefox is asking for four different types:

    text/html
    application/xhtml+xml
    application/xml
    */*

Note that that last type, `*/*`, corresponds to “all other types.” In addition, you notice that Firefox sends a “q value” for the last two types; 0.9 for `application/xml`, and 0.8 for `*/*`. These values specify the desire that Firefox wants to receive those types, and are inferred to be 1.0 when not explicitly stated (as for `text/html` and `appication/xhtml+xml`). So if our server could send a response in both `text/html` and `application/xml`, Firefox would prefer to receive the `text/html` one.

For the purposes of our callback here, which can send responses as both `text/json` and `text/xml`, we may get an Accept header which looks like:

    Accept: text/xml,text/json;q=0.9
    
Which means that the client can accept a response as both the types that we can provide, but it would prefer to receive a `text/xml` one. Fortunately, if we pass such a header to `request.accepts()`, it’s smart enough to take all that stuff into account and send us back the best match.

Okay, let’s move on.

                    response.status(.notAcceptable)
    
                response.status(.internalServerError)

On these lines, we are setting the status code of the HTTP response. There are dozens and dozens of possible status codes, and Kitura has the most common ones defined in its `HTTPStatusCode` enum for more readable code. As mentioned above, we send a “406 Not Acceptable” status when the client asks for a content type we cannot send them. In addition, we now send a “500 Internal Server Error” code if we can’t answer the request because an error occurred when attempting to query the database. (Note that we are also sending information about the query in the body of the HTTP response. This is useful for testing and debugging, but on a live server, sending this information may be a privacy and/or security vulnerability, so don’t do this on live servers!) If we don’t explicitly define a status code, as we haven’t in previous chapters in this book, Kitura automatically sends a “200 OK“ code for us.

Let’s fire up our server and do some testing with Curl.

    > curl localhost:8080/songs/w -i -H "Accept: text/json"
    HTTP/1.1 200 OK
    Date: Thu, 23 Nov 2017 20:54:33 GMT
    Content-Type: text/json
    Content-Length: 24
    Vary: Accept
    Connection: Keep-Alive
    Keep-Alive: timeout=60
    
    Not yet implemented. :(
    > curl localhost:8080/songs/w -i -H "Accept: image/png"
    HTTP/1.1 406 Not Acceptable
    Date: Thu, 23 Nov 2017 20:55:13 GMT
    Content-Length: 0
    Vary: Accept
    Connection: Keep-Alive
    Keep-Alive: timeout=60

    >

Note the “Content-Type” and “Vary” headers, as well as the status codes.

Okay, now that we’re finally done crawling through the HTTP protocol weeds on our belly, let’s send some real responses.

## JSON

Converting data to (and from) JSON in Swift is so blissfully easy. First, I need to briefly introduce a protocol in Foundation called `Codable`. Data structures which are `Codable` are able to be converted by encoders and decoders into structured data formats, and Foundation has an encoder and decoder for JSON built in. `Codable` itself is the union between two other protocols, `Encodable` and `Decodable`. In our case, we’re only worried about encoding to JSON, so we’ll just worry about `Encodable.`

First, we need to make our `Track` struct conform to `Encodable`. This is a piece of cake. Open up `Track.swift` and make the `Track` struct subclass `Encodable`.

    struct Track: Encodable {

Now we go back to our route handler, and specifically the switch case for `text/json`. We need to instantiate a case of `JSONEncoder` and pass our `tracks` array to its `encode()` method. If all goes well, it will return a `Data` object, which we’ll convert to a String.

            case "text/json"?:
                response.headers["Content-Type"] = "text/json"
                let encoder: JSONEncoder = JSONEncoder()
                let jsonData: Data = try! encoder.encode(tracks)
                output = String(data: jsonData, encoding: .utf8)!
                break

Can it really be that easy? Build and test:
    
    > curl localhost:8080/songs/w -H "Accept: text/json"
    [{"name":"W.M.A.","albumTitle":"Vs.","composer":"Dave Abbruzzese\/Eddie Vedder\/Jeff Ament\/Mike McCready\/Stone Gossard"},{"name":"W\/Brasil (Chama O Síndico)","albumTitle":"Jorge Ben Jor 25 Anos"},{"name":"Wainting On A Friend","albumTitle":"No Security","composer":"Jagger\/Richards"},{"name":"Waiting","albumTitle":"Judas 0: B-Sides and Rarities","composer":"Billy Corgan"},{"name":"Waiting","albumTitle":"International Superhits","composer":"Billie Joe Armstrong -Words Green Day -Music"}, …]

Let’s clean up that output a bit.

    [
      {
        "name": "W.M.A.",
        "albumTitle": "Vs.",
        "composer": "Dave Abbruzzese\/Eddie Vedder\/Jeff Ament\/Mike McCready\/Stone Gossard"
      },
      {
        "name": "W\/Brasil (Chama O Síndico)",
        "albumTitle": "Jorge Ben Jor 25 Anos"
      },
      {
        "name": "Wainting On A Friend",
        "albumTitle": "No Security",
        "composer": "Jagger\/Richards"
      }
      …
    ]

So just as our `tracks` variable in our Swift code was an array of `Track` objects, this JSON code represents an array (delineated by the square brackets) of objects (delineated by the curly braces) with properties for `name`, `albumTitle`, and, when available, `composer` properties.

Yes, it *can* be that easy. Wow.

## XML

Unfortunately, publishing our data in XML is going to be a little more difficult. Part of the reason is that there is a lot more ambiguity on how to “correctly” encode something as XML versus as JSON.

For example, consider the following:

    let arrayOfInts: [Int] = [1, 2, 3]

What is the correct way to encode `arrayOfInts` into JSON? If you asked a hundred coders familiar with JSON this question, I’ll bet you a nice dinner that every single one of them would give you this answer:

    [1, 2, 3]

But how would you encode it as XML? Again, you could ask 100 coders familiar with XML this question, but this time around my bet is that you’d get several dozen different answers *at least.* They might or might not include the following:

    <arrayOfInts>
      <int>1</int>
      <int>2</int>
      <int>3</int>
    </arrayOfInts>
    
    <array type="Int">
      <value>1</value>
      <value>2</value>
      <value>3</value>
    </array>
    
    <collection type="array" name="arrayOfInts">
      <item position="0" value="1" />
      <item position="1" value="2" />
      <item position="2" value="3" />
    </collection>

…And so on. And none of these are necessarily wrong.

So can we just throw the `Encodable` protocol on a class or struct and get it to generate XML as easily as we can with JSON? Well… kind of. You see, besides JSON, Foundation has built-in support to generate *property lists,* or “plists.” Property lists are files that serialize Foundation data types into a particular XML format, but that XML format, or *schema,* is rather verbose and not well optimized to a particular use case. Property lists originate in the NeXTSTEP operating system developed in the late ‘80s, which was eventually purchased by Apple and molded into macOS, which itself served as the basis of Apple’s other operating systems. So outside of the Apple ecosystem, property lists are practically unheard of. So let’s just forget about them and implement our own schema, shall we? I think something that looks like this will work nicely:

    <tracks>
      <track>
        <name>W.M.A.</name>
        <albumTitle>Vs.</albumTitle>
        <composer>Dave Abbruzzese/Eddie Vedder/Jeff Ament/Mike McCready/Stone Gossard</composer>
      </track>
      …
    </tracks>

So the *root element* of our XML document will be `<tracks>`, which will contain several child `<track>` elements. Each `<track>` element will itself contain `<name>`, `<albumTitle>` and `<composer>` elements. This is pretty straightforward, right?

So now that we know what we want our XML to look like, should we write an encoder like `JSONEncoder` so that we can encode our Encodable Track object? Well… we *could.* But writing encoders takes a lot of code, and truth be told, it's best for cases where we need to encode things generically, without necessarily a strictly enforced structure. So if we had many different types of objects we needed to encode into XML, writing an encoder might be a good choice. But for our case, we'll just do things more manually.

Let’s add a method to our `Track` struct to have it create a `<track>` element from itself, along with its corresponding child elements. Open up `Track.swift` and add in something like this.

        func asXmlElement() -> XMLElement {
            let trackElement: XMLElement = XMLElement(name: "track")
            let nameElement: XMLElement = XMLElement(name: "name", stringValue: name)
            let composerElement: XMLElement = XMLElement(name: "composer", stringValue: composer)
            let albumTitleElement: XMLElement = XMLElement(name: "albumTitle", stringValue: albumTitle)
            trackElement.addChild(nameElement)
            trackElement.addChild(composerElement)
            trackElement.addChild(albumTitleElement)
            return trackElement
        }

So we are working with a whole lot of `XMLElement` objects. When we initialize them, we can pass a `name` parameter corresponding to the tag name, and a `stringValue` corresponding to the value between the opening and closing tags.

Now let’s go back to our router callback and the switch case for an XML request.

                case "text/xml"?:
                    response.headers["Content-Type"] = "text/xml"
                    let tracksElement: XMLElement = XMLElement(name: "tracks")
                    for track in tracks {
                        tracksElement.addChild(track.asXmlElement())
                    }
                    let tracksDoc: XMLDocument = XMLDocument(rootElement: tracksElement)
                    let xmlData: Data = tracksDoc.xmlData
                    output = String(data: xmlData, encoding: .utf8)!
                    break

So we are creating a `<tracks>` element, looping through our `tracks` array, and appending child `<track>` elements to it. Finally, we’re creating an `XMLDocument` and setting our `<tracks>` element as the root element. We get a `Data` object out of that, and after it’s converted to a `String`, it will have our XML. Let’s give it a try.

    > curl localhost:8080/songs/k -i -H "Accept: text/xml"
    HTTP/1.1 200 OK
    Date: Wed, 29 Nov 2017 03:35:22 GMT
    Content-Type: text/xml
    Content-Length: 3496
    Vary: Accept
    Connection: Keep-Alive
    Keep-Alive: timeout=60
    
    <tracks><track><name>Karelia Suite, Op.11: 2. Ballade (Tempo Di Menuetto)</name><composer>Jean Sibelius</composer><albumTitle>Sibelius: Finlandia</albumTitle></track><track><name>Kashmir</name><composer>John Bonham</composer><albumTitle>Physical Graffiti [Disc 1]</albumTitle></track><track><name>Kayleigh</name><composer>Kelly, Mosley, Rothery, Trewaves</composer><albumTitle>Misplaced Childhood</albumTitle></track><track><name>Keep It To Myself (Aka Keep It To Yourself)</name><composer>Sonny Boy Williamson [I]</composer><albumTitle>The Best Of Buddy Guy - The Millenium Collection</albumTitle></track>


Again, let’s clean that output up and see what we have.

    <tracks>
      <track>
        <name>Karelia Suite, Op.11: 2. Ballade (Tempo Di Menuetto)</name>
        <composer>Jean Sibelius</composer>
        <albumTitle>Sibelius: Finlandia</albumTitle>
      </track>
      <track>
        <name>Kashmir</name>
        <composer>John Bonham</composer>
        <albumTitle>Physical Graffiti [Disc 1]</albumTitle>
      </track>
      …
    </tracks>

Yep, that looks about right.

We were adding to our router callback in fits and starts in this chapter, so just in case you got lost, here’s what ours should look like - or at least reasonably similar to - in the end.

    router.get("songs/:letter") { request, response, next in
        let letter = request.parameters["letter"]!
    
        let albumSchema = albumTable()
        let trackSchema = trackTable()
    
        let query = Select(trackSchema.Name, trackSchema.Composer, albumSchema.Title, from: trackSchema)
            .join(albumSchema).on(trackSchema.AlbumId == albumSchema.AlbumId)
            .where(trackSchema.Name.like(letter + "%"))
            .order(by: .ASC(trackSchema.Name))
    
        cxn.execute(query: query) { queryResult in
            if let rows = queryResult.asRows {
                var tracks: [Track] = []
                for row in rows {
                    let track = Track(fromRow: row)
                    tracks.append(track)
                }
    
                response.headers["Vary"] = "Accept"
                let output: String
                switch request.accepts(types: ["text/json", "text/xml"]) {
                case "text/json"?:
                    response.headers["Content-Type"] = "text/json"
                    let encoder: JSONEncoder = JSONEncoder()
                    let jsonData: Data = try! encoder.encode(tracks)
                    output = String(data: jsonData, encoding: .utf8)!
                    response.send(output)
                    break
                case "text/xml"?:
                    response.headers["Content-Type"] = "text/xml"
                    let tracksElement: XMLElement = XMLElement(name: "tracks")
                    for track in tracks {
                        tracksElement.addChild(track.asXmlElement())
                    }
                    let tracksDoc: XMLDocument = XMLDocument(rootElement: tracksElement)
                    let xmlData: Data = tracksDoc.xmlData
                    output = String(data: xmlData, encoding: .utf8)!
                    response.send(output)
                    break
                default:
                    response.status(.notAcceptable)
                    next()
                    return
                }
            }
    
            else if let queryError = queryResult.asError {
                let builtQuery = try! query.build(queryBuilder: cxn.queryBuilder)
                response.status(.internalServerError)
                response.send("Database error: \(queryError.localizedDescription) - Query: \(builtQuery)")
            }
        }
        next()
    }
