WITH RUNS_PER_PLAYER_MATCH AS (           -- runs scored by every player in each match
    SELECT
        bbb."match_id",
        bbb."striker"                              AS "player_id",
        SUM(bs."runs_scored")                      AS "runs_scored"
    FROM IPL.IPL."BALL_BY_BALL"     bbb
    JOIN IPL.IPL."BATSMAN_SCORED"   bs
      ON  bbb."match_id"   = bs."match_id"
      AND bbb."innings_no" = bs."innings_no"
      AND bbb."over_id"    = bs."over_id"
      AND bbb."ball_id"    = bs."ball_id"
    GROUP BY
        bbb."match_id",
        bbb."striker"
),
PLAYER_MATCH_WITH_RUNS AS (            -- every appearance of a player, attaching 0 runs if he didn't score
    SELECT
        pm."player_id",
        pm."match_id",
        COALESCE(rpm."runs_scored", 0)             AS "runs_scored"
    FROM IPL.IPL."PLAYER_MATCH"  pm
    LEFT JOIN RUNS_PER_PLAYER_MATCH rpm
           ON pm."player_id" = rpm."player_id"
          AND pm."match_id"  = rpm."match_id"
),
PLAYER_AVG AS (                        -- each player’s average runs per match
    SELECT
        "player_id",
        SUM("runs_scored")                                   AS "total_runs",
        COUNT(DISTINCT "match_id")                           AS "matches_played",
        ( SUM("runs_scored")::DECIMAL(18,4) 
          / COUNT(DISTINCT "match_id") )                     AS "avg_runs_per_match"
    FROM PLAYER_MATCH_WITH_RUNS
    GROUP BY "player_id"
),
COUNTRY_AVG AS (                       -- country-level average of those player averages
    SELECT
        pl."country_name",
        AVG(p."avg_runs_per_match")     AS "country_batting_average"
    FROM PLAYER_AVG      p
    JOIN IPL.IPL."PLAYER" pl
      ON p."player_id" = pl."player_id"
    GROUP BY pl."country_name"
)
SELECT
    "country_name",
    ROUND("country_batting_average", 4) AS "country_batting_average"
FROM COUNTRY_AVG
ORDER BY "country_batting_average" DESC NULLS LAST
FETCH FIRST 5 ROWS;