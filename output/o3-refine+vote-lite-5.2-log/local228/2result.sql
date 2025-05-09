WITH season_runs AS (          -- total runs by every batsman in a season
    SELECT  m.season_id,
            bb.striker              AS player_id,
            SUM(bs.runs_scored)     AS total_runs
    FROM    batsman_scored  bs
    JOIN    ball_by_ball    bb
           ON bs.match_id   = bb.match_id
          AND bs.over_id    = bb.over_id
          AND bs.ball_id    = bb.ball_id
          AND bs.innings_no = bb.innings_no
    JOIN    match           m
           ON m.match_id    = bs.match_id
    GROUP BY m.season_id, bb.striker
),
ranked_batsmen AS (           -- rank batsmen, break ties with smaller id
    SELECT  season_id,
            player_id,
            total_runs,
            ROW_NUMBER() OVER (PARTITION BY season_id
                               ORDER BY total_runs DESC, player_id ASC) AS rnk
    FROM    season_runs
),
season_wkts AS (              -- wicket count for every bowler in a season
    SELECT  m.season_id,
            bb.bowler            AS player_id,
            COUNT(*)             AS total_wkts
    FROM    wicket_taken  w
    JOIN    ball_by_ball  bb
           ON w.match_id   = bb.match_id
          AND w.over_id    = bb.over_id
          AND w.ball_id    = bb.ball_id
          AND w.innings_no = bb.innings_no
    JOIN    match         m
           ON m.match_id   = w.match_id
    WHERE   LOWER(w.kind_out) NOT IN ('run out','hit wicket','retired hurt')
    GROUP BY m.season_id, bb.bowler
),
ranked_bowlers AS (           -- rank bowlers, break ties with smaller id
    SELECT  season_id,
            player_id,
            total_wkts,
            ROW_NUMBER() OVER (PARTITION BY season_id
                               ORDER BY total_wkts DESC, player_id ASC) AS rnk
    FROM    season_wkts
),
top_bats  AS (SELECT * FROM ranked_batsmen WHERE rnk <= 3),
top_bowls AS (SELECT * FROM ranked_bowlers WHERE rnk <= 3)

SELECT  s.season_id,
        tb.player_id            AS batsman_id,
        pb.player_name          AS batsman_name,
        tb.total_runs,
        bl.player_id            AS bowler_id,
        pl.player_name          AS bowler_name,
        bl.total_wkts
FROM   (SELECT DISTINCT season_id FROM match) s
JOIN    top_bats  tb  ON tb.season_id = s.season_id
JOIN    top_bowls bl  ON bl.season_id = s.season_id
                     AND bl.rnk       = tb.rnk      -- match 1 with 1, 2 with 2, 3 with 3
LEFT JOIN player pb  ON pb.player_id = tb.player_id
LEFT JOIN player pl  ON pl.player_id = bl.player_id
ORDER BY s.season_id, tb.rnk;