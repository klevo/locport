<img src="https://github.com/user-attachments/assets/52df253c-aeb9-46a1-9c26-a40ad733379f alt="locport logo" width="300" heigh="300" />

* Standardizes keeping track of local development ports.
* See which ports are listening.
* Automatically assign unused ports.
* See conflicts.
* Proxy and daemon free.

<img width="846" height="646" alt="adding and listing" src="https://github.com/user-attachments/assets/133e36c7-9bc9-46b6-871f-e4f77cdf5f93" />
<img width="846" height="646" alt="conflicts" src="https://github.com/user-attachments/assets/260f97b6-1cd5-44f9-92f2-858ccaa2b3d1" />

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
