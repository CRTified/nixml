# nixml

Quick-and-dirty nix flake to generate XML documents from attribute sets.

## Try it out

The flake has a check that results in a minimal webpage:

```
$ cat $(nix build --no-link --print-out-paths github:CRTified/nixml\#checks.x86_64-linux.simpleWebpage)
<!DOCTYPE html><html><head><title>Title of document</title></head><body style="background-color: #00CC00;"><marquee>Wow, what an awesome webpage</marquee></body></html>
```
