SELECT
  o."object_id",
  o."title",
  TO_CHAR(TO_TIMESTAMP(o."metadata_date" / 1000000), 'YYYY-MM-DD') AS "metadata_date"
FROM THE_MET.THE_MET."OBJECTS"            o
JOIN THE_MET.THE_MET."VISION_API_DATA"    v
  ON o."object_id" = v."object_id"
WHERE o."department" = 'The Libraries'
  AND o."title" ILIKE '%book%'
  AND v."cropHintsAnnotation":"cropHints"[0]."confidence"::FLOAT > 0.5;