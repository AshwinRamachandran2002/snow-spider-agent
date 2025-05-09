SELECT
    vd."object_id",
    o."title",
    TO_CHAR(
        TO_TIMESTAMP_LTZ(o."metadata_date" / 1000000),  -- convert micro-seconds epoch to timestamp
        'YYYY-MM-DD'
    ) AS "formatted_metadata_date"
FROM THE_MET.THE_MET."VISION_API_DATA" vd
JOIN THE_MET.THE_MET."OBJECTS"           o
      ON vd."object_id" = o."object_id"
WHERE o."department" = 'The Libraries'
  AND o."title" ILIKE '%book%'                           -- title contains the word “book”
  AND COALESCE(                                          
        (vd."cropHintsAnnotation":"cropHints"[0]:"confidence")::FLOAT,
        0
      ) > 0.5;                                           -- cropConfidence > 0.5