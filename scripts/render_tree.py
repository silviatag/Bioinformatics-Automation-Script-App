import os
os.environ["QT_QPA_PLATFORM"] = "offscreen"

from ete3 import Tree, TreeStyle, NodeStyle, TextFace
import sys

nw_file = sys.argv[1]
img_file = sys.argv[2]

# make output folder if needed
os.makedirs(os.path.dirname(img_file), exist_ok=True)

t = Tree(nw_file)

# --- Tree Style ---
ts = TreeStyle()
ts.show_branch_support = True
ts.show_scale = True
ts.branch_vertical_margin = 15

# Correctly add title
title_face = TextFace("Phylogenetic Tree", fsize=14)
ts.title.add_face(title_face, column=0)

# Node styling
nstyle = NodeStyle()
nstyle["size"] = 5
nstyle["fgcolor"] = "black"
nstyle["vt_line_width"] = 2
nstyle["hz_line_width"] = 2
for n in t.traverse():
    n.set_style(nstyle)

# Render tree
t.render(img_file, tree_style=ts, w=800, units="px")
print(f"Tree image saved as {img_file}")
