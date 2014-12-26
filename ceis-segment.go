package main

import (
	"flag"
	"fmt"
	"strings"
	"github.com/PuerkitoBio/goquery"
)

func ExtractThings(url string, selector string) map[string]string {
	var doc *goquery.Document
	var e error
	var ret map[string]string

	ret = make(map[string]string)

	if doc, e = goquery.NewDocument(url); e != nil {
		fmt.Printf("ERROR: %s\n", e.Error())
		return ret
	}

	doc.Find("script").Each(func (_ int, s *goquery.Selection) {
		p := s.Parent().Nodes[0]
		p.RemoveChild( s.Nodes[0] )
	})

	doc.Find(selector).Each(func (i int, s *goquery.Selection){ 
		if link, ok := s.Attr("href"); ok {
			var t string

			lvl := 0
			p := s
			q := p.Parent()

			for q.Find(selector).Size() <= 1 {
				lvl++
				q = q.Parent()
				p = p.Parent()
			}
			
			t = ""
			p.Contents().Each(func (i int, s *goquery.Selection) { t += " " + s.Text() })
			t = strings.Replace(t, "\n", " ", -1)
			t = strings.Replace(t, "\t", " ", -1)
			
			title := ""
			for _, _t := range strings.Split(t, " ") {
				if _t != "" {
					title += " " + _t
				}
			}
			title = strings.TrimSpace(title);

			ret[link] = title
		}
	})

	return ret
}

// go run ceis-segment.go 'https://duckduckgo.com/html/?q=nihao' 'a'
func main() {
	flag.Parse()
	url := flag.Arg(0)
	selector := flag.Arg(1)

	things := ExtractThings(url, selector)
	for i := range things {
		fmt.Printf("%v\n%v\n\n", i, things[i])
	}
}
