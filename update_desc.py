#!/usr/bin/env python3

from lxml import etree
import sys

root = etree.parse(sys.argv[1])
date = sys.argv[2]
new_size = sys.argv[3]
bak_name = sys.argv[4]
root.xpath("date")[0].text = date
origin_size = int(root.xpath("size")[0].text)
origin_storage_left = int(root.xpath("storageLeft")[0].text)
total_size = origin_size + origin_storage_left
root.xpath("size")[0].text = new_size
root.xpath("storageLeft")[0].text = str(total_size - int(new_size))
root.xpath("//bakFile")[0].text = bak_name
root.write(sys.argv[5], xml_declaration=True, standalone=True, encoding="utf-8")
