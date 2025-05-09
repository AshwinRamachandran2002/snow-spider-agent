WITH ball_runs AS (
    /* runs scored off every ball (batsman + extras) */
    SELECT
        b.match_id,
        b.innings_no,
        b.over_id,
        b.bowler,
        COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0) AS run_in_ball
    FROM ball_by_ball  b
    LEFT JOIN batsman_scored bs
           ON  b.match_id = bs.match_id
           AND b.innings_no = bs.innings_no
           AND b.over_id  = bs.over_id
           AND b.ball_id  = bs.ball_id
    LEFT JOIN extra_runs  er
           ON  b.match_id = er.match_id
           AND b.innings_no = er.innings_no
           AND b.over_id  = er.over_id
           AND b.ball_id  = er.ball_id
),
over_runs AS (
    /* total runs conceded by a bowler in one over (over = match+innings+over_id) */
    SELECT
        match_id,
        innings_no,
        over_id,
        bowler,
        SUM(run_in_ball) AS runs_conceded
    FROM ball_runs
    GROUP BY match_id, innings_no, over_id, bowler
),
max_over_per_match AS (
    /* what was the costliest over in every match? */
    SELECT
        match_id,
        MAX(runs_conceded) AS max_runs
    FROM over_runs
    GROUP BY match_id
),
overs_with_max AS (
    /* keep only those costliest overs */
    SELECT o.*
    FROM over_runs o
    JOIN max_over_per_match m
      ON o.match_id = m.match_id
     AND o.runs_conceded = m.max_runs
),
bowler_worst AS (
    /* for every bowler, find his single ‑worst‑ over (among the overs kept above) */
    SELECT
        bowler        AS player_id,
        MAX(runs_conceded) AS worst_runs
    FROM overs_with_max
    GROUP BY bowler
),
bowler_worst_match AS (
    /* tie‑breaker: if the bowler had two such overs with the same runs, keep the earliest match */
    SELECT
        o.bowler      AS player_id,
        MIN(o.match_id) AS match_id,
        o.runs_conceded
    FROM overs_with_max o
    JOIN bowler_worst bw
         ON o.bowler = bw.player_id
        AND o.runs_conceded = bw.worst_runs
    GROUP BY o.bowler, o.runs_conceded
),
top_bowlers AS (
    /* finally get the three worst (i.e., most expensive) overs */
    SELECT *
    FROM bowler_worst_match
    ORDER BY runs_conceded DESC, player_id
    LIMIT 3
)
SELECT
    p.player_name   AS bowler_name,
    t.match_id,
    t.runs_conceded
FROM top_bowlers t
JOIN player p ON p.player_id = t.player_id
ORDER BY t.runs_conceded DESC, bowler_name;