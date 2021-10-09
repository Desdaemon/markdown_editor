```pseudo
procedure Apply-Diff(template, element):
    c-template := children of template
    c-element := children of element
    N := Length(c-template)

    for count := N to 0:
        extra := c-element[N - count]
        parent := parent of extra
        remove extra from parent

    for index := 0 to Length(c-template):
        node := c-template[index]
        elm-node := c-element[index]

        if elm-node does not exist:
            add a clone of node into element

        else if Node-Type(node) != Node-Type(elm-node):
            parent := parent of elm-node
            replace elm-node with node in parent
        
        else:
            node-txt := Node-Content(node)
            katex-changed := Compare-Katex-Hashes(node-txt, elm-node)
            if node-txt is not empty AND katex-changed AND node-txt != Node-Content(elm-node):
                elm-node.text-content := node-txt
            
            elm-node-is-parent := Length(children of elm-node) > 0
            node-is-parent := Length(children of node) > 0

            if elm-node-is-parent AND not node-is-parent AND katex-changed:
                elm-node.text-content := node-txt 

            else if not elm-node-is-parent AND node-is-parent:
                fragment := new fragment element
                Apply-Diff(node, fragment)
                insert fragment into element

            else:
                Apply-Diff(node, elm-node)


procedure Node-Type(a, b):
    todo
    
procedure Node-Content(a):
    todo
    
procedure Compare-Katex-Hashes(text, node):
    todo
```