-- Task: What are the titles, artist names, mediums, and original image URLs of objects with 'Photograph' in their names from the 'Photographs' department?
SELECT o.title, o.artist_display_name, o.medium, i.original_image_url
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.images` AS i
ON o.object_id = i.object_id
WHERE LOWER(o.object_name) LIKE '%photograph%'
  AND o.department = 'Photographs'
  AND o.title IS NOT NULL
  AND o.medium IS NOT NULL
  AND i.original_image_url IS NOT NULL;