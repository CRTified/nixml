{
  inputs = { };
  outputs = { self }: {
    # A valid node has at least a name
    # Attributes and child nodes are optional
    isNode = arg:
      builtins.all (x: x) [
        (builtins.isAttrs arg)
        #(self.isValidTagName arg.name)
      ];

    xmlStr = name: content:
      with builtins;
      if !(isAttrs content) then
        toString content
      else
        let
          nodeCmp = n1: n2:
            if hasAttr "-priority" n1 then
              if hasAttr "-priority" n2 then
                n1."-priority" < n2."-priority"
              else
                n1."-priority" < 0
            else if hasAttr "-priority" n2 then
              0 < n2."-priority"
            else
              true;

          children = sort (n1: n2: nodeCmp content."${n1}" content."${n2}")
            (filter (f: f != "-attributes" && f != "-priority")
              (attrNames content));

          childStr = concatStringsSep ""
            (map (x: self.xmlStr x content."${x}") children);

          hasAttributes = hasAttr "-attributes" content;

          attrStr = if hasAttributes then
            " " + (concatStringsSep " "
              (map (x: ''${x}="${toString content."-attributes"."${x}"}"'')
                (attrNames content."-attributes")))
          else
            "";
        in if substring 0 1 name == "-" then
          concatStringsSep "" (map (x: toString content."${x}") children)
        else
          "<${name}${
            if hasAttributes then attrStr else ""
          }>${childStr}</${name}>";

    xmlDoc = { xmldecl ? null, rootNodeName, rootNode ? null }:
      (if builtins.isString xmldecl then xmldecl else "")
      + (if self.isNode rootNode then
        self.xmlStr rootNodeName rootNode
      else
        "");

    checks = builtins.listToAttrs (map (name: {
      inherit name;
      value = import ./tests { inherit self; system = name; };
    }) [ "x86_64-linux" ]);
  };
}
