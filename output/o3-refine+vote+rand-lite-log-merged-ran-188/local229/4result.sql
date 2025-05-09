WITH per_ball AS (
    /* runs scored on every delivery */
    SELECT  bb.match_id,
            bb.striker,
            bb.non_striker,
            COALESCE(bs.runs_scored,0) AS bat_runs,
            COALESCE(er.extra_runs,0)  AS extra_runs
    FROM    ball_by_ball AS bb
    LEFT JOIN batsman_scored AS bs
           ON  bb.match_id   = bs.match_id
           AND bb.over_id    = bs.over_id
           AND bb.ball_id    = bs.ball_id
           AND bb.innings_no = bs.innings_no
    LEFT JOIN extra_runs AS er
           ON  bb.match_id   = er.match_id
           AND bb.over_id    = er.over_id
           AND bb.ball_id    = er.ball_id
           AND bb.innings_no = er.innings_no
),
pair_totals AS (
    /* aggregate to unordered batting pairs (higher id = p1) */
    SELECT  match_id,
            CASE WHEN striker > non_striker THEN striker ELSE non_striker END AS p1,
            CASE WHEN striker > non_striker THEN non_striker ELSE striker END AS p2,
            SUM(CASE WHEN striker =
                         CASE WHEN striker > non_striker THEN striker ELSE non_striker END
                     THEN bat_runs ELSE 0 END)                              AS p1_runs,
            SUM(CASE WHEN striker =
                         CASE WHEN striker > non_striker THEN non_striker ELSE striker END
                     THEN bat_runs ELSE 0 END)                              AS p2_runs,
            SUM(bat_runs + extra_runs)                                      AS partnership_runs
    FROM    per_ball
    GROUP   BY match_id, p1, p2
),
ranked AS (
    /* pick the maximum–run partnership(s) in every match */
    SELECT  pt.*,
            MAX(partnership_runs) OVER (PARTITION BY match_id) AS max_partnership
    FROM    pair_totals AS pt
),
ordered AS (
    /* enforce player-1 / player-2 ordering rule */
    SELECT  match_id,
            CASE
                 WHEN p1_runs >  p2_runs THEN p1
                 WHEN p1_runs <  p2_runs THEN p2
                 WHEN p1      >  p2      THEN p1 ELSE p2 END               AS player1_id,
            CASE
                 WHEN p1_runs >  p2_runs THEN p2
                 WHEN p1_runs <  p2_runs THEN p1
                 WHEN p1      >  p2      THEN p2 ELSE p1 END               AS player2_id,
            CASE
                 WHEN p1_runs >  p2_runs THEN p1_runs
                 WHEN p1_runs <  p2_runs THEN p2_runs
                 WHEN p1      >  p2      THEN p1_runs ELSE p2_runs END     AS player1_runs,
            CASE
                 WHEN p1_runs >  p2_runs THEN p2_runs
                 WHEN p1_runs <  p2_runs THEN p1_runs
                 WHEN p1      >  p2      THEN p2_runs ELSE p1_runs END     AS player2_runs,
            partnership_runs
    FROM    ranked
    WHERE   partnership_runs = max_partnership
)
SELECT  match_id,
        player1_id,
        player2_id,
        player1_runs,
        player2_runs,
        partnership_runs
FROM    ordered
ORDER BY match_id, player1_id DESC, player2_id DESC;