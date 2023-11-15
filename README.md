# AI_DEVS2

This repository contains libs and tasks from AI Devs 2 course

## Description

This repository includes exercises, libraries, and tasks related to the AI Devs 2 course. Users can explore various Ruby-based functionalities and AI-related implementations.
All tasks is running on Debian 11.8

## Ruby version and custom gems

```bash
$ rvm list gemsets
=> ruby-3.2.2@aidevs [ x86_64 ]
```

```bash
dotenv (2.8.1)
httparty (0.21.0)
json (2.6.3)
mysql2 (0.5.5)
ruby-openai (6.1.0, 5.2.0, 4.0.0)
open-uri (0.3.0)
qdrant-ruby (0.9.4)
securerandom (default: 0.2.2)
```

## Software requirements 

[Qdrant](https://qdrant.tech/)

[mariadb](https://mariadb.org/)

## Installation

To begin, ensure you have the necessary environment set up and follow these steps:
Fill in your secrets using the .env.example file.
```bash
cp .env.example .evn
vi .env
```
Update the .env file with your configurations.

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.
