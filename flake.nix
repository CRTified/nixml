{
  inputs = { };
  outputs = { self }:
    let
      mkAttrStr = attrs:
        if attrs == { } then
          ""
        else
          " " + (builtins.concatStringsSep " "
            (map (n: ''${n}="${builtins.toString (builtins.getAttr n attrs)}"'')
              (builtins.attrNames attrs)));

      nodeToStr = self:
        if self.children == [ ] || self.children == null then
          "<${self.name}${mkAttrStr self.attributes'}/>"
        else
          "<${self.name}${mkAttrStr self.attributes'}>${
            builtins.concatStringsSep "" (map (builtins.toString) self.children)
          }</${self.name}>";
    in {
      xmlDoc = { xmldecl ? null, document ? { } }:
        let
          isValidDocument = builtins.all (x: x)
            [ ((builtins.length (builtins.attrNames document)) <= 1) ];
        in if isValidDocument then
          (if builtins.isString xmldecl then xmldecl else "")
          + (if document == { } then
            ""
          else
            builtins.toString (builtins.elemAt (self.mkNodes document) 0))
        else
          throw "Invalid document";

      mkTextNode = text: priority': {
        inherit text priority';
        __toString = self: self.text;
      };

      # Function that takes an attrset and converts it to
      # "naive" XML where values are textual leaf nodes
      # and attributes are XML nodes.
      # Note that there are no guarantees about the order
      # within one attrset.
      # mkNodes :: attrset -> [attrset]
      mkNodes = attrset:
        with builtins;
        if attrset == null then
          [ ]
        else if isBool attrset then
          [ (if attrset then "true" else "false") ]
        else if isList attrset then
          builtins.concatMap (self.mkNodes) attrset
        else if !(isAttrs attrset) then
          [ attrset ]
        else
          filter (x: x != null) (map (name:
            let value = getAttr name attrset;
            in if elem name [ "priority'" "attributes'" "children'" ] then
              null
            else {
              inherit name;
              attributes' = value.attributes' or { };
              priority' = value.priority' or 0;
              # List of child nodes, sorted (stable) by priority
              children =
                sort (e1: e2: (e1.priority' or 0) < (e2.priority' or 0))
                ((value.children' or [ ]) ++ self.mkNodes value);

              __toString = nodeToStr;
            }) (attrNames attrset));

      checks = builtins.listToAttrs (map (name: {
        inherit name;
        value = import ./tests {
          inherit self;
          system = name;
        };
      }) [ "x86_64-linux" ]);
    };
}
