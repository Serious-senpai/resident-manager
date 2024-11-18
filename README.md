[![Azure deployment](https://github.com/Serious-senpai/resident-manager/actions/workflows/deploy.yml/badge.svg?branch=main&event=push)](https://github.com/Serious-senpai/resident-manager/actions/workflows/deploy.yml)
[![Flutter build](https://github.com/Serious-senpai/resident-manager/actions/workflows/build.yml/badge.svg?branch=main&event=push)](https://github.com/Serious-senpai/resident-manager/actions/workflows/build.yml)
[![Lint](https://github.com/Serious-senpai/resident-manager/actions/workflows/lint.yml/badge.svg?branch=main&event=push)](https://github.com/Serious-senpai/resident-manager/actions/workflows/lint.yml)
[![Run tests](https://github.com/Serious-senpai/resident-manager/actions/workflows/tests.yml/badge.svg?branch=main&event=push)](https://github.com/Serious-senpai/resident-manager/actions/workflows/tests.yml)

Management system for residents sharing an apartment.

## API server

### Response codes

This is the list of possible values in the `"code"` field of every JSON response object. Note that this is
different from the HTTP response code.

The reason we return a result code instead of a string is to give the client a chance to translate the response
message into a specific language.

| Code | Description |
| ---- | ----------- |
| 0 | Successful response |
| 101 | Invalid resident name |
| 102 | Invalid resident room number |
| 103 | Invalid resident phone number |
| 104 | Invalid resident email address |
| 105 | Invalid resident username |
| 106 | Invalid resident password |
| 107 | The registration username has already been used |
| 201 | Unable to authorize resident from JWT |
| 301 | Target resident ID does not exist in an update request |
| 401 | Unauthorized administrator operation |
| 402 | Unauthorized resident operation |
| 501 | Invalid room's area |
| 502 | Invalid room's motorbikes count |
| 503 | Invalid room's cars count |
| 601 | Invalid fee name |
| 602 | Invalid fee lower bound and upper bound |
| 603 | Invalid fee per area |
| 604 | Invalid fee per motorbike |
| 605 | Invalid fee per car |
