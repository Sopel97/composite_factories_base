import sys
import base64
import zlib
import json
from collections import defaultdict

input_filename = sys.argv[1]

with open(input_filename, 'r') as infile:
    data = base64.b64decode(infile.read()[1:])
    text = zlib.decompress(data)
    d = json.loads(text)
    item_counts = defaultdict(lambda: 0)
    for e in d['blueprint']['entities']:
        item_counts[e['name']] += 1

    for k, v in item_counts.items():
        print('{{\"{}\", {}}},'.format(k, v))
