WITH all_runs AS (
    SELECT match_id,
           innings_no,
           over_id,
           runs_scored AS runs
    FROM batsman_scored
    UNION ALL
    SELECT match_id,
           innings_no,
           over_id,
           extra_runs AS runs
    FROM extra_runs
),
per_over AS (
    SELECT match_id,
           innings_no,
           over_id,
           SUM(runs) AS total_runs
    FROM all_runs
    GROUP BY match_id, innings_no, over_id
),
max_runs_per_match AS (
    SELECT match_id,
           MAX(total_runs) AS max_runs
    FROM per_over
    GROUP BY match_id
),
chosen_over AS (
    /* pick the earliest (innings_no, over_id) over if multiple tie on max_runs */
    SELECT p1.match_id,
           p1.innings_no,
           p1.over_id,
           p1.total_runs
    FROM per_over p1
    JOIN max_runs_per_match m
      ON p1.match_id = m.match_id
     AND p1.total_runs = m.max_runs
    LEFT JOIN per_over p2
      ON p1.match_id = p2.match_id
     AND p2.total_runs = m.max_runs
     AND (p2.innings_no < p1.innings_no
          OR (p2.innings_no = p1.innings_no AND p2.over_id < p1.over_id))
    WHERE p2.match_id IS NULL
),
chosen_over_bowler AS (
    SELECT co.match_id,
           co.total_runs,
           MIN(bb.bowler) AS bowler_id          -- one bowler per over; MIN() ensures single value
    FROM chosen_over co
    JOIN ball_by_ball bb
      ON co.match_id   = bb.match_id
     AND co.innings_no = bb.innings_no
     AND co.over_id    = bb.over_id
    GROUP BY co.match_id
)
SELECT ROUND(AVG(total_runs), 4) AS average_highest_over_runs
FROM chosen_over_bowler;