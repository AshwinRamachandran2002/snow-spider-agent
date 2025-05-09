WITH matches_with_duration AS (
    SELECT
        m."id",
        m."winner_id",
        m."loser_id",
        m."duration",
        m."title_id",
        m."title_change",
        CASE
            WHEN (LENGTH(m."duration") - LENGTH(REPLACE(m."duration", ':', ''))) = 2 THEN
                (TO_NUMBER(SPLIT_PART(m."duration", ':', 1)) * 3600) + (TO_NUMBER(SPLIT_PART(m."duration", ':', 2)) * 60) + TO_NUMBER(SPLIT_PART(m."duration", ':', 3))
            WHEN (LENGTH(m."duration") - LENGTH(REPLACE(m."duration", ':', ''))) = 1 THEN
                (TO_NUMBER(SPLIT_PART(m."duration", ':', 1)) * 60) + TO_NUMBER(SPLIT_PART(m."duration", ':', 2))
            ELSE
                NULL
        END AS total_seconds
    FROM WWE.WWE.MATCHES m
    WHERE m."title_id" = 23153 AND m."title_change" = 0 AND m."duration" IS NOT NULL
)
SELECT w1."name" AS wrestler1_name, w2."name" AS wrestler2_name
FROM matches_with_duration mwd
JOIN WWE.WWE.WRESTLERS w1 ON mwd."winner_id" = w1."id"
JOIN WWE.WWE.WRESTLERS w2 ON mwd."loser_id" = w2."id"
ORDER BY mwd.total_seconds ASC NULLS LAST
LIMIT 1;