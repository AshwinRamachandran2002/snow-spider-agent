WITH nxt_belts AS (
    SELECT "id"
    FROM WWE.WWE.BELTS
    WHERE LOWER("name") LIKE '%nxt%'          -- keep only NXT-related titles
),
nxt_matches AS (                               -- matches for those titles, ignoring title changes
    SELECT
        "id",
        "winner_id",
        "loser_id",
        "duration",
        CASE                                       -- convert duration text to seconds
             WHEN REGEXP_COUNT("duration", ':') = 2 THEN 
                  TO_NUMBER(SPLIT_PART("duration",':',1))*3600 +
                  TO_NUMBER(SPLIT_PART("duration",':',2))*60   +
                  TO_NUMBER(SPLIT_PART("duration",':',3))
             WHEN REGEXP_COUNT("duration", ':') = 1 THEN
                  TO_NUMBER(SPLIT_PART("duration",':',1))*60   +
                  TO_NUMBER(SPLIT_PART("duration",':',2))
             ELSE NULL
        END AS duration_seconds
    FROM WWE.WWE.MATCHES
    WHERE "title_id" IN (SELECT "id" FROM nxt_belts)
      AND "title_change" = 0                     -- exclude title-change bouts
      AND "duration" IS NOT NULL
      AND "duration" <> ''
),
shortest_match AS (                              -- pick the shortest such match
    SELECT *
    FROM nxt_matches
    WHERE duration_seconds IS NOT NULL
    QUALIFY duration_seconds = MIN(duration_seconds) OVER ()
)
SELECT
    w_win."name"  AS winner_name,
    w_lose."name" AS loser_name
FROM shortest_match sm
LEFT JOIN WWE.WWE.WRESTLERS w_win  ON w_win."id"  = TO_NUMBER(sm."winner_id")
LEFT JOIN WWE.WWE.WRESTLERS w_lose ON w_lose."id" = TO_NUMBER(sm."loser_id");