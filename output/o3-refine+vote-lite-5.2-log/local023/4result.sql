WITH season_matches AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
player_runs_per_match AS (
    SELECT 
        b.striker                    AS player_id,
        bs.match_id,
        SUM(bs.runs_scored)          AS runs_in_match
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS b
         ON b.match_id   = bs.match_id
        AND b.over_id    = bs.over_id
        AND b.ball_id    = bs.ball_id
        AND b.innings_no = bs.innings_no
    JOIN season_matches AS sm
         ON sm.match_id = bs.match_id
    GROUP BY b.striker, bs.match_id
),
player_season_stats AS (
    SELECT
        player_id,
        SUM(runs_in_match)                       AS total_runs,
        COUNT(DISTINCT match_id)                 AS matches_played,
        1.0 * SUM(runs_in_match) / COUNT(DISTINCT match_id)  AS avg_runs_per_match
    FROM player_runs_per_match
    GROUP BY player_id
)
SELECT 
    p.player_name,
    ROUND(ps.avg_runs_per_match, 4) AS batting_average
FROM player_season_stats AS ps
JOIN player AS p
  ON p.player_id = ps.player_id
ORDER BY 
    ps.avg_runs_per_match DESC,
    p.player_name ASC
LIMIT 5;