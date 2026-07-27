# API Specification

## Base URL

```
/api/v1
```

## Endpoints

### Auth

| Method | Path | Description |
|--------|------|-------------|
| POST | /auth/register | User registration |
| POST | /auth/login | User login |
| POST | /auth/refresh | Refresh token |

### Mood

| Method | Path | Description |
|--------|------|-------------|
| POST | /mood | Log current mood |
| GET | /mood | Get mood history |
| GET | /mood/trend | Get mood trend |

### Chat

| Method | Path | Description |
|--------|------|-------------|
| POST | /chat | Send message to AI |
| GET | /chat | Get chat history |

### Exercises

| Method | Path | Description |
|--------|------|-------------|
| GET | /exercises | List available exercises |
| GET | /exercises/{id} | Get exercise details |
| POST | /exercises/{id}/complete | Mark exercise completed |
