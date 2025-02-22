-- Task: Find the given names of baseball players along with their total games played, runs, hits, and home runs. Show only the first 100 results.
WITH total_stats AS (
    SELECT 
        player_id, 
        SUM(TRY_TO_NUMERIC(g)) AS total_games,
        SUM(TRY_TO_NUMERIC(r)) AS total_runs,
        SUM(TRY_TO_NUMERIC(h)) AS total_hits,
        SUM(TRY_TO_NUMERIC(hr)) AS total_hr
    FROM BASEBALL.BASEBALL.BATTING
    GROUP BY player_id
),
top_players AS (
    SELECT 
        ts.player_id,
        ts.total_games,
        ts.total_runs,
        ts.total_hits,
        ts.total_hr,
        p.name_given
    FROM total_stats ts
    INNER JOIN BASEBALL.BASEBALL.PLAYER p ON ts.player_id = p.player_id
)
SELECT name_given, total_games, total_runs, total_hits, total_hr
FROM top_players
LIMIT 100;