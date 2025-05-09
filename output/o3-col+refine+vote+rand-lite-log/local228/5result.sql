WITH batter_totals AS (
    SELECT
        m.season_id,
        bb.striker                    AS player_id,
        p.player_name,
        SUM(bs.runs_scored)           AS total_runs
    FROM batsman_scored   bs
    JOIN ball_by_ball     bb ON  bb.match_id = bs.match_id
                            AND bb.over_id  = bs.over_id
                            AND bb.ball_id  = bs.ball_id
    JOIN match            m  ON m.match_id  = bs.match_id
    JOIN player           p  ON p.player_id = bb.striker
    GROUP BY m.season_id, bb.striker
),
batter_rank AS (
    SELECT
        season_id,
        player_id,
        player_name,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_runs DESC, player_id) AS rk
    FROM batter_totals
),
bowler_totals AS (
    SELECT
        m.season_id,
        bb.bowler                   AS player_id,
        p.player_name,
        COUNT(*)                    AS total_wkts
    FROM wicket_taken     wt
    JOIN ball_by_ball     bb ON  bb.match_id = wt.match_id
                            AND bb.over_id  = wt.over_id
                            AND bb.ball_id  = wt.ball_id
    JOIN match            m  ON m.match_id  = wt.match_id
    JOIN player           p  ON p.player_id = bb.bowler
    WHERE wt.kind_out NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
bowler_rank AS (
    SELECT
        season_id,
        player_id,
        player_name,
        total_wkts,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_wkts DESC, player_id) AS rk
    FROM bowler_totals
)
SELECT
    br.season_id,
    br.rk                       AS position,
    br.player_id                AS batsman_id,
    br.player_name              AS batsman_name,
    br.total_runs,
    bw.player_id                AS bowler_id,
    bw.player_name              AS bowler_name,
    bw.total_wkts
FROM batter_rank br
JOIN bowler_rank bw
  ON bw.season_id = br.season_id
 AND bw.rk        = br.rk
WHERE br.rk <= 3
ORDER BY br.season_id, br.rk;