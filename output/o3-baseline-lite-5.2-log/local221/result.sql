WITH win_counts AS (
    -- home‑team wins
    SELECT home_team_api_id AS team_api_id
    FROM   Match
    WHERE  home_team_goal > away_team_goal
    
    UNION ALL
    
    -- away‑team wins
    SELECT away_team_api_id
    FROM   Match
    WHERE  away_team_goal > home_team_goal
)

SELECT
    t.team_long_name AS team_name,
    COUNT(*)         AS wins
FROM   win_counts wc
JOIN   Team t
  ON   wc.team_api_id = t.team_api_id
GROUP  BY wc.team_api_id
ORDER  BY wins DESC, team_name ASC
LIMIT 10;