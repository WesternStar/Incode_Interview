package main

import (
	"embed"
	"html/template"
	"io"
)

//go:embed templates/*.html
var templateFS embed.FS

type templateSet struct {
	templates *template.Template
}

func loadTemplates() (*templateSet, error) {
	tmpl, err := template.New("").Funcs(template.FuncMap{
		"duration": formatDuration,
	}).ParseFS(templateFS, "templates/*.html")
	if err != nil {
		return nil, err
	}
	return &templateSet{templates: tmpl}, nil
}

func (t *templateSet) render(w io.Writer, name string, data any) error {
	return t.templates.ExecuteTemplate(w, name, data)
}
