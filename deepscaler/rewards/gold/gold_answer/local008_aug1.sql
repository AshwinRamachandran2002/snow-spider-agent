-- Task: I would like to know the given name(s) of baseball player(s) who have achieved the highest number of home runs, along with their total home runs.
WITH player_stats AS (
    SELECT
        b.player_id,
        p.name_given AS player_name,
        SUM(b.hr) AS home_runs
    FROM player p
    JOIN batting b ON p.player_id = b.player_id
    GROUP BY b.player_id, p.name_given
)
SELECT player_name, home_runs
FROM player_stats
WHERE home_runs = (SELECT MAX(home_runs) FROM player_stats);