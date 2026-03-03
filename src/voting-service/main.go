package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5"
)

func main() {
	conn, err := pgx.Connect(context.Background(), os.Getenv("CNPG_URI"))
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close(context.Background())

	err = conn.Ping(context.Background())
	if err != nil {
		log.Fatal(err)
	} else {
		log.Println("DB connection is established")
	}

	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Get("/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("pong"))
	})

	http.ListenAndServe(os.Getenv("IP_ADDR")+":"+"8080", r)
}
