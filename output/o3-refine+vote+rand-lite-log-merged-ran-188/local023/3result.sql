WITH season_matches AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
player_matches AS (               -- every player who took part in a season‑5 match
    SELECT pm.player_id,
           pm.match_id
    FROM player_match pm
    JOIN season_matches sm
      ON sm.match_id = pm.match_id
    GROUP BY pm.player_id, pm.match_id
),
player_runs AS (                  -- runs each player scored in each season‑5 match
    SELECT bb.striker AS player_id,
           bs.match_id,
           SUM(bs.runs_scored) AS runs
    FROM batsman_scored bs
    JOIN ball_by_ball bb
         ON bb.match_id  = bs.match_id
        AND bb.over_id   = bs.over_id
        AND bb.ball_id   = bs.ball_id
        AND bb.innings_no = bs.innings_no
    JOIN season_matches sm
      ON sm.match_id = bs.match_id
    GROUP BY bb.striker, bs.match_id
),
aggregated AS (                   -- matches played and total runs for every player
    SELECT pm.player_id,
           COUNT(DISTINCT pm.match_id)      AS matches_played,
           COALESCE(SUM(pr.runs), 0)        AS total_runs
    FROM player_matches pm
    LEFT JOIN player_runs pr
           ON pr.player_id = pm.player_id
          AND pr.match_id  = pm.match_id
    GROUP BY pm.player_id
),
averages AS (                     -- average runs per match
    SELECT player_id,
           total_runs * 1.0 / matches_played AS avg_runs
    FROM aggregated
    WHERE matches_played > 0
)
SELECT p.player_name,
       ROUND(ag.avg_runs, 4) AS batting_average
FROM averages ag
JOIN player p
  ON p.player_id = ag.player_id
ORDER BY ag.avg_runs DESC,
         p.player_name
LIMIT 5;