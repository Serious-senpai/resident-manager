# resident-manager

[![Azure deployment](https://github.com/Serious-senpai/resident-manager/actions/workflows/deploy.yml/badge.svg?branch=main&event=push)](https://github.com/Serious-senpai/resident-manager/actions/workflows/deploy.yml)
[![Flutter build](https://github.com/Serious-senpai/resident-manager/actions/workflows/build.yml/badge.svg?branch=main&event=push)](https://github.com/Serious-senpai/resident-manager/actions/workflows/build.yml)
[![Lint](https://github.com/Serious-senpai/resident-manager/actions/workflows/lint.yml/badge.svg?branch=main&event=push)](https://github.com/Serious-senpai/resident-manager/actions/workflows/lint.yml)
[![Run tests](https://github.com/Serious-senpai/resident-manager/actions/workflows/tests.yml/badge.svg?branch=main&event=push)](https://github.com/Serious-senpai/resident-manager/actions/workflows/tests.yml)

Management system for residents sharing an apartment.

## API server

### Response codes

The reason we return a result code instead of a string is to give the client a chance to translate the response
message into a specific language.

| Code | Description |
| ---- | ----------- |
| 0 | Successful response |
| 101 | Invalid registration name |
| 102 | Invalid registration room number |
| 103 | Invalid registration phone number |
| 104 | Invalid registration email address |
| 105 | Invalid registration username |
| 106 | Invalid registration password |
| 107 | The registration username has already been used |
| 201 | Login username does not exist |
| 202 | Incorrect login password |
| 203 | Incorrect administrator authentication data |
| 204 | Unable to decrypt password |
