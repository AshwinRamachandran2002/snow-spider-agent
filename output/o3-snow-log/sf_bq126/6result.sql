SELECT 
    o."title",
    o."artist_display_name"  AS "artist_name",
    o."medium",
    MIN(i."original_image_url") AS "original_image_url"
FROM THE_MET.THE_MET."OBJECTS" AS o
LEFT JOIN THE_MET.THE_MET."IMAGES" AS i
       ON o."object_id" = i."object_id"
WHERE o."department" = 'Photographs'
  AND o."object_name" ILIKE '%Photograph%'
  AND o."object_end_date" <= 1839
  AND o."artist_display_name" IS NOT NULL
  AND UPPER(o."artist_display_name") NOT LIKE '%UNKNOWN%'
GROUP BY 
    o."title",
    o."artist_display_name",
    o."medium"
ORDER BY 
    o."title";