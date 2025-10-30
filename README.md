# locport

Manage local ports across projects. Prevent conflicts. Overview all your projects, hosts and ports. Proxy-free.

![localhost](https://github.com/user-attachments/assets/a930a841-5a41-4c92-8d51-453100c288d0)

## Introducing the .localhost file convention

<img width="687" height="175" alt="list success" src="https://github.com/user-attachments/assets/2b1dbef7-fa3b-44b9-af3e-f48340d3b49a" />

A project can define within it's root, the `.localhost` file, that lists local hosts with ports that the project uses.

Format of this file is a simple list of `<host>:<port>` separated by newlines. For example:

```sh
hello.localhost:3001
another.service.localhost:3002
```

A single project can have zero, one or multiple domains associated to it.

To add the project to **locport**, simply `locport index [PATH]`. Now you can overview hosts and ports with
`locport list` and easily discover conflicts across any number of projects.

## Installation

[Ruby](https://www.ruby-lang.org/) is required.

```sh
gem install locport
```

## Usage

### Adding hosts with ports to a project

To create and/or add to `.localhost` file, from within your project directory:

```sh
locport add <url>[:<port>]

# Example where a unique port is automatically assigned by locport
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

### TODOs

- [ ] Handle empty lines in dotfile
- [ ] Some hostname validation during `add`
- [ ] Remove project from the index
- [ ] Test suite

## Development

PRs are welcome. To set up locally from within the checked out repo:

```sh
# Install dependencies
bundle

# Run commands with dev code
ruby -Ilib/ bin/locport
```
