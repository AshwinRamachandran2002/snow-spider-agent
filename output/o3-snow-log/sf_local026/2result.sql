/*-------------------------------------------------------------
STEP-1 : Runs conceded by every bowler in every over
--------------------------------------------------------------*/
WITH runs_per_over AS (  
    SELECT  
        b."match_id",  
        b."innings_no",  
        b."over_id",  
        b."bowler",  
        SUM( COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0) ) AS runs_conceded  
    FROM IPL.IPL.BALL_BY_BALL     b
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  b."match_id"  = bs."match_id"
           AND b."innings_no"= bs."innings_no"
           AND b."over_id"   = bs."over_id"
           AND b."ball_id"   = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS   er
           ON  b."match_id"  = er."match_id"
           AND b."innings_no"= er."innings_no"
           AND b."over_id"   = er."over_id"
           AND b."ball_id"   = er."ball_id"
    GROUP BY  
        b."match_id",
        b."innings_no",
        b."over_id",
        b."bowler"
),

/*-------------------------------------------------------------
STEP-2 : Maximum runs conceded in a single over for each match
--------------------------------------------------------------*/
match_max AS (
    SELECT  
        "match_id",
        MAX(runs_conceded) AS max_runs_in_match
    FROM runs_per_over
    GROUP BY "match_id"
),

/*-------------------------------------------------------------
STEP-3 : Overs that are that “worst” over of their match
--------------------------------------------------------------*/
worst_overs AS (
    SELECT  r.*
    FROM    runs_per_over r
    JOIN    match_max      m
      ON    r."match_id"    = m."match_id"
      AND   r.runs_conceded = m.max_runs_in_match
),

/*-------------------------------------------------------------
STEP-4 : For every bowler keep his single worst over
--------------------------------------------------------------*/
bowler_worst AS (
    SELECT  
        r."bowler", 
        r."match_id",
        r.runs_conceded,
        ROW_NUMBER() OVER (PARTITION BY r."bowler" 
                           ORDER BY r.runs_conceded DESC, r."match_id") AS rn
    FROM worst_overs r
),

/*-------------------------------------------------------------
STEP-5 : Pick top-3 bowlers overall on that metric
--------------------------------------------------------------*/
top3 AS (
    SELECT *
    FROM   bowler_worst
    WHERE  rn = 1
    ORDER BY runs_conceded DESC NULLS LAST
    LIMIT 3
)

/*-------------------------------------------------------------
FINAL OUTPUT
--------------------------------------------------------------*/
SELECT  
    p."player_name"               AS bowler_name,
    t."match_id",
    t.runs_conceded
FROM   top3 t
JOIN   IPL.IPL.PLAYER p
  ON   p."player_id" = t."bowler"
ORDER BY t.runs_conceded DESC NULLS LAST;