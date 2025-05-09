WITH per_over_totals AS (
    SELECT bs.match_id, bs.innings_no, bs.over_id,
           SUM(bs.runs_scored + IFNULL(er.extra_runs, 0)) AS total_runs_per_over
    FROM batsman_scored bs
    LEFT JOIN extra_runs er
      ON bs.match_id = er.match_id 
         AND bs.innings_no = er.innings_no 
         AND bs.over_id = er.over_id 
         AND bs.ball_id = er.ball_id
    GROUP BY bs.match_id, bs.innings_no, bs.over_id
),
max_per_innings AS (
    SELECT match_id, innings_no,
           MAX(total_runs_per_over) AS max_total_runs
    FROM per_over_totals
    GROUP BY match_id, innings_no
),
highest_over_with_bowler AS (
    SELECT pot.match_id, pot.innings_no, pot.over_id, pot.total_runs_per_over, bb.bowler
    FROM per_over_totals pot
    JOIN max_per_innings mpi
      ON pot.match_id = mpi.match_id 
         AND pot.innings_no = mpi.innings_no 
         AND pot.total_runs_per_over = mpi.max_total_runs
    JOIN (
        SELECT match_id, innings_no, over_id, bowler
        FROM ball_by_ball
        WHERE ball_id = 1
    ) bb
      ON pot.match_id = bb.match_id 
         AND pot.innings_no = bb.innings_no 
         AND pot.over_id = bb.over_id
)
SELECT ROUND(AVG(total_runs_per_over), 4) AS average_highest_over_total
FROM highest_over_with_bowler;