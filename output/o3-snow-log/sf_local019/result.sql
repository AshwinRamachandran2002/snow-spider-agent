WITH "NXT_MATCHES" AS (
    SELECT
        m."id"                     AS "match_id",
        m."duration",
        /* convert duration text to number of seconds */
        CASE
            WHEN m."duration" IS NULL OR m."duration" = '' THEN NULL
            /* format HH:MM:SS */
            WHEN ARRAY_SIZE(SPLIT(m."duration", ':')) = 3 THEN
                 3600 * TO_NUMBER(SPLIT_PART(m."duration", ':', 1))
               +  60 * TO_NUMBER(SPLIT_PART(m."duration", ':', 2))
               +       TO_NUMBER(SPLIT_PART(m."duration", ':', 3))
            /* format MM:SS */
            WHEN ARRAY_SIZE(SPLIT(m."duration", ':')) = 2 THEN
                 60 * TO_NUMBER(SPLIT_PART(m."duration", ':', 1))
               +      TO_NUMBER(SPLIT_PART(m."duration", ':', 2))
        END                         AS "seconds",
        CAST(m."winner_id" AS NUMBER) AS "winner_id",
        CAST(m."loser_id"  AS NUMBER) AS "loser_id"
    FROM WWE.WWE."MATCHES" m
    JOIN WWE.WWE."BELTS"   b
          ON CAST(m."title_id" AS NUMBER) = b."id"
    WHERE b."name" ILIKE '%NXT%'      -- only NXT titles
      AND m."title_change" = 0        -- exclude matches with a title change
      AND m."duration" IS NOT NULL
      AND m."duration" <> ''
)
SELECT
    w_win."name"  AS "winner_name",
    w_lose."name" AS "loser_name"
FROM "NXT_MATCHES" nm
JOIN WWE.WWE."WRESTLERS" w_win  ON w_win."id" = nm."winner_id"
JOIN WWE.WWE."WRESTLERS" w_lose ON w_lose."id" = nm."loser_id"
ORDER BY nm."seconds" ASC NULLS LAST   -- shortest match first
LIMIT 1;