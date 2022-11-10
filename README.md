# xml-flake

Quick-and-dirty nix flake to generate XML documents from attribute sets.

## Try it out

The flake has a `demo` attribute that results in a minimal webpage:
```
$ nix eval --raw github:CRTified/xml-flake\#demo
<!DOCTYPE html>
<html><head><title>Title of document</title></head><body style="background-color: #00CC00;"><marquee>Wow, what an awesome webpage</marquee></body></html>
```
