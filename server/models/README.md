# Response codes

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
