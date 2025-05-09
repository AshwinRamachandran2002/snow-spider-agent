WITH partnership AS (          -- runs scored by every unordered batting pair
    SELECT  b."match_id",
            CASE WHEN b."striker" > b."non_striker" 
                 THEN b."striker" ELSE b."non_striker" END AS p1,
            CASE WHEN b."striker" > b."non_striker" 
                 THEN b."non_striker" ELSE b."striker" END AS p2,
            SUM(s."runs_scored")                                    AS partnership_runs
    FROM    "ball_by_ball"  b
    JOIN    "batsman_scored" s
           ON b."match_id"  = s."match_id"
          AND b."over_id"   = s."over_id"
          AND b."ball_id"   = s."ball_id"
          AND b."innings_no"= s."innings_no"
    GROUP BY b."match_id", p1, p2
),
max_partnership AS (           -- highest partnership runs per match
    SELECT  "match_id",
            MAX(partnership_runs) AS max_runs
    FROM    partnership
    GROUP BY "match_id"
),
top_pair AS (                  -- keep only the partnership(s) that are the highest in each match
    SELECT  p."match_id",
            p.p1      AS bat1,
            p.p2      AS bat2,
            p.partnership_runs
    FROM    partnership p
    JOIN    max_partnership m
          ON p."match_id"        = m."match_id"
         AND p.partnership_runs  = m.max_runs
),
indiv AS (                     -- individual total runs in each match
    SELECT  b."match_id",
            b."striker"               AS player_id,
            SUM(s."runs_scored")      AS runs
    FROM    "ball_by_ball"  b
    JOIN    "batsman_scored" s
           ON b."match_id"  = s."match_id"
          AND b."over_id"   = s."over_id"
          AND b."ball_id"   = s."ball_id"
          AND b."innings_no"= s."innings_no"
    GROUP BY b."match_id", b."striker"
)
SELECT  tp."match_id",
        CASE                                         -- decide player-1
             WHEN i1.runs > i2.runs                       THEN tp.bat1
             WHEN i1.runs < i2.runs                       THEN tp.bat2
             WHEN i1.runs = i2.runs AND tp.bat1 > tp.bat2 THEN tp.bat1
             ELSE                                             tp.bat2
        END                                        AS player1_id,
        CASE
             WHEN i1.runs > i2.runs                       THEN i1.runs
             WHEN i1.runs < i2.runs                       THEN i2.runs
             WHEN i1.runs = i2.runs AND tp.bat1 > tp.bat2 THEN i1.runs
             ELSE                                             i2.runs
        END                                        AS player1_runs,
        CASE                                         -- player-2 is the other batsman
             WHEN i1.runs > i2.runs                       THEN tp.bat2
             WHEN i1.runs < i2.runs                       THEN tp.bat1
             WHEN i1.runs = i2.runs AND tp.bat1 > tp.bat2 THEN tp.bat2
             ELSE                                             tp.bat1
        END                                        AS player2_id,
        CASE
             WHEN i1.runs > i2.runs                       THEN i2.runs
             WHEN i1.runs < i2.runs                       THEN i1.runs
             WHEN i1.runs = i2.runs AND tp.bat1 > tp.bat2 THEN i2.runs
             ELSE                                             i1.runs
        END                                        AS player2_runs,
        tp.partnership_runs
FROM    top_pair tp
JOIN    indiv    i1  ON tp."match_id" = i1."match_id" AND tp.bat1 = i1.player_id
JOIN    indiv    i2  ON tp."match_id" = i2."match_id" AND tp.bat2 = i2.player_id
ORDER BY tp."match_id", player1_id DESC, player2_id DESC;