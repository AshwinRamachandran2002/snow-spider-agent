WITH nxt_matches AS (
    SELECT
        M."id"                                                AS match_id,
        /* convert duration text to total seconds */
        CASE 
            WHEN REGEXP_COUNT(M."duration", ':') = 2 THEN
                 (SPLIT_PART(M."duration", ':', 1))::INT * 3600 +
                 (SPLIT_PART(M."duration", ':', 2))::INT * 60   +
                 (SPLIT_PART(M."duration", ':', 3))::INT
            ELSE
                 (SPLIT_PART(M."duration", ':', 1))::INT * 60   +
                 (SPLIT_PART(M."duration", ':', 2))::INT
        END                                                   AS dur_seconds,
        M."winner_id",
        M."loser_id"
    FROM WWE.WWE.MATCHES  M
    JOIN WWE.WWE.BELTS   B
         ON B."id" = M."title_id"::INT
    WHERE UPPER(B."name") LIKE '%NXT%'         -- only NXT titles
      AND M."title_change" = 0                 -- exclude matches with a title change
      AND M."duration" IS NOT NULL
      AND M."duration" <> ''
)
SELECT
    W1."name" AS winner_name,
    W2."name" AS loser_name
FROM nxt_matches NM
LEFT JOIN WWE.WWE.WRESTLERS W1 ON W1."id" = NM."winner_id"::INT
LEFT JOIN WWE.WWE.WRESTLERS W2 ON W2."id" = NM."loser_id"::INT
ORDER BY NM.dur_seconds ASC NULLS LAST
LIMIT 1;