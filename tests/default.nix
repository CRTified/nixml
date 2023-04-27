{ self, system }:
let
  success = name: cond:
    builtins.derivation {
      inherit name system;
      builder = "/bin/sh";
      args = [ "-c" "echo '${toString cond.test}' > $out" ];
    };
  fail = name: cond:
    throw ''

      Check ${name} failed.

      ---------- EXPECTED VALUE ----------
      ${toString cond.expected}
      ---------- EXPECTED VALUE ----------

      ${cond.name}

      ----------- FOUND VALUE ------------
      ${toString cond.test}
      ----------- FOUND VALUE ------------
    '';

  mkCondition = name: op:
    { expected, test }: {
      operation = op;
      inherit name expected test;
    };
  runCondition = { operation, expected, test, ... }: operation expected test;

  testEq = mkCondition "equals" (x: y: x == y);
  testTrue = c:
    mkCondition "The following is true" (_: y: builtins.isBool y && y) {
      expected = true;
      test = c;
    };
  testFalse = c:
    mkCondition "The following is false" (_: y: builtins.isBool y && !y) {
      expected = false;
      test = c;
    };

  mkTest = name: cond:
    if runCondition cond then success name cond else fail name cond;

in builtins.mapAttrs (mkTest) {
  emptyDocument = testEq {
    expected = "";
    test = self.xmlDoc {
      xmldecl = null;
      document = { };
    };
  };

  justXMLdeclDocument = testEq {
    expected = ''<?xml version="1.0" encoding="utf-8"?>'';
    test = self.xmlDoc {
      xmldecl = ''<?xml version="1.0" encoding="utf-8"?>'';
      document = { };
    };
  };

  simpleWebpage = testEq {
    expected = ''
      <!DOCTYPE html><html><head><title>Title of document</title></head><body style="background-color: #00CC00;">This is above the marquee.<marquee>Wow, what an awesome webpage</marquee>This is below the marquee.</body></html>'';

    test = self.xmlDoc {
      xmldecl = "<!DOCTYPE html>";

      document = {
        html = {
          head = {
            priority' = -1;
            title = "Title of document";
          };
          body = {
            attributes' = { style = "background-color: #00CC00;"; };
            children' = [
              (self.mkTextNode "This is below the marquee." 1)
              (self.mkTextNode "This is above the marquee." (-1))
            ];
            marquee = "Wow, what an awesome webpage";
          };
        };
      };
    };
  };
}
