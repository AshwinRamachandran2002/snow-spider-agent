SELECT DISTINCT
  o.title,
  o.artist_display_name AS artist_name,
  o.medium,
  i.original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.images`  AS i
     ON o.object_id = i.object_id
WHERE LOWER(o.department) = 'photographs'
  AND LOWER(o.object_name) LIKE '%photograph%'
  AND o.object_end_date <= 1839
  AND o.artist_display_name IS NOT NULL
  AND NOT REGEXP_CONTAINS(LOWER(o.artist_display_name), r'\bunknown\b')
  AND i.original_image_url IS NOT NULL;