/*  Total wickets (excluding run-outs, retired-hurt, etc.), economy rate,
    strike rate and best bowling figure for every bowler               */

WITH per_ball AS (   -- one row per delivery for every bowler
    SELECT
        b."bowler",
        b."match_id",
        COALESCE(bs."runs_scored",0)                                         AS "runs_scored",
        CASE
            WHEN w."kind_out" IS NOT NULL
                 AND w."kind_out" NOT ILIKE '%run out%'
                 AND w."kind_out" NOT ILIKE '%retired%'
                 AND w."kind_out" NOT ILIKE '%obstructing%'
            THEN 1                                                          -- wicket credited
            ELSE 0
        END                                                                 AS "is_wicket"
    FROM IPL.IPL."BALL_BY_BALL"      b
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON bs."match_id"   = b."match_id"
          AND bs."innings_no" = b."innings_no"
          AND bs."over_id"    = b."over_id"
          AND bs."ball_id"    = b."ball_id"
    LEFT JOIN IPL.IPL."WICKET_TAKEN"  w
           ON w."match_id"   = b."match_id"
          AND w."innings_no" = b."innings_no"
          AND w."over_id"    = b."over_id"
          AND w."ball_id"    = b."ball_id"
),

overall AS (        -- career aggregates for every bowler
    SELECT
        "bowler",
        COUNT(*)                                    AS "balls_bowled",
        SUM("runs_scored")                          AS "runs_conceded",
        SUM("is_wicket")                            AS "wickets"
    FROM per_ball
    GROUP BY "bowler"
),

per_match AS (      -- wicket / run tally for each bowler-match
    SELECT
        "bowler",
        "match_id",
        SUM("is_wicket")                            AS "wkts_in_match",
        SUM("runs_scored")                          AS "runs_in_match"
    FROM per_ball
    GROUP BY "bowler","match_id"
),

best_match AS (     -- pick best match: most wkts, then fewest runs
    SELECT
        "bowler",
        CONCAT("wkts_in_match",'-',"runs_in_match") AS "best_bowling"
    FROM (
        SELECT
            "bowler",
            "match_id",
            "wkts_in_match",
            "runs_in_match",
            ROW_NUMBER() OVER (PARTITION BY "bowler"
                               ORDER BY "wkts_in_match" DESC,
                                        "runs_in_match" ASC) AS rn
        FROM per_match
    )
    WHERE rn = 1
)

SELECT
    o."bowler",
    o."wickets",
    ROUND( (o."runs_conceded" * 6) / NULLIF(o."balls_bowled",0) , 2) AS "economy_rate",
    ROUND( o."balls_bowled" / NULLIF(o."wickets",0) , 2)            AS "strike_rate",
    b."best_bowling"
FROM overall o
LEFT JOIN best_match b USING ("bowler")
ORDER BY o."wickets" DESC NULLS LAST;