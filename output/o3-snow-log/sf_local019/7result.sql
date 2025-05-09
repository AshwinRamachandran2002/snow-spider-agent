WITH nxt_matches AS (
    SELECT
        m."id"           AS match_id,
        m."winner_id",
        m."loser_id",
        m."duration",
        /* convert duration text to total seconds */
        CASE
            WHEN m."duration" IS NULL OR TRIM(m."duration") = '' THEN NULL
            /* HH:MM:SS */
            WHEN REGEXP_COUNT(m."duration", ':') = 2 THEN
                     TO_NUMBER(SPLIT_PART(m."duration", ':', 1)) * 3600
                   + TO_NUMBER(SPLIT_PART(m."duration", ':', 2)) * 60
                   + TO_NUMBER(SPLIT_PART(m."duration", ':', 3))
            /* MM:SS */
            WHEN REGEXP_COUNT(m."duration", ':') = 1 THEN
                     TO_NUMBER(SPLIT_PART(m."duration", ':', 1)) * 60
                   + TO_NUMBER(SPLIT_PART(m."duration", ':', 2))
        END            AS duration_sec
    FROM WWE.WWE.MATCHES m
    JOIN WWE.WWE.BELTS   b  ON b."id" = TO_NUMBER(m."title_id")
    WHERE b."name" ILIKE '%NXT%'      -- only NXT championships
      AND m."title_change" = 0        -- exclude matches with a title change
      AND m."duration" IS NOT NULL
      AND TRIM(m."duration") <> ''
)
SELECT
    w_win."name"  AS winner_name,
    w_loss."name" AS loser_name
FROM nxt_matches       nm
JOIN WWE.WWE.WRESTLERS w_win  ON w_win."id"  = TO_NUMBER(nm."winner_id")
JOIN WWE.WWE.WRESTLERS w_loss ON w_loss."id" = TO_NUMBER(nm."loser_id")
WHERE nm.duration_sec IS NOT NULL
ORDER BY nm.duration_sec ASC NULLS LAST
LIMIT 1;