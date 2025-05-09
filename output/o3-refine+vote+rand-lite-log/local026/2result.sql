WITH ball_runs AS (
    /* Runs scored off every ball (batsman runs + extras) together with the bowler */
    SELECT
        bb.match_id,
        bb.innings_no,
        bb.over_id,
        bb.bowler,
        bs.runs_scored                             AS bat_runs,
        COALESCE(er.extra_runs,0)                  AS extra_runs
    FROM ball_by_ball       bb
    JOIN batsman_scored     bs ON  bb.match_id = bs.match_id
                              AND bb.innings_no = bs.innings_no
                              AND bb.over_id   = bs.over_id
                              AND bb.ball_id   = bs.ball_id
    LEFT JOIN extra_runs    er ON  bb.match_id = er.match_id
                              AND bb.innings_no = er.innings_no
                              AND bb.over_id   = er.over_id
                              AND bb.ball_id   = er.ball_id
),
/* Aggregate to runs conceded in every over (we assume the same bowler bowls the whole over) */
over_runs AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        MIN(bowler)                                       AS bowler,       -- one bowler per over
        SUM(bat_runs + extra_runs)                        AS runs_conceded
    FROM ball_runs
    GROUP BY match_id, innings_no, over_id
),
/* Maximum‑run over in every match */
max_over_per_match AS (
    SELECT
        match_id,
        MAX(runs_conceded)                                AS max_runs
    FROM over_runs
    GROUP BY match_id
),
/* Keep only those overs that are the max‑run over for their match */
selected_overs AS (
    SELECT
        o.match_id,
        o.bowler,
        o.runs_conceded
    FROM over_runs o
    JOIN max_over_per_match m
         ON o.match_id = m.match_id
        AND o.runs_conceded = m.max_runs
)
/* Top 3 bowlers who conceded the most runs in such overs */
SELECT
    p.player_name         AS bowler_name,
    s.match_id,
    s.runs_conceded
FROM selected_overs s
JOIN player p ON p.player_id = s.bowler
ORDER BY
    s.runs_conceded DESC,      -- highest runs first
    p.player_name
LIMIT 3;