package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
	"sync/atomic"
)

var (
	healthzCount atomic.Int64
	boomCount    atomic.Int64

	mu     sync.RWMutex
	broken bool
)

func main() {
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}

	http.HandleFunc("/healthz", healthzHandler)
	http.HandleFunc("/boom", boomHandler)
	http.HandleFunc("/metrics", metricsHandler)

	log.Printf("go-sample listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}

func healthzHandler(w http.ResponseWriter, r *http.Request) {
	healthzCount.Add(1)
	mu.RLock()
	b := broken
	mu.RUnlock()
	if b {
		http.Error(w, "broken", http.StatusInternalServerError)
		return
	}
	w.Write([]byte("ok\n"))
}

func boomHandler(w http.ResponseWriter, r *http.Request) {
	boomCount.Add(1)
	mu.Lock()
	broken = !broken
	b := broken
	mu.Unlock()
	if b {
		w.Write([]byte("breaking.\n"))
	} else {
		w.Write([]byte("healed.\n"))
	}
}

func metricsHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "# HELP homelab_healthz_total Number of /healthz requests.\n")
	fmt.Fprint(w, "# TYPE homelab_healthz_total counter\n")
	fmt.Fprintf(w, "homelab_healthz_total %d\n", healthzCount.Load())
	fmt.Fprint(w, "# HELP homelab_boom_total Number of /boom requests.\n")
	fmt.Fprint(w, "# TYPE homelab_boom_total counter\n")
	fmt.Fprintf(w, "homelab_boom_total %d\n", boomCount.Load())
}
