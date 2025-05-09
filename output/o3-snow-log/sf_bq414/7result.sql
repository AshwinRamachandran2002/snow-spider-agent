SELECT DISTINCT
       o."object_id",
       o."title",
       TO_CHAR(
           TO_TIMESTAMP_NTZ(o."metadata_date" / 1000000),   -- microseconds → seconds
           'YYYY-MM-DD'
       ) AS "metadata_date"
FROM   THE_MET.THE_MET."OBJECTS"         AS o
JOIN   THE_MET.THE_MET."VISION_API_DATA" AS v
      ON o."object_id" = v."object_id"
CROSS JOIN LATERAL FLATTEN(
           INPUT => PARSE_JSON(v."cropHintsAnnotation"):"cropHints"
         ) AS ch
WHERE  o."department" = 'The Libraries'
  AND  o."title" ILIKE '%book%'
  AND  TRY_TO_DOUBLE(ch.value:"confidence"::STRING) > 0.5;