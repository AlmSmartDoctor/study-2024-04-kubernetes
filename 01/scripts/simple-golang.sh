#!/bin/bash

cat <<EOF > main.go
package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, World!")
    })

    log.Fatal(http.ListenAndServe(":8080", nil))
}
EOF

cat <<EOF > Dockerfile
FROM golang:1.14.1-alpine3.11

COPY ./main.go ./

RUN go build -o main .

ENTRYPOINT ["./main"]
EOF

docker build -t simple-golang .