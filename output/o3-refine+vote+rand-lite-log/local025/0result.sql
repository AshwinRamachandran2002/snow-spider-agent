WITH
/* 1. Put every run (by batsman or as an extra) in one list            */
all_runs AS (
    SELECT match_id,
           innings_no,
           over_id,
           runs_scored         AS runs
    FROM   batsman_scored
    
    UNION ALL
    
    SELECT match_id,
           innings_no,
           over_id,
           extra_runs          AS runs
    FROM   extra_runs
),

/* 2. Total runs made in every over of every innings of every match    */
over_totals AS (
    SELECT   match_id,
             innings_no,
             over_id,
             SUM(runs) AS total_runs
    FROM     all_runs
    GROUP BY match_id, innings_no, over_id
),

/* 3. Keep exactly one (the highest‑scoring) over per match            */
best_over AS (
    SELECT   match_id,
             innings_no,
             over_id,
             total_runs,
             ROW_NUMBER() OVER (PARTITION BY match_id
                                ORDER BY total_runs DESC,
                                         innings_no,
                                         over_id) AS rn
    FROM     over_totals
),
top_over_per_match AS (
    SELECT match_id,
           innings_no,
           over_id,
           total_runs
    FROM   best_over
    WHERE  rn = 1
),

/* 4. Find the bowler who delivered that over (there is only one bowler
       per over, MIN(bowler) is enough in case data repeat)            */
over_bowler AS (
    SELECT   match_id,
             innings_no,
             over_id,
             MIN(bowler) AS bowler_id
    FROM     ball_by_ball
    GROUP BY match_id, innings_no, over_id
),

/* 5. Attach bowler’s name                                             */
top_over_with_bowler AS (
    SELECT  t.match_id,
            t.innings_no,
            t.over_id,
            t.total_runs,
            ob.bowler_id,
            p.player_name AS bowler_name
    FROM    top_over_per_match t
    JOIN    over_bowler  ob
           ON  t.match_id   = ob.match_id
           AND t.innings_no = ob.innings_no
           AND t.over_id    = ob.over_id
    JOIN    player      p
           ON p.player_id   = ob.bowler_id
),

/* 6. Average of all “best‑over” run totals across every match         */
avg_best_over AS (
    SELECT AVG(total_runs) AS avg_highest_over_runs
    FROM   top_over_per_match
)

/* 7. Final output: for every match show its highest‑scoring over,
       the bowler, the run total, and (repeated for convenience)
       the overall average of those best‑over totals.                  */
SELECT  t.match_id,
        t.innings_no,
        t.over_id,
        t.bowler_id,
        t.bowler_name,
        t.total_runs         AS highest_over_runs_in_match,
        a.avg_highest_over_runs
FROM    top_over_with_bowler t
CROSS   JOIN avg_best_over   a
ORDER BY t.match_id;