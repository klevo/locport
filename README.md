# locport

* Standardizes keeping track of local development ports.
* See which ports are listening.
* Automatically assign unused ports.
* See conflicts.
* Proxy and daemon free.

![locport-logo](https://github.com/user-attachments/assets/52df253c-aeb9-46a1-9c26-a40ad733379f)

## Introducing the .localhost file convention

A project can define within it's root, the `.localhost` file, that lists local hosts with ports that the project uses.

Format of this file is a simple list of `<host>:<port>` separated by newlines. For example:

```sh
hello.localhost:3001
another.service.localhost:3002
```

A single project can have multiple addresses associated to it.

To add the project to **locport**, simply `locport index [PATH1] [PATH2]`. Now you can overview hosts and ports with
`locport` and easily discover conflicts across any number of projects.

You can also add projects recursively, like so: `locport index ~/projects -r`. This will look for directories that contain `.localhost` file and indexes those.

<img width="687" height="175" alt="list success" src="https://github.com/user-attachments/assets/2b1dbef7-fa3b-44b9-af3e-f48340d3b49a" />

## Installation

[Ruby](https://www.ruby-lang.org/) is required.

```sh
gem install locport
```

## Usage

### Adding hosts

You've got several options to create or add to `.localhost` file, 
from within your project directory:

```sh
# Creates .localhost file in the current directory, with randomly assigned unused port,
# and hostname based on the current directory name suffixed with .localhost
locport add

# Adding a custom hostname and letting locport find a port
locport add myapp.localhost

# Example with a user specified port
locport add myapp.localhost:30000
```

### Listing projects and hosts

```sh
locport
# OR
locport list
```

If any conflicts are detected, they will be displayed and program exits with error code 1.

<img width="685" height="254" alt="list conflicts" src="https://github.com/user-attachments/assets/ea5eeb06-1d96-4932-bc5f-93e950572e78" />

### Adding existing projects to the index

```sh
# Add specific projects that contain .localhost file
locport index ~/projects/a ~/projects/b

# Recursively find and index .localhost files
```

## Development

PRs are welcome. To set up locally from within the checked out repo:

```sh
# Install dependencies
bundle

# Run commands with dev code
ruby -Ilib/ bin/locport
```

### Running tests

```sh
bin/rake
```
