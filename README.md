# locport

Manage local ports across projects. Prevent conflicts.

## .locport file

A project can define `.localhost` file, that lists local domains with ports that the project uses.
Indexing such file/project with `locport index .` allows to list all local URLs and detect port conflicts.

`lockport add <url>[:<port>]` adds to the `.localhost` file (or creates it) if no port conflicts are found. If no port is specified, 
a random port number is assigned from a pool.

## Implementation

Append projects added with `lockport index` to a configuration file, kept in an appropriate system folder.
When `add` or `list` is invoked these directories are scanned for `.localhost` files.
