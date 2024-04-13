package main

import (
	"bytes"
	"embed"
	"fmt"
	"io"
	"net/http"
	"os"

	"golang.org/x/exp/slog"
)

const portDefault = "8001"

//go:embed static
var content embed.FS

func main() {
	// establish port
	port := os.Getenv("PORT")
	if port == "" {
		port = portDefault
	}
	slog.Info("Preparing to start a server", "port", port)

	// routes
	mux := http.NewServeMux()
	mux.HandleFunc("/", getRoot)
	mux.Handle("/static/", http.FileServer(http.FS(content)))

	// listen and serve
	slog.Info("Starting server", "port", port)
	err := http.ListenAndServe(":"+port, mux)
	if err != nil {
		slog.Error("error starting server", "error", err)
		panic(fmt.Errorf("error starting server: %w", err))
	}
}

func getRoot(w http.ResponseWriter, r *http.Request) {
	slog.Info("request received",
		"route", "/",
		"method", r.Method,
		"user-agent", r.UserAgent(),
	)
	// Open the file from the embedded file system
	f, err := content.Open("static/html/index.html")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer f.Close()

	// Read the entire file into memory
	data, err := io.ReadAll(f)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Get the file info
	fi, err := f.Stat()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	reader := bytes.NewReader(data)
	http.ServeContent(w, r, fi.Name(), fi.ModTime(), reader)
}
