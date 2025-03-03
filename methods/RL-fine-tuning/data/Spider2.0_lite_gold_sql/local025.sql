WITH total_runs_per_ball AS (
    SELECT bs.match_id, bs.innings_no, bs.over_id, bs.ball_id,
           bs.runs_scored + IFNULL(er.extra_runs, 0) AS total_runs
    FROM batsman_scored AS bs
    LEFT JOIN extra_runs AS er
      ON bs.match_id = er.match_id
     AND bs.innings_no = er.innings_no
     AND bs.over_id = er.over_id
     AND bs.ball_id = er.ball_id
),
over_runs AS (
    SELECT match_id, innings_no, over_id,
           SUM(total_runs) AS total_runs
    FROM total_runs_per_ball
    GROUP BY match_id, innings_no, over_id
),
highest_over_per_match AS (
    SELECT match_id, innings_no, over_id, total_runs
    FROM (
        SELECT match_id, innings_no, over_id, total_runs,
               ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY total_runs DESC, over_id) AS rn
        FROM over_runs
    ) sub
    WHERE rn = 1
),
over_bowlers AS (
    SELECT match_id, innings_no, over_id, bowler
    FROM (
        SELECT match_id, innings_no, over_id, bowler,
               ROW_NUMBER() OVER (PARTITION BY match_id, innings_no, over_id ORDER BY ball_id) AS rn
        FROM ball_by_ball
    ) sub
    WHERE rn = 1
),
highest_over_with_bowler AS (
    SELECT h.match_id, h.innings_no, h.over_id, h.total_runs, ob.bowler
    FROM highest_over_per_match AS h
    JOIN over_bowlers AS ob
      ON h.match_id = ob.match_id
     AND h.innings_no = ob.innings_no
     AND h.over_id = ob.over_id
)
SELECT AVG(total_runs) AS average_highest_over_total
FROM highest_over_with_bowler;