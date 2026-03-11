import Foundation
import Testing
@testable import ReadMiniMacOS

struct FeedParserTests {
    @Test
    func parsesRSSFeed() throws {
        let xml = """
        <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
          <channel>
            <title>Example Feed</title>
            <description>Feed Description</description>
            <item>
              <title>Article One</title>
              <link>https://example.com/article-1</link>
              <description><![CDATA[<p>Summary</p>]]></description>
              <content:encoded><![CDATA[<p>Body</p><img src="https://example.com/image.jpg" />]]></content:encoded>
              <pubDate>Wed, 10 Jan 2024 10:00:00 +0000</pubDate>
            </item>
          </channel>
        </rss>
        """

        let payload = try XMLFeedParsing().parse(data: Data(xml.utf8))

        #expect(payload.title == "Example Feed")
        #expect(payload.description == "Feed Description")
        #expect(payload.entries.count == 1)
        #expect(payload.entries[0].title == "Article One")
        #expect(payload.entries[0].link == "https://example.com/article-1")
        #expect(payload.entries[0].firstImageURL == "https://example.com/image.jpg")
    }

    @Test
    func parsesAtomFeed() throws {
        let xml = """
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Atom Feed</title>
          <subtitle>Atom Description</subtitle>
          <entry>
            <title>Atom Entry</title>
            <link href="https://example.com/atom-entry" />
            <updated>2024-02-01T10:30:00Z</updated>
            <summary type="html">&lt;p&gt;Atom Summary&lt;/p&gt;</summary>
            <content type="html">&lt;p&gt;Atom Body&lt;/p&gt;</content>
            <author><name>Author</name></author>
          </entry>
        </feed>
        """

        let payload = try XMLFeedParsing().parse(data: Data(xml.utf8))

        #expect(payload.title == "Atom Feed")
        #expect(payload.entries.count == 1)
        #expect(payload.entries[0].author == "Author")
        #expect(payload.entries[0].contentHTML.contains("Atom Body"))
    }
}
