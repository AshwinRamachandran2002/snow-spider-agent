WITH player_matches AS (
    /* total matches each player took part in */
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS matches_played
    FROM player_match
    GROUP BY player_id
),
player_runs AS (
    /* total runs each player scored (need ball‑by‑ball to know the striker) */
    SELECT
        bb.striker AS player_id,
        SUM(bs.runs_scored) AS runs_scored
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bb
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.striker
),
player_avg AS (
    /* individual batting average: runs per match */
    SELECT
        pl.player_id,
        pl.country_name,
        COALESCE(runs_scored, 0) * 1.0 / matches_played AS avg_runs_per_match
    FROM player AS pl
    JOIN player_matches AS pm
      ON pm.player_id = pl.player_id
    LEFT JOIN player_runs AS pr
      ON pr.player_id = pl.player_id
),
country_avg AS (
    /* average of player averages for every country */
    SELECT
        country_name,
        AVG(avg_runs_per_match) AS country_batting_avg
    FROM player_avg
    GROUP BY country_name
)
SELECT
    country_name,
    ROUND(country_batting_avg, 4) AS country_batting_avg
FROM country_avg
ORDER BY country_batting_avg DESC, country_name
LIMIT 5;