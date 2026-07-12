{% macro image() %}
#pad(left: {{ design.header.photo_space_left }}, right: {{ design.header.photo_space_right }}, image("{{ cv.photo.name }}", width: {{ design.header.photo_width }}))
{% endmacro %}

{% if cv.photo %}
{% set photo = "image(\"" + cv.photo|string + "\", width: "+ design.header.photo_width + ")" %}
#grid(
{% if design.header.photo_position == "left" %}
  columns: (auto, 1fr),
{% else %}
  columns: (1fr, auto),
{% endif %}
  column-gutter: 0cm,
  align: horizon + left,
{% if design.header.photo_position == "left" %}
  [{{ image() }}],
  [
{% else %}
  [
{% endif %}
{% endif %}
{% if cv.headline %}
#block(height: 0pt, width: 100%, above: 0pt, below: 0pt)[
  #place(top + right, dy: -0.85cm)[
    #text(size: 7.5pt, weight: "semibold", fill: rgb(37, 99, 149))[{{ cv.headline }}]
  ]
]
{% endif %}
{% if cv.name %}
= {{ cv.name }}
{% endif %}

#connections(
{% for connection in cv.connections %}
  [{{ connection }}],
{% endfor %}
)
{% if cv.photo %}
{% if design.header.photo_position == "left" %}
  ]
)
{% else %}
  ],
  [{{ image() }}],
)
{% endif %}
{% endif %}
