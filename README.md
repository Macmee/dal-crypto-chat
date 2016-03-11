###SERVER

**INSTALLING SERVER**

it's located at `/server`:

1. get nodejs 5.5.x
2. run `npm install`
3. `cd` into `/server/patches/import-export` and run `npm install` there too
4. `cd` back to `/server` and run `node index`

**SEND MESSAGE ENDPOINT**

TYPE: `PUT`

URL: `http://localhost:8005/messages`

BODY PARAMS: `user_id`, `to_user_id`, `message`

RESPONSE: `{ success: true }`

**GET MESSAGES ENDPOINT**

TYPE: `GET`

URL: `localhost:8005/messages?user_id=USER_ID_HERE`

RESPONSE:
```
{
  "messages": [{
      "user_id": "a",
      "to_user_id": "b",
      "message": "c",
      "created_at": "2016-03-04T16:20:27.145Z",
      "id": "smt34WSvJuRjwEjz"
    }, {
      "user_id": "a",
      "to_user_id": "b",
      "message": "c",
      "created_at": "2016-03-04T16:36:47.062Z",
      "id": "xZ7gYRfz0fWquW1p"
    }]
}
```
