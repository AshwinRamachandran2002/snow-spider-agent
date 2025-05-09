WITH "nxt_belts" AS (   -- all belts whose name contains 'NXT'
    SELECT "id"
    FROM WWE.WWE.BELTS
    WHERE "name" ILIKE '%NXT%'
),
"nxt_matches" AS (      -- all NON-title-change matches for those belts
    SELECT
        m."id",
        m."winner_id"::NUMBER  AS "winner_id",
        m."loser_id" ::NUMBER  AS "loser_id",
        m."duration",
        /* convert duration text to total seconds */
        CASE
            WHEN m."duration" IS NULL OR TRIM(m."duration") = '' THEN NULL
            WHEN REGEXP_COUNT(m."duration", ':') = 2 THEN        -- HH:MM:SS
                 SPLIT_PART(m."duration", ':',1)::INT * 3600 +
                 SPLIT_PART(m."duration", ':',2)::INT *  60 +
                 SPLIT_PART(m."duration", ':',3)::INT
            WHEN REGEXP_COUNT(m."duration", ':') = 1 THEN        -- MM:SS
                 SPLIT_PART(m."duration", ':',1)::INT *  60 +
                 SPLIT_PART(m."duration", ':',2)::INT
            ELSE NULL
        END AS "seconds"
    FROM WWE.WWE.MATCHES m
    JOIN "nxt_belts" b
      ON m."title_id" = b."id"::TEXT
    WHERE m."title_change" = 0
),
"shortest_match" AS (   -- the single shortest-duration match
    SELECT *
    FROM "nxt_matches"
    WHERE "seconds" IS NOT NULL
    ORDER BY "seconds" ASC NULLS LAST
    LIMIT 1
)
SELECT
    w1."name" AS "wrestler_1",
    w2."name" AS "wrestler_2"
FROM "shortest_match" sm
JOIN WWE.WWE.WRESTLERS w1 ON w1."id" = sm."winner_id"
JOIN WWE.WWE.WRESTLERS w2 ON w2."id" = sm."loser_id";