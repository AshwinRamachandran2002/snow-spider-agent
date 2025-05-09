/*  Bowler-wise overall wickets, economy-rate, strike-rate
    and best match figures (“wickets-runs”, extras ignored)  */
WITH "balls_runs" AS (      -- total balls & runs (off the bat) conceded
    SELECT
        bb."bowler",
        COUNT(*)                          AS "balls_bowled",
        COALESCE(SUM(bs."runs_scored"),0) AS "runs_conceded"
    FROM IPL.IPL.BALL_BY_BALL bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"  = bs."match_id"
          AND bb."innings_no" = bs."innings_no"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
    GROUP BY bb."bowler"
),
"wickets" AS (             -- bowler-credited wickets (exclude run-outs etc.)
    SELECT
        bb."bowler",
        COUNT(*) AS "wickets"
    FROM IPL.IPL.WICKET_TAKEN wt
    JOIN IPL.IPL.BALL_BY_BALL bb
          ON  wt."match_id"  = bb."match_id"
         AND wt."innings_no" = bb."innings_no"
         AND wt."over_id"    = bb."over_id"
         AND wt."ball_id"    = bb."ball_id"
    WHERE wt."kind_out" NOT IN ('run out', 'retired hurt', 'obstructing the field')
    GROUP BY bb."bowler"
),
"per_match" AS (           -- per-match runs & wickets for every bowler
    SELECT
        bb."bowler",
        bb."match_id",
        COALESCE(SUM(bs."runs_scored"),0) AS "runs_conceded",
        SUM(
            CASE
                WHEN wt."kind_out" NOT IN ('run out', 'retired hurt', 'obstructing the field')
                THEN 1 ELSE 0
            END)                           AS "wickets"
    FROM IPL.IPL.BALL_BY_BALL bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"  = bs."match_id"
          AND bb."innings_no" = bs."innings_no"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL.WICKET_TAKEN wt
           ON  wt."match_id"  = bb."match_id"
          AND wt."innings_no" = bb."innings_no"
          AND wt."over_id"    = bb."over_id"
          AND wt."ball_id"    = bb."ball_id"
    GROUP BY bb."bowler", bb."match_id"
),
"best_match_ranked" AS (   -- rank matches per bowler (most wkts, then fewest runs)
    SELECT
        "bowler",
        "match_id",
        "runs_conceded",
        "wickets",
        ROW_NUMBER() OVER (PARTITION BY "bowler"
                           ORDER BY "wickets" DESC,
                                    "runs_conceded" ASC) AS "rnk"
    FROM "per_match"
),
"best_figures" AS (        -- best figures string “wickets-runs”
    SELECT
        "bowler",
        /* cast to string to avoid numeric concatenation */
        (CAST("wickets" AS STRING) || '-' || CAST("runs_conceded" AS STRING)) AS "best_bowling"
    FROM "best_match_ranked"
    WHERE "rnk" = 1
)
SELECT
    br."bowler"                                   AS "bowler_id",
    p."player_name",
    COALESCE(w."wickets",0)                       AS "total_wickets",
    ROUND( (br."runs_conceded"*6.0) / NULLIF(br."balls_bowled",0) , 4) AS "economy_rate",
    ROUND( br."balls_bowled" / NULLIF(w."wickets",0) , 4)              AS "strike_rate",
    bf."best_bowling"
FROM "balls_runs"      br
LEFT JOIN "wickets"    w  ON br."bowler" = w."bowler"
LEFT JOIN "best_figures" bf ON br."bowler" = bf."bowler"
LEFT JOIN IPL.IPL.PLAYER  p ON br."bowler" = p."player_id"
ORDER BY "total_wickets" DESC NULLS LAST,
         "economy_rate"  ASC  NULLS LAST;