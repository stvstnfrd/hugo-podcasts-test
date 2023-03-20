---
title: {{ replace .Name "-" " " | title }}
description: ''
date: {{ .Date }}
draft: true
tags: []
feed:
  type: full
  explicit: {{ .Site.Params.Feed.explicit | default false }}
  attachments: []
---

