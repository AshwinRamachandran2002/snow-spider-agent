SELECT
    t.team_long_name      AS team_name,
    w.wins
FROM (
        /* collect every winning appearance, home or away */
        SELECT team_id, COUNT(*) AS wins
        FROM (
                 SELECT home_team_api_id AS team_id
                 FROM   "Match"
                 WHERE  home_team_goal > away_team_goal

                 UNION ALL

                 SELECT away_team_api_id
                 FROM   "Match"
                 WHERE  away_team_goal > home_team_goal
             ) AS win_list
        GROUP BY team_id
     ) AS w
JOIN "Team" AS t
  ON t.team_api_id = w.team_id
ORDER BY w.wins DESC,
         t.team_long_name ASC
LIMIT 10;