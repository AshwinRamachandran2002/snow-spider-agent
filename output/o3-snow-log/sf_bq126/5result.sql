SELECT
    o."title",
    o."artist_display_name"  AS "artist_name",
    o."medium",
    i."original_image_url"
FROM THE_MET.THE_MET."OBJECTS"  o
JOIN THE_MET.THE_MET."IMAGES"   i
      ON o."object_id" = i."object_id"
WHERE o."department"      = 'Photographs'
  AND o."object_name" ILIKE '%Photograph%'          -- ensure “Photograph” is in the object’s name
  AND o."artist_display_name" IS NOT NULL           -- artist must be specified
  AND o."artist_display_name" NOT ILIKE '%unknown%' -- exclude “Unknown” artists
  AND o."object_end_date" <= 1839;