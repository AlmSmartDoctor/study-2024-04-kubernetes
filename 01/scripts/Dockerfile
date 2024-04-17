FROM golang:1.14.1-alpine3.11

COPY ./main.go ./

RUN go build -o main .

ENTRYPOINT ["./main"]
