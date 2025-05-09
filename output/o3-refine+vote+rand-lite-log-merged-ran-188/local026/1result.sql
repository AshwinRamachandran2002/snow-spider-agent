WITH bat AS (
    /* runs scored off the bat per delivery */
    SELECT match_id,
           innings_no,
           over_id,
           ball_id,
           SUM(runs_scored) AS bat_runs
    FROM batsman_scored
    GROUP BY match_id, innings_no, over_id, ball_id
),
ext AS (
    /* extra runs per delivery (wides, no‑balls, byes, leg‑byes, …) */
    SELECT match_id,
           innings_no,
           over_id,
           ball_id,
           SUM(extra_runs) AS extra_runs
    FROM extra_runs
    GROUP BY match_id, innings_no, over_id, ball_id
),
deliveries AS (
    /* every delivery with total runs conceded (bat + extras) */
    SELECT b.match_id,
           b.innings_no,
           b.over_id,
           b.bowler,
           COALESCE(bat.bat_runs,0) + COALESCE(ext.extra_runs,0) AS runs_in_ball
    FROM ball_by_ball b
    LEFT JOIN bat  ON bat.match_id  = b.match_id
                  AND bat.innings_no = b.innings_no
                  AND bat.over_id    = b.over_id
                  AND bat.ball_id    = b.ball_id
    LEFT JOIN ext  ON ext.match_id  = b.match_id
                  AND ext.innings_no = b.innings_no
                  AND ext.over_id    = b.over_id
                  AND ext.ball_id    = b.ball_id
),
over_runs AS (
    /* total runs conceded in each over by its bowler */
    SELECT match_id,
           innings_no,
           over_id,
           bowler,
           SUM(runs_in_ball) AS runs_in_over
    FROM deliveries
    GROUP BY match_id, innings_no, over_id, bowler
),
max_over_per_match AS (
    /* what was the highest–run over in every match? */
    SELECT match_id,
           MAX(runs_in_over) AS max_runs_in_match
    FROM over_runs
    GROUP BY match_id
),
match_max_overs AS (
    /* keep only the overs that were equal to that match maximum */
    SELECT o.*
    FROM over_runs o
    JOIN max_over_per_match m
      ON m.match_id = o.match_id
     AND m.max_runs_in_match = o.runs_in_over
),
top3 AS (
    /* top three of those overs across all matches */
    SELECT mm.bowler,
           p.player_name,
           mm.match_id,
           mm.runs_in_over
    FROM match_max_overs mm
    JOIN player p
      ON p.player_id = mm.bowler
    ORDER BY mm.runs_in_over DESC, mm.match_id, mm.bowler
    LIMIT 3
)
SELECT player_name         AS bowler_name,
       match_id,
       runs_in_over        AS runs_conceded_in_over
FROM top3;