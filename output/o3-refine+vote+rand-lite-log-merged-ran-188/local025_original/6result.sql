WITH
-- 1. Put every run from both the batsman_scored and extra_runs tables in one pile
runs_union AS (       
    SELECT match_id,
           innings_no,
           over_id,
           runs_scored AS runs
    FROM   batsman_scored
    UNION ALL
    SELECT match_id,
           innings_no,
           over_id,
           extra_runs AS runs
    FROM   extra_runs
),

-- 2. Aggregate those runs so we have one total per (match, innings, over)
over_runs AS (
    SELECT match_id,
           innings_no,
           over_id,
           SUM(runs) AS total_runs
    FROM   runs_union
    GROUP  BY match_id, innings_no, over_id
),

-- 3. Grab the bowler for each over (all six balls of an over are bowled by the same person;
--    MIN(bowler) is therefore a safe, simple pick)
over_bowler AS (
    SELECT match_id,
           innings_no,
           over_id,
           MIN(bowler) AS bowler_id          -- should be one value per over
    FROM   ball_by_ball
    GROUP  BY match_id, innings_no, over_id
),

-- 4. Join runs and bowler so every over has both pieces of information
over_stats AS (
    SELECT r.match_id,
           r.innings_no,
           r.over_id,
           r.total_runs,
           b.bowler_id
    FROM   over_runs  r
    JOIN   over_bowler b
      ON   r.match_id  = b.match_id
     AND   r.innings_no = b.innings_no
     AND   r.over_id    = b.over_id
),

-- 5. Within each match pick the *single* over that produced the most runs
max_over_per_match AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY match_id
                              ORDER BY total_runs DESC,
                                       innings_no,
                                       over_id) AS rn
    FROM   over_stats
),

-- 6. Keep only that top‐scoring over per match and attach the bowler’s name
top_overs AS (
    SELECT m.match_id,
           m.innings_no,
           m.over_id,
           m.total_runs,
           m.bowler_id,
           p.player_name AS bowler_name
    FROM   max_over_per_match m
    JOIN   player p
      ON   p.player_id = m.bowler_id
    WHERE  m.rn = 1
)

-- 7. Present every match’s top over plus the overall average of those
SELECT match_id,
       innings_no,
       over_id,
       bowler_id,
       bowler_name,
       total_runs             AS highest_over_runs,
       ROUND(AVG(total_runs) OVER (), 4)  -- average of *all* matches’ highest overs
           AS avg_highest_over_runs_across_matches
FROM   top_overs
ORDER  BY match_id;