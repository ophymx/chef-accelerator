Chef Accelerator
================

__NOTE: only works with debian, only tested on ubuntu__

Chef Accelerator is a simple script to get you up an running with chef.
It uses Berkshelf and the Omnibus installer for Chef to bootstrap chef and start running some cookbooks.
It does not require a ruby installed on the system as it uses the ruby embedded in the Omnibus installer.


Just edit the Berkshelf file and write your node.yml.

```yaml
---
recipes:
- apt
- ruby_build
- rbenv
```

and run `./setup.sh`
