WITH crop_conf AS (
    SELECT
        v."object_id",
        MAX(
            TRY_TO_DOUBLE(f.value:confidence::STRING)
        ) AS "crop_confidence"
    FROM THE_MET.THE_MET."VISION_API_DATA" v
         , LATERAL FLATTEN(INPUT => TRY_PARSE_JSON(v."cropHintsAnnotation"):cropHints) f
    GROUP BY v."object_id"
)
SELECT
    o."object_id",
    o."title",
    TO_CHAR(TO_TIMESTAMP(o."metadata_date" / 1000000), 'YYYY-MM-DD') AS "metadata_date"
FROM THE_MET.THE_MET."OBJECTS" o
JOIN crop_conf c
  ON o."object_id" = c."object_id"
WHERE o."department" = 'The Libraries'
  AND o."title" ILIKE '%book%'
  AND c."crop_confidence" > 0.5;