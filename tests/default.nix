{ self }:
let
  success = name:
    builtins.derivation {
      inherit name;
      system = builtins.currentSystem;
      builder = "/bin/sh";
      args = [ "-c" "true > $out" ];
    };
  fail = name: cond:
    throw ''

      Check ${name} failed.

      ---------- EXPECTED VALUE ----------
      ${cond.expected}
      ---------- EXPECTED VALUE ----------

      ${cond.name}

      ----------- FOUND VALUE ------------
      ${cond.test}
      ----------- FOUND VALUE ------------
    '';

  mkCondition = name: op:
    { expected, test }: {
      operation = op;
      inherit name expected test;
    };
  runCondition = { operation, expected, test, ... }: operation expected test;

  testEq = mkCondition "equals" (x: y: x == y);

  mkTest = name: cond:
    if runCondition cond then success name else fail name cond;
in builtins.mapAttrs (mkTest) {

  emptyDocument = testEq {
    expected = "";
    test = self.xmlDoc {
      xmldecl = null;
      rootNode = null;
    };
  };

  justXMLdeclDocument = testEq {
    expected = ''<?xml version="1.0" encoding="utf-8"?>'';
    test =
      self.xmlDoc { xmldecl = ''<?xml version="1.0" encoding="utf-8"?>''; };
  };

  simpleWebpage = testEq {
    expected = ''
      <!DOCTYPE html><html><head><title>Title of document</title></head><body style="background-color: #00CC00;"><marquee>Wow, what an awesome webpage</marquee></body></html>'';
    test = self.xmlDoc {
      xmldecl = "<!DOCTYPE html>";
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
