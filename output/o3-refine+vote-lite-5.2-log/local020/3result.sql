WITH batsman_runs AS (
    SELECT match_id,
           over_id,
           ball_id,
           innings_no,
           runs_scored
    FROM batsman_scored
),
valid_extras AS (
    SELECT match_id,
           over_id,
           ball_id,
           innings_no,
           SUM(extra_runs) AS extra_runs
    FROM extra_runs
    -- Byes and leg‑byes are NOT charged to the bowler
    WHERE extra_type NOT IN ('legbyes','byes')
    GROUP BY match_id, over_id, ball_id, innings_no
),
ball_runs AS (
    SELECT bb.match_id,
           bb.over_id,
           bb.ball_id,
           bb.innings_no,
           bb.bowler,
           COALESCE(br.runs_scored,0) + COALESCE(ve.extra_runs,0) AS runs_conceded
    FROM ball_by_ball bb
    LEFT JOIN batsman_runs  br ON br.match_id = bb.match_id
                              AND br.over_id  = bb.over_id
                              AND br.ball_id  = bb.ball_id
                              AND br.innings_no = bb.innings_no
    LEFT JOIN valid_extras  ve ON ve.match_id = bb.match_id
                              AND ve.over_id  = bb.over_id
                              AND ve.ball_id  = bb.ball_id
                              AND ve.innings_no = bb.innings_no
),
bowler_runs AS (
    SELECT bowler AS player_id,
           SUM(runs_conceded) AS total_runs
    FROM ball_runs
    GROUP BY bowler
),
bowler_wkts AS (
    SELECT bb.bowler  AS player_id,
           COUNT(*)   AS wickets
    FROM wicket_taken  wk
    JOIN ball_by_ball bb
         ON bb.match_id  = wk.match_id
        AND bb.over_id   = wk.over_id
        AND bb.ball_id   = wk.ball_id
        AND bb.innings_no= wk.innings_no
    -- Run‑outs (and similar) are not credited to the bowler
    WHERE wk.kind_out <> 'run out'
    GROUP BY bb.bowler
),
bowler_stats AS (
    SELECT br.player_id,
           br.total_runs,
           bw.wickets,
           CAST(br.total_runs AS REAL) / bw.wickets AS bowling_average
    FROM bowler_runs br
    JOIN bowler_wkts bw ON bw.player_id = br.player_id
    WHERE bw.wickets > 0
)
SELECT p.player_name,
       bs.bowling_average
FROM bowler_stats bs
JOIN player p ON p.player_id = bs.player_id
ORDER BY bs.bowling_average ASC,
         p.player_name
LIMIT 1;