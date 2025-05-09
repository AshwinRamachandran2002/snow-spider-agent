WITH agg AS (
    SELECT
        player_id,
        SUM(g)  AS total_games,
        SUM(r)  AS total_runs,
        SUM(h)  AS total_hits,
        SUM(hr) AS total_hr
    FROM batting
    GROUP BY player_id
),
max_vals AS (
    SELECT
        MAX(total_games) AS max_games,
        MAX(total_runs)  AS max_runs,
        MAX(total_hits)  AS max_hits,
        MAX(total_hr)    AS max_hr
    FROM agg
),
leaders AS (
      SELECT player_id, 'Games Played' AS stat, total_games AS value
      FROM agg, max_vals
      WHERE total_games = max_games
      
      UNION ALL
      
      SELECT player_id, 'Runs' AS stat, total_runs
      FROM agg, max_vals
      WHERE total_runs = max_runs
      
      UNION ALL
      
      SELECT player_id, 'Hits' AS stat, total_hits
      FROM agg, max_vals
      WHERE total_hits = max_hits
      
      UNION ALL
      
      SELECT player_id, 'Home Runs' AS stat, total_hr
      FROM agg, max_vals
      WHERE total_hr = max_hr
)
SELECT
    p.name_given        AS given_name,
    l.stat,
    l.value
FROM leaders l
JOIN player p
  ON p.player_id = l.player_id
ORDER BY l.stat;