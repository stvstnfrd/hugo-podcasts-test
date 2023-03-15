---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
author:
  name: {{ .Site.Author.name }}
  email: {{ .Site.Author.email }}
tags: []
feed:
  admin:
    name: {{ .Site.Author.name }}
    email: {{ .Site.Author.email }}
  editor:
    name: {{ .Site.Author.name }}
    email: {{ .Site.Author.email }}
  language: {{ .Site.Language }}
  explicit: {{ .Site.Params.Feed.explicit | default false }}
  type: {{ .Site.Params.Feed.type | default "episodic" }}
  copyright: Copyright 2023, {{ .Site.Title }}
  status: {{ .Site.Params.Feed.status | default "ongoing" }}
  ttl: {{ .Site.Params.Feed.ttl | default 1440 }}
---

