package main

import (
    "context"
    "log"
    "github.com/jackc/pgx/v5"
	"os"
)

func main() {
    conn, err := pgx.Connect(context.Background(), os.Getenv("CNPG_URI"))
    if err != nil {
        log.Fatal(err)
    }
    defer conn.Close(context.Background())

    if err = conn.Ping(context.Background()); err != nil {
        log.Fatal(err)
    }
}
