package main

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Artist struct {
	ID   int
	Name string
}

type Album struct {
	ID       int
	Title    string
	ArtistID int
}

type Track struct {
	ID            int
	Name          string
	AlbumID       int
	Composer      string
	Milliseconds  int
	UnitPrice     float64
}

func newPool(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("creating pgx pool: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("pinging database: %w", err)
	}
	return pool, nil
}

func searchArtists(ctx context.Context, pool *pgxpool.Pool, query string) ([]Artist, error) {
	rows, err := pool.Query(ctx, `
		SELECT artist_id, name
		FROM artist
		WHERE $1 = '' OR name ILIKE '%' || $1 || '%'
		ORDER BY name
		LIMIT 50
	`, query)
	if err != nil {
		return nil, fmt.Errorf("querying artists: %w", err)
	}
	defer rows.Close()

	var artists []Artist
	for rows.Next() {
		var a Artist
		if err := rows.Scan(&a.ID, &a.Name); err != nil {
			return nil, fmt.Errorf("scanning artist: %w", err)
		}
		artists = append(artists, a)
	}
	return artists, rows.Err()
}

func albumsByArtist(ctx context.Context, pool *pgxpool.Pool, artistID int) ([]Album, error) {
	rows, err := pool.Query(ctx, `
		SELECT album_id, title, artist_id
		FROM album
		WHERE artist_id = $1
		ORDER BY title
	`, artistID)
	if err != nil {
		return nil, fmt.Errorf("querying albums: %w", err)
	}
	defer rows.Close()

	var albums []Album
	for rows.Next() {
		var al Album
		if err := rows.Scan(&al.ID, &al.Title, &al.ArtistID); err != nil {
			return nil, fmt.Errorf("scanning album: %w", err)
		}
		albums = append(albums, al)
	}
	return albums, rows.Err()
}

func tracksByAlbum(ctx context.Context, pool *pgxpool.Pool, albumID int) ([]Track, error) {
	rows, err := pool.Query(ctx, `
		SELECT track_id, name, album_id, COALESCE(composer, ''), milliseconds, unit_price::float8
		FROM track
		WHERE album_id = $1
		ORDER BY track_id
	`, albumID)
	if err != nil {
		return nil, fmt.Errorf("querying tracks: %w", err)
	}
	defer rows.Close()

	var tracks []Track
	for rows.Next() {
		var t Track
		if err := rows.Scan(&t.ID, &t.Name, &t.AlbumID, &t.Composer, &t.Milliseconds, &t.UnitPrice); err != nil {
			return nil, fmt.Errorf("scanning track: %w", err)
		}
		tracks = append(tracks, t)
	}
	return tracks, rows.Err()
}
