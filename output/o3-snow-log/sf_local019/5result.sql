WITH nxt_matches AS (
    SELECT
        m."id",
        m."winner_id"::INT          AS winner_id,
        m."loser_id"::INT           AS loser_id,
        /* convert duration text to total seconds */
        CASE
            WHEN m."duration" IS NULL OR TRIM(m."duration") = '' THEN NULL
            /* format mm:ss               */
            WHEN REGEXP_COUNT(m."duration", ':') = 1 THEN
                 SPLIT_PART(m."duration", ':', 1)::INT * 60
               + SPLIT_PART(m."duration", ':', 2)::INT
            /* format hh:mm:ss             */
            WHEN REGEXP_COUNT(m."duration", ':') = 2 THEN
                 SPLIT_PART(m."duration", ':', 1)::INT * 3600
               + SPLIT_PART(m."duration", ':', 2)::INT * 60
               + SPLIT_PART(m."duration", ':', 3)::INT
        END                              AS duration_seconds
    FROM  WWE.WWE.MATCHES m
    JOIN  WWE.WWE.BELTS  b
          ON m."title_id"::INT = b."id"
    WHERE LOWER(b."name") LIKE '%nxt%'          -- only NXT titles
      AND m."title_change" = 0                  -- exclude title-change bouts
      AND m."duration" IS NOT NULL
      AND TRIM(m."duration") <> ''              -- only timed matches
)
SELECT
    w_win."name"  AS winner_name,
    w_lose."name" AS loser_name
FROM nxt_matches nm
JOIN WWE.WWE.WRESTLERS w_win  ON w_win."id" = nm.winner_id
JOIN WWE.WWE.WRESTLERS w_lose ON w_lose."id" = nm.loser_id
ORDER BY nm.duration_seconds ASC NULLS LAST,    -- shortest first
         nm."id" ASC
LIMIT 1;