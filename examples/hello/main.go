// SPDX-License-Identifier: GPL-2.0
package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var helloCounter = promauto.NewCounter(prometheus.CounterOpts{
	Name: "hello_endpoint_total_calls",
	Help: "The total number of calls to the /hello endpoint",
})

func main() {
	http.Handle("/metrics", promhttp.Handler())
	http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello")
		helloCounter.Inc()
	})
	log.Fatal(http.ListenAndServe(":8080", nil))
}
