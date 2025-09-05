# locport

Manage local ports across projects. Prevent conflicts. 

Inspired by [DHH's Rails World 2025 keynote](https://www.youtube.com/watch?v=gcwzWzC7gUA&t=1625s) 
part about how 37Signals deals with this in development.

<img width="1057" height="475" alt="Screenshot 2025-09-05 at 09 59 17" src="https://github.com/user-attachments/assets/a5242dc6-3d68-4898-9838-43e8d6d48d0a" />

# .localhost file

A project can define `.localhost` file, that lists local domains with ports that the project uses.
Indexing such file/project with `locport index .` allows to list all local URLs and detect port conflicts.

`lockport add <url>[:<port>]` adds to the `.localhost` file (or creates it) if no port conflicts are found. If no port is specified, 
a random port number is assigned from a pool.

## Implementation

Append projects added with `lockport index` to a configuration file, kept in an appropriate system folder.
When `add` or `list` is invoked these directories are scanned for `.localhost` files.

## Development

```sh
# Install dependencies
bundle

# Run commands with dev code
ruby -Ilib/ bin/locport
```
