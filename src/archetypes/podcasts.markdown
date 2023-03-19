---
title: "{{ replace .Name "-" " " | title }}"
description: ""
date: {{ .Date }}
draft: true
tags: []
categories: []
feed:
  explicit: {{ .Site.Params.Feed.explicit | default false }}
  type: {{ .Site.Params.Feed.type | default "episodic" }}
---

