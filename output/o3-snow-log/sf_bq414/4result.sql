WITH crop_conf AS (
    SELECT
        "object_id",
        TRY_TO_DOUBLE(
            (TRY_PARSE_JSON("cropHintsAnnotation"):cropHints[0]:confidence)::STRING
        ) AS "crop_confidence"
    FROM THE_MET.THE_MET.VISION_API_DATA
)

SELECT
    o."object_id",
    o."title",
    TO_CHAR(
        TO_TIMESTAMP(o."metadata_date" / 1000000),
        'YYYY-MM-DD'
    ) AS "metadata_date"
FROM THE_MET.THE_MET.OBJECTS o
JOIN crop_conf c
  ON o."object_id" = c."object_id"
WHERE o."department" = 'The Libraries'
  AND c."crop_confidence" > 0.5
  AND o."title" ILIKE '%book%';