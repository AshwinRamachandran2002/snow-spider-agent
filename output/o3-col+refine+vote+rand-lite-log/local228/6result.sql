WITH run_totals AS (          -- total runs per batsman per season
    SELECT  m.season_id,
            bb.striker                     AS player_id,
            SUM(bs.runs_scored)            AS total_runs
    FROM    batsman_scored  bs
    JOIN    ball_by_ball    bb  ON  bs.match_id = bb.match_id
                               AND bs.over_id  = bb.over_id
                               AND bs.ball_id  = bb.ball_id
    JOIN    match           m   ON  m.match_id = bs.match_id
    GROUP BY m.season_id, bb.striker
),
run_ranked AS (               -- rank batsmen, tie-break on smaller player_id
    SELECT  season_id,
            player_id,
            total_runs,
            ROW_NUMBER() OVER (
                PARTITION BY season_id
                ORDER BY total_runs DESC, player_id
            )                 AS pos
    FROM    run_totals
),
wkt_totals AS (               -- valid wickets per bowler per season
    SELECT  m.season_id,
            bb.bowler                     AS player_id,
            COUNT(*)                      AS total_wkts
    FROM    wicket_taken   wt
    JOIN    ball_by_ball   bb  ON  wt.match_id = bb.match_id
                               AND wt.over_id  = bb.over_id
                               AND wt.ball_id  = bb.ball_id
    JOIN    match          m   ON  m.match_id  = wt.match_id
    WHERE   wt.kind_out NOT IN ('run out','hit wicket','retired hurt')
    GROUP BY m.season_id, bb.bowler
),
wkt_ranked AS (               -- rank bowlers, tie-break on smaller player_id
    SELECT  season_id,
            player_id,
            total_wkts,
            ROW_NUMBER() OVER (
                PARTITION BY season_id
                ORDER BY total_wkts DESC, player_id
            )                 AS pos
    FROM    wkt_totals
),
paired AS (                   -- pair positions 1-3 of batsmen & bowlers
    SELECT  r.season_id,
            r.pos                         AS position,
            pb.player_name                AS batsman_name,
            r.total_runs,
            bw.player_name                AS bowler_name,
            w.total_wkts
    FROM    run_ranked  r
    JOIN    wkt_ranked w   ON r.season_id = w.season_id
                          AND r.pos       = w.pos
    JOIN    player     pb  ON pb.player_id = r.player_id
    JOIN    player     bw  ON bw.player_id = w.player_id
    WHERE   r.pos <= 3
)
SELECT  season_id,
        position,
        batsman_name,
        total_runs,
        bowler_name,
        total_wkts
FROM    paired
ORDER BY season_id, position;