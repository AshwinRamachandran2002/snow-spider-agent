/*  Player with the most wins  &  player with the most losses          */
/*  – Only appearances in NON-draw matches and NON-NULL line-up slots  */

WITH appearances AS (
       /* ---------------- home team ---------------- */
       SELECT (home_team_goal > away_team_goal) AS is_winner , home_player_1  AS player_id FROM Match WHERE home_player_1  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_2  FROM Match WHERE home_player_2  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_3  FROM Match WHERE home_player_3  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_4  FROM Match WHERE home_player_4  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_5  FROM Match WHERE home_player_5  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_6  FROM Match WHERE home_player_6  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_7  FROM Match WHERE home_player_7  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_8  FROM Match WHERE home_player_8  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_9  FROM Match WHERE home_player_9  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_10 FROM Match WHERE home_player_10 IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (home_team_goal > away_team_goal) ,               home_player_11 FROM Match WHERE home_player_11 IS NOT NULL AND home_team_goal <> away_team_goal
       /* ---------------- away team ---------------- */
       UNION ALL SELECT (away_team_goal > home_team_goal) ,      away_player_1  FROM Match WHERE away_player_1  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_2  FROM Match WHERE away_player_2  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_3  FROM Match WHERE away_player_3  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_4  FROM Match WHERE away_player_4  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_5  FROM Match WHERE away_player_5  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_6  FROM Match WHERE away_player_6  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_7  FROM Match WHERE away_player_7  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_8  FROM Match WHERE away_player_8  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_9  FROM Match WHERE away_player_9  IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_10 FROM Match WHERE away_player_10 IS NOT NULL AND home_team_goal <> away_team_goal UNION ALL
       SELECT (away_team_goal > home_team_goal) ,               away_player_11 FROM Match WHERE away_player_11 IS NOT NULL AND home_team_goal <> away_team_goal
),
agg AS (
       SELECT player_id,
              SUM(is_winner)           AS wins,
              SUM(1 - is_winner)       AS losses
       FROM   appearances
       GROUP  BY player_id
),
max_vals AS (
       SELECT MAX(wins)   AS max_wins,
              MAX(losses) AS max_losses
       FROM   agg
)
SELECT p.player_name,
       'most_wins'  AS metric,
       a.wins       AS total_matches
FROM   agg a
JOIN   max_vals m  ON a.wins   = m.max_wins
JOIN   Player  p   ON p.player_api_id = a.player_id

UNION ALL

SELECT p.player_name,
       'most_losses' AS metric,
       a.losses      AS total_matches
FROM   agg a
JOIN   max_vals m  ON a.losses = m.max_losses
JOIN   Player  p   ON p.player_api_id = a.player_id
ORDER  BY metric;