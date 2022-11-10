# xml-flake

Quick-and-dirty nix flake to generate XML documents from attribute sets.

## Try it out

The flake has a check that results in a minimal webpage:

```
$ cat $(nix eval --raw github:CRTified/xml-flake\#checks.x86_64-linux.simpleWebpage)
<!DOCTYPE html><html><head><title>Title of document</title></head><body style="background-color: #00CC00;"><marquee>Wow, what an awesome webpage</marquee></body></html>
```
