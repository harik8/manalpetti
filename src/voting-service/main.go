package main

import (
    "context"
    "log"
    "time"
    "github.com/jackc/pgx/v5"
    "os"
)

func main() {
    conn, err := pgx.Connect(context.Background(), os.Getenv("CNPG_URI"))
    if err != nil {
        log.Fatal(err)
    }
    defer conn.Close(context.Background())

    for {
        if err = conn.Ping(context.Background()); err != nil {
            log.Printf("ping failed: %v", err)
        } else {
            log.Println("connected to database")
        }
        time.Sleep(5 * time.Second)
    }
}
