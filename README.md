#glowing-octo-ninja
==================

##About
This is a project designed to make debugging hiera related puppet issues easier.

This will get a list of all certnames that the puppet after knows about, then scan your modulepath and find all explicit `hiera()`, `hiera_array()`, and `hiera_hash()` calls and extract the key names. It will then do the same hiera type of hiera lookup for each certificate the master is aware of.

Since facts are often needed to traverse the hiera hierarchy, it can use mcollective, yaml files or json files as the source of these facts when making the lookups.

##Usage
###Examples and Notes
When called with no options, it will act the same as if you passed in `-u peadmin`

```
# ./glowing-octo-ninja
Looking up hiera() call values for pe-323-master.domain.tld.
bar is text
pe_puppetdb::pe::database::reserved_non_postgresql_memory_in_bytes is nil
Looking up hiera_array() call values for pe-323-master.domain.tld.
bat is ["array1", "array2"]
Looking up hiera_hash() call values for pe-323-master.domain.tld.
baz is {"key1"=>"value1", "key2"=>"value2"}
pe_puppetdb::pe::database::database_config_hash is nil
pe_puppetdb::pe::java_args is nil
```

When called with the `--yaml` or `--json` options, a file will need to be created for each certificate that holds key-value pairs for any variables used in your hierarchy.

###Options
- `-h` or `--help`
  - **Description**: Outputs usage information
- `-u <username>` or `--user <username>` 
  - **Default**: `peadmin`
  - **Description**: The username to use when using mcollective as a fact source 
- `-y` or `--yaml`
  - **Description**: Use `<clientcertname>.yaml` as the fact source.
- `-j` or `--json`
  - **Description**: Use `<clientcertname>.json` as the fact source.
- `-d` or `--debug`
  - **Description**: Enable the `--debug` flag when calling hiera.
- `-f <path>' or `--filebase <path>`
  - **Default**: `.`
  - **Description**: The path to be prepended to `<clientcertname>.[yaml|json]` when doing filebased fact source.



##Installation
Simply clone the repo, and copy `glowing-octo-ninja` into somewhere in your path or add the bin directory to your path.. If you have [StupidBashTard](https://github.com/KyleJHarper/stupidbashtard) installed, please change the source line to source that instead of my modified version.  The path to  `sbt_libs.sh` will also need to be updated if you do not add the bin folder to your path.

##To Do
1. ~~Fix the internal help~~
1. Locate and lookup class parameters
1. Add ability to specify as single variable to look up across all nodes
1. Add ability to specify a plaintext key=value file per node as a fact source
1. Add ability to look up all variables for a single node
1. Add ability to specify a group of ndoes via regex
1. Unit and regression tests
1. Add Directory Environment support
1. Provide an option to tell you what variables are used by `hiera.yaml`
1. ??????
1. Profit
1. Same thing we do every night - try to take over the world!

##License
See LICENSE

##Getting Help
If you need help, please look me up in #puppet on Freenode.  I am FriedBob. Please also open an issue here on the GitHub repo.

##FAQ
- "Why"
  - Why not? hiera can be tricky to debug, and there are notany solid, uncomplicated ways to debug it so far.
- "Why 'glowing-octo-ninja'?
  - I suck at naming, and this was a suggested repo name, and ninjas make everything better.
- "Why doesn't it...?"
  - This is an early release, more features are planned. Feature requests and PRs are welcome.
