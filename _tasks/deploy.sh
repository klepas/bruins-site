#!/usr/bin/env bash
jekyll build && rsync -avz -e "ssh -p 2683" --delete _site/ cbchrist@cbchristensen.net:public_html/
