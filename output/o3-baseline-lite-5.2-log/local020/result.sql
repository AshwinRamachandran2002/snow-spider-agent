WITH deliveries AS (
    SELECT  bb.bowler                              AS player_id,
            COALESCE(bs.runs_scored,0)             AS runs_off_bat,
            COALESCE(er.extra_runs,0)              AS extra_runs
    FROM   ball_by_ball       bb
    LEFT JOIN batsman_scored  bs ON  bb.match_id  = bs.match_id
                                AND bb.over_id   = bs.over_id
                                AND bb.ball_id   = bs.ball_id
                                AND bb.innings_no= bs.innings_no
    LEFT JOIN extra_runs      er ON  bb.match_id  = er.match_id
                                AND bb.over_id   = er.over_id
                                AND bb.ball_id   = er.ball_id
                                AND bb.innings_no= er.innings_no
), bowler_runs AS (
    SELECT  player_id,
            SUM(runs_off_bat + extra_runs) AS runs_conceded
    FROM    deliveries
    GROUP BY player_id
), bowler_wkts AS (
    SELECT  bb.bowler  AS player_id,
            COUNT(*)   AS wickets
    FROM    wicket_taken wt
    JOIN    ball_by_ball bb ON  bb.match_id   = wt.match_id
                           AND bb.over_id    = wt.over_id
                           AND bb.ball_id    = wt.ball_id
                           AND bb.innings_no = wt.innings_no
    WHERE   wt.kind_out <> 'run out'          -- only wickets credited to bowler
    GROUP BY bb.bowler
), bowler_avg AS (
    SELECT  br.player_id,
            br.runs_conceded * 1.0 / bw.wickets AS bowling_average
    FROM    bowler_runs  br
    JOIN    bowler_wkts  bw USING (player_id)
    WHERE   bw.wickets > 0                      -- avoid division by zero
)
SELECT  p.player_name
FROM    bowler_avg ba
JOIN    player p ON p.player_id = ba.player_id
ORDER BY ba.bowling_average ASC
LIMIT 1;