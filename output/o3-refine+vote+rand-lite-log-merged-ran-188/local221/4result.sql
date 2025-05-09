SELECT
    T.team_long_name        AS team_name,
    COUNT(*)                AS win_count
FROM
    (
        /* wins achieved by the home side */
        SELECT home_team_api_id AS team_api_id
        FROM   Match
        WHERE  home_team_goal IS NOT NULL
          AND  away_team_goal IS NOT NULL
          AND  home_team_goal > away_team_goal

        UNION ALL

        /* wins achieved by the away side */
        SELECT away_team_api_id
        FROM   Match
        WHERE  home_team_goal IS NOT NULL
          AND  away_team_goal IS NOT NULL
          AND  away_team_goal > home_team_goal
    ) AS W
JOIN Team AS T
  ON T.team_api_id = W.team_api_id
GROUP BY
    T.team_long_name
ORDER BY
    win_count DESC,
    T.team_long_name ASC
LIMIT 10;