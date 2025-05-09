SELECT DISTINCT
       o."title",
       o."artist_display_name"   AS "artist_name",
       o."medium",
       i."original_image_url"
FROM   THE_MET.THE_MET.OBJECTS  AS o
JOIN   THE_MET.THE_MET.IMAGES   AS i
       ON o."object_id" = i."object_id"
WHERE  o."department" = 'Photographs'
  AND  o."object_name" ILIKE '%Photograph%'
  AND  o."artist_display_name" IS NOT NULL
  AND  o."artist_display_name" NOT ILIKE '%unknown%'
  AND  o."object_end_date" <= 1839;