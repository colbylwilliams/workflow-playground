# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import argparse

from pathlib import Path

dir_root = Path(__file__).resolve().parent.parent.parent
pages_dir = dir_root / 'src' / 'Web' / 'Pages'

home_page = pages_dir / 'Index.cshtml'
basket_page = pages_dir / 'Basket' / 'Index.cshtml'

bad_replacement = '<img class="esh-catalog-title" src="~/images/main_banner_text.png" />'
good_replacement = '<img class="esh-catalog-title" src="~/images/main_banner_text.png" alt="All t-shirts on sale this weekend" />'

placeholder = '@* DEMO PLACEHOLDER *@'

parser = argparse.ArgumentParser()
parser.add_argument('branch', choices=['a', 'b'])
parser.add_argument('--reverse', action='store_true')

args = parser.parse_args()

branch = args.branch
reverse = args.reverse

bad = branch == 'a'
good = branch == 'b'

def _replace_placeholder(file, holder, content):
    with open(file, 'r') as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        if holder in line:
            lines[i] = content
    with open(file, 'w') as f:
        f.writelines(lines)

if reverse:
    _replace_placeholder(home_page, good_replacement, placeholder)
    _replace_placeholder(basket_page, bad_replacement, placeholder)
    _replace_placeholder(basket_page, good_replacement, placeholder)

else:
    _replace_placeholder(home_page, placeholder, good_replacement)
    if bad:
        _replace_placeholder(basket_page, placeholder, bad_replacement)
    if good:
        _replace_placeholder(basket_page, good_replacement)
