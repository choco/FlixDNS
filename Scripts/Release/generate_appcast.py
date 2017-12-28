#!/usr/bin/env python
"""
Helpers to generate Sparkle AppCast XML
AppCast is a RSS2.0-based spec for publishing application versions
- https://sparkle-project.org/documentation/publishing/
- https://github.com/vslavik/winsparkle/wiki/Appcast-Feeds
"""

from xml.etree import ElementTree
from dateutil.parser import parse as parse_datetime


class Channel:
    tag_name = "channel"

    def __init__(self, title, link, language=""):
        self.title = title
        self.link = link
        self.language = language
        self.items = []
 
    def to_xml(self):
        ret = ElementTree.Element("rss")
        ret.attrib["version"] = "2.0"
        ret.attrib["xmlns:sparkle"] = "http://www.andymatuschak.org/xml-namespaces/sparkle"
        ret.attrib["xmlns:dc"] = "http://purl.org/dc/elements/1.1/"
 
        channel = ElementTree.Element(self.tag_name)
        ret.append(channel)
 
        title = ElementTree.Element("title")
        title.text = self.title
        channel.append(title)
 
        link = ElementTree.Element("link")
        link.text = self.link
        channel.append(link)
 
        if self.language:
            language = ElementTree.Element("language")
            language.text = self.language
            channel.append(language)
 
        for item in self.items:
            channel.append(item.to_xml())
 
        return ret
 
    def to_xml_string(self):
        return ElementTree.tostring(self.to_xml()).decode("utf-8")
 
 
class Item:
    tag_name = "item"
 
    def __init__(self, title, description, pub_date):
        self.title = title
        self.description = description
        self.pub_date = pub_date
        self.minimum_system_version = ""
 
    def to_xml(self):
        ret = ElementTree.Element(self.tag_name)
 
        title = ElementTree.Element("title")
        title.text = self.title
        ret.append(title)
 
        description = ElementTree.Element("description")
        description.text = self.description
        ret.append(description)
 
        pub_date = ElementTree.Element("pubDate")
        pub_date.text = self.pub_date.isoformat()
        ret.append(pub_date)
 
        return ret
 
 
class AppCastItem(Item):
    def __init__(self, *args):
        super().__init__(*args)
        self.minimum_system_version = ""
        self.version = ""
        self.short_version_string = ""
        self.url = ""
        self.length = 0
        self.type = "application/octet-stream"
        self.release_notes_link = ""
 
    def to_xml(self):
        ret = super().to_xml()
 
        if self.minimum_system_version:
            minver = ElementTree.Element("sparkle:minimumSystemVersion")
            minver.text = self.minimum_system_version
            ret.append(minver)
 
        if self.release_notes_link:
            link = ElementTree.Element("sparkle:releaseNotesLink")
            link.text = self.release_notes_link
            ret.append(link)
 
        enclosure = ElementTree.Element("enclosure")
        enclosure.attrib["url"] = self.url
        enclosure.attrib["type"] = self.type
        enclosure.attrib["length"] = str(self.length)
        enclosure.attrib["sparkle:version"] = self.version
        enclosure.attrib["sparkle:shortVersionString"] = self.short_version_string
        ret.append(enclosure)
 
        return ret
 
 
def item_from_github(release):
    title = release["name"]
    description = release["body"]
    date = parse_datetime(release["published_at"])
    url = release["html_url"]
 
    item = AppCastItem(title, description, date)
    item.short_version_string = release["tag_name"]
    item.version = str(release["id"])  # TODO
 
    if not release["assets"]:
        return item
    # Only support ==1 asset
    asset = release["assets"][0]
    item.url = asset["browser_download_url"]
    item.type = asset["content_type"]
    item.length = asset["size"]
    return item
 
 
def from_github(org, repo):
    """
    Convert a list of releases in a Github repository
    to an AppCast channel
    """
    import requests

    # https://api.github.com/repos/HearthSim/HDT-Releases/releases
    url = "https://github.com/%s/%s" % (org, repo)
    releases_url = "https://api.github.com/repos/%s/%s/releases" % (org, repo)
    r = requests.get(releases_url)
    d = r.json()

    channel = Channel(repo, url)
    for release in d:
        item = item_from_github(release)
        channel.items.append(item)
    return channel


def main():
    import sys

    if len(sys.argv) < 3:
        print("Usage: %s <GH-ORG> <GH-REPO>" % (sys.argv[0]))
        exit(1)

    org = sys.argv[1]
    repo = sys.argv[2]
    print(from_github(org, repo).to_xml_string())


if __name__ == "__main__":
    main()
