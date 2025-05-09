WITH "NXT_MATCHES" AS (
    SELECT
        m."id"                       AS "match_id",
        m."winner_id",
        m."loser_id",
        /* convert duration (MM:SS or HH:MM:SS) to total seconds */
        CASE
            WHEN m."duration" IS NULL OR m."duration" = '' THEN NULL
            WHEN REGEXP_COUNT(m."duration", ':') = 1 THEN       -- MM:SS
                 TO_NUMBER(SPLIT_PART(m."duration", ':', 1)) * 60
               + TO_NUMBER(SPLIT_PART(m."duration", ':', 2))
            WHEN REGEXP_COUNT(m."duration", ':') = 2 THEN       -- HH:MM:SS
                 TO_NUMBER(SPLIT_PART(m."duration", ':', 1)) * 3600
               + TO_NUMBER(SPLIT_PART(m."duration", ':', 2)) * 60
               + TO_NUMBER(SPLIT_PART(m."duration", ':', 3))
        END                                                   AS "duration_seconds"
    FROM WWE.WWE."MATCHES"  m
    JOIN WWE.WWE."BELTS"    b
      ON TO_NUMBER(m."title_id") = b."id"
    WHERE LOWER(b."name") LIKE '%nxt%'        -- only NXT titles
      AND m."title_change" = 0               -- exclude title changes
      AND m."duration" IS NOT NULL
      AND m."duration" <> ''
)
SELECT
    w1."name" AS "winner_name",
    w2."name" AS "loser_name"
FROM "NXT_MATCHES" nm
JOIN WWE.WWE."WRESTLERS" w1 ON w1."id" = TO_NUMBER(nm."winner_id")
JOIN WWE.WWE."WRESTLERS" w2 ON w2."id" = TO_NUMBER(nm."loser_id")
ORDER BY nm."duration_seconds" ASC NULLS LAST
LIMIT 1;