---
layout: default
title: Blog
---

Blog
====

{% for post in site.posts %}
  <h2>
    <a href="{{ post.url }}">{{ post.title }}</a>
  </h2>

  <h4>
    Posted
    {% if post.author %}by {{ post.author }}{% endif %} on {{ post.date | date: '%B %e, %Y' }}
  </h4>
{% endfor %}
