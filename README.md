# Scaped
## To run locally (using Docker)
1. Copy `docker-compose.dev.yml` to `docker-compose.yml`
2. Generate a secret: `python3 -c 'import secrets; print(secrets.token_urlsafe(48)[:64])'`
3. In `docker-compose.yml`, add the following variables:
```yml
      SECRET_KEY_BASE: "<your secret>"
      GROQ_API_KEY: 
      AZURE_KEY:
      AZURE_CLU_KEY: 
      STUDY_ID: "<any string>"
```
4. Run docker compose:
```sh
docker compose up -d
```
5. Create the database:
```sh
docker compose run phx bin/migrate
```
6. Access your app (change `study_id` to a string from above): http://localhost:5011/?prolific_pid=test&session_id=test&study_id={study_id}




