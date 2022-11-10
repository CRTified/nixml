{
  inputs = { };
  outputs = { self }: {
    # A valid node has at least a name
    # Attributes and child nodes are optional
    isNode = arg:
      builtins.foldl' (x: y: x && y) true
        [
          (builtins.isAttrs arg)
          (builtins.hasAttr "name" arg)
        ];
        
    
    xmlStr = { name, attributes ? { }, childs ? [ ] }:
      with builtins;
      let
        childStr = concatStringsSep ""
          (map (x: if isAttrs x then self.xmlStr x else toString x) childs);
        attrStr = concatStringsSep " "
          (map (x: ''${x}="${toString attributes."${x}"}"'')
            (attrNames attributes));
      in "<${name}${
        if attributes != { } then " " + attrStr else ""
      }>${childStr}</${name}>";
    
    xmlDoc = { xmldecl ? null, rootNode ? null }:
      (if builtins.isString xmldecl then xmldecl else "") +
      (if self.isNode rootNode then self.xmlStr rootNode else "");

    checks = builtins.listToAttrs (map (name: {
      inherit name;
      value = import ./tests { inherit self; };
    }) [ "x86_64-linux" ]);
  };
}
