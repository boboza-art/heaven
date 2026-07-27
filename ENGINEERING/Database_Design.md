# Database Design


## Users

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| email | VARCHAR(255) | User email |
| password_hash | VARCHAR(255) | Hashed password |
| nickname | VARCHAR(100) | Display name |
| created_at | TIMESTAMP | Registration time |


## MoodLogs

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to Users |
| mood_level | INTEGER | 1-5 scale |
| note | TEXT | Optional note |
| created_at | TIMESTAMP | Log time |


## ChatMessages

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to Users |
| role | VARCHAR(20) | user / assistant |
| content | TEXT | Message content |
| created_at | TIMESTAMP | Message time |


## Memories

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to Users |
| category | VARCHAR(50) | Memory category |
| content | TEXT | Memory content |
| approved | BOOLEAN | User approved flag |
| created_at | TIMESTAMP | Memory time |
