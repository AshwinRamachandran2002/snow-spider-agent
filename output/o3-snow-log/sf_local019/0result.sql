WITH nxt_matches AS (
    SELECT
        m."id",
        m."winner_id",
        m."loser_id",
        m."duration",
        /* convert duration to total seconds */
        CASE  
            WHEN m."duration" IS NULL OR TRIM(m."duration") = '' THEN NULL
            WHEN ARRAY_SIZE(SPLIT(m."duration", ':')) = 2 THEN      /* mm:ss */
                 TO_NUMBER(SPLIT(m."duration", ':')[0]) * 60
               + TO_NUMBER(SPLIT(m."duration", ':')[1])
            WHEN ARRAY_SIZE(SPLIT(m."duration", ':')) = 3 THEN      /* hh:mm:ss */
                 TO_NUMBER(SPLIT(m."duration", ':')[0]) * 3600
               + TO_NUMBER(SPLIT(m."duration", ':')[1]) * 60
               + TO_NUMBER(SPLIT(m."duration", ':')[2])
        END AS duration_seconds
    FROM WWE.WWE.MATCHES   m
    JOIN WWE.WWE.BELTS     b  ON m."title_id" = b."id"
    WHERE b."name" ILIKE '%NXT%'          -- only NXT titles
      AND m."title_change" = 0            -- exclude title-change bouts
      AND m."duration" IS NOT NULL
      AND TRIM(m."duration") <> ''
), shortest AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY duration_seconds NULLS LAST) AS rn
    FROM nxt_matches
)
SELECT 
    w1."name" AS "wrestler_1",
    w2."name" AS "wrestler_2"
FROM shortest s
JOIN WWE.WWE.WRESTLERS w1 ON w1."id" = TO_NUMBER(s."winner_id")
JOIN WWE.WWE.WRESTLERS w2 ON w2."id" = TO_NUMBER(s."loser_id")
WHERE s.rn = 1;