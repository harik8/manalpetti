# FROM python:3.13-slim as build

# LABEL HARI KARTHIGASU <khprasaad@gmail.com>

# WORKDIR /app

# COPY ./src .

# RUN pip3 install --upgrade pip && \
#     pip3 install -r requirements.txt

# FROM gcr.io/distroless/python3

# WORKDIR /app

# ENV PYTHONPATH=/usr/lib/python3.13
# EXPOSE 8080

# COPY --from=build /app /app
# COPY --from=build /usr/local/lib/python3.13/site-packages/ /usr/lib/python3.13/

# CMD ["app.py"]

# FROM python:3
# WORKDIR /app
# COPY . .
# CMD ["python", "-m", "http.server", "8000"]

FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o main .

FROM alpine:latest
WORKDIR /app
COPY --from=build /app/main .
CMD ["./main"]