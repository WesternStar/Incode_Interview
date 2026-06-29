package main

import (
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/jackc/pgx/v5/pgxpool"
)

type server struct {
	pool      *pgxpool.Pool
	templates *templateSet
}

func (s *server) handleIndex(w http.ResponseWriter, r *http.Request) {
	if err := s.templates.render(w, "index.html", nil); err != nil {
		log.Printf("render index: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
	}
}

func (s *server) handleArtistSearch(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")

	artists, err := searchArtists(r.Context(), s.pool, query)
	if err != nil {
		log.Printf("search artists: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	if err := s.templates.render(w, "artists.html", artists); err != nil {
		log.Printf("render artists: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
	}
}

func (s *server) handleArtistAlbums(w http.ResponseWriter, r *http.Request) {
	artistID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		http.Error(w, "invalid artist id", http.StatusBadRequest)
		return
	}

	albums, err := albumsByArtist(r.Context(), s.pool, artistID)
	if err != nil {
		log.Printf("albums by artist: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	if err := s.templates.render(w, "albums.html", albums); err != nil {
		log.Printf("render albums: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
	}
}

func (s *server) handleAlbumTracks(w http.ResponseWriter, r *http.Request) {
	albumID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		http.Error(w, "invalid album id", http.StatusBadRequest)
		return
	}

	tracks, err := tracksByAlbum(r.Context(), s.pool, albumID)
	if err != nil {
		log.Printf("tracks by album: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	if err := s.templates.render(w, "tracks.html", tracks); err != nil {
		log.Printf("render tracks: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
	}
}

func formatDuration(ms int) string {
	totalSeconds := ms / 1000
	return fmt.Sprintf("%d:%02d", totalSeconds/60, totalSeconds%60)
}
