{
  inputs = { };
  outputs = { self }:
    let
      inherit (builtins)
        concatStringsSep toString getAttr attrNames attrValues all length
        isAttrs isString isBool isList elemAt elem concatMap filter sort
        listToAttrs replaceStrings;

      defaultSettings = {
        boolToString = b: if b then "true" else "false";
        prettyPrint = false;
        prettyPrintIndent = 2;
      };

      optionalStr = cond: s: if cond then s else "";

      # Helper function
      # Converts a flat attrset to a space-separated list.
      mkAttrStr = attrs:
        let
          isValid = all (x: x) [
            (isAttrs attrs) # Attribute have to be an attrset
            (all (x: !(isAttrs x))
              (attrValues attrs)) # and the attrset needs to be non-nested
          ];
        in if !isValid then
          throw "attrs is not a valid flat attrset"
        else if attrs == { } then
          ""
        else
          " " + (concatStringsSep " "
            (map (n: ''${n}="${toString (getAttr n attrs)}"'')
              (attrNames attrs)));

      # Helper function
      # Takes the bare minimum of a node and builds the tag out of it
      nodeToStr = settings:
        let
          ifPP = optionalStr settings.prettyPrint;
          concatSep = ifPP ("\n" + (concatStringsSep ""
            (builtins.genList (x: " ") settings.prettyPrintIndent)));
          renderChild = x:
            if settings.prettyPrint then
              replaceStrings [ "\n" ] [ concatSep ] (nodeToStr settings x)
            else
              nodeToStr settings x;
        in self:
        if !(isAttrs self) then
          toString self
        else if "node_text" == ({ __type = "default"; } // self).__type then
          toString self
        else if self.children' == [ ] || self.children' == null then
        # We are in the case of an empty tag. Use a short self-closing tag
          "<${self.name}${mkAttrStr self.attributes'}/>"
        else
        # Surround the toString-converted children with the tag
          "<${self.name}${mkAttrStr self.attributes'}>${ifPP concatSep}${
            concatStringsSep concatSep (map (renderChild) self.children')
          }${ifPP "\n"}</${self.name}>";
    in {
      lib = {
        # Main function to build the XML document.
        xmlDoc = { xmldecl ? null, document ? { }, settings ? { } }:
          let
            finalSettings = defaultSettings // settings;
            isValidDocument = all (x: x) [

              ((length (attrNames document))
                <= 1) # XML forbids more than one root node
            ];
          in if isValidDocument then
            (if isString xmldecl then
              (xmldecl + (if finalSettings.prettyPrint then "\n" else ""))
            else
              "") + (if document == { } then
                ""
              else
                toString (elemAt (self.lib.mkNodes settings document) 0))
          else
            throw "Invalid document";

        # Utility function for text nodes
        #
        # mkTextNode :: String -> Int -> Node
        mkTextNode = text: priority': {
          inherit text priority';
          __type = "node_text";
          __toString = s: s.text;
        };

        # Function that takes an attrset and converts it to
        # an attrset structure that translates directly to XML.
        # The attrset overrides toString for the XML conversion.
        #
        # Returns a list of nodes, as the root attrset may contain more
        # than one element.
        #
        # mkNodes :: Either Attrset a -> [Node]
        mkNodes = settings: target:
          let finalSettings = defaultSettings // settings;
          in if target == null then
          # No input
            [ ]
          else if isBool target then
          # Translate bool to true/false
            [ (finalSettings.boolToString target) ]
          else if isList target then
          # Lists are simply converted to nodes, depending on their content
            concatMap (self.lib.mkNodes) target
          else if !(isAttrs target) then
          # Everything else is simply converted to a list element
            [ target ]
          else
          # Filter ignored fields
            filter (x: x != null) (map (name:
              let
                ignoredFields = [ "priority'" "attributes'" "children'" ];
                value = getAttr name target;
                cmpNodes = e1: e2: (e1.priority' or 0) < (e2.priority' or 0);
              in if elem name ignoredFields then
                null
              else {
                inherit name;
                attributes' = value.attributes' or { };
                priority' = value.priority' or 0;

                # List of child nodes, sorted (stable) by priority
                # The child nodes are generated by a recursive call,
                # at least if they're not supplied directly
                children' = sort (cmpNodes)
                  ((value.children' or [ ]) ++ self.lib.mkNodes settings value);

                __toString = nodeToStr finalSettings;
                __type = "node";
              }) (attrNames target));
      };

      checks = listToAttrs (map (name: {
        inherit name;
        value = import ./tests {
          inherit self;
          system = name;
        };
      }) [ "x86_64-linux" ]);
    };
}
