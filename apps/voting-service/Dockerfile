FROM golang:1.26.1-alpine AS build
WORKDIR /app

COPY ./go.mod ./go.sum ./
COPY . .

RUN go build .

EXPOSE 8080

CMD ["./voting-service"]
