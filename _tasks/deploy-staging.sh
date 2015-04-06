#!/usr/bin/env bash
jekyll build && rsync -avz -e "ssh -p 2683 -i ~/.ssh/klepas.org" --delete _site/ klepasor@klepas.org:public_html/bruin/
