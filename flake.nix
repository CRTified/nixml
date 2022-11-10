{
  inputs = { };
  outputs = { self }: {
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
    xmlDoc = { docstr, rootNode }: ''
      ${docstr}
      ${self.xmlStr rootNode}
    '';

    demo = self.xmlDoc {
      docstr = "<!DOCTYPE html>";
      rootNode = {
        name = "html";
        childs = [
          {
            name = "head";
            childs = [{
              name = "title";
              childs = [ "Title of document" ];
            }];
          }
          {
            name = "body";
            attributes = { style = "background-color: #00CC00;"; };
            childs = [{
              name = "marquee";
              childs = [ "Wow, what an awesome webpage" ];
            }];
          }
        ];
      };
    };
  };
}
