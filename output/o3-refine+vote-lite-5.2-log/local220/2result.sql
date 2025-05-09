WITH all_player_matches AS (
    -- 11 home players
    SELECT id AS match_id, home_team_goal AS goals_for, away_team_goal AS goals_against, home_player_1  AS player_id FROM Match WHERE home_player_1  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_2  FROM Match WHERE home_player_2  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_3  FROM Match WHERE home_player_3  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_4  FROM Match WHERE home_player_4  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_5  FROM Match WHERE home_player_5  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_6  FROM Match WHERE home_player_6  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_7  FROM Match WHERE home_player_7  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_8  FROM Match WHERE home_player_8  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_9  FROM Match WHERE home_player_9  IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_10 FROM Match WHERE home_player_10 IS NOT NULL
    UNION ALL SELECT id, home_team_goal, away_team_goal, home_player_11 FROM Match WHERE home_player_11 IS NOT NULL
    
    -- 11 away players (goals swapped)
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_1  FROM Match WHERE away_player_1  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_2  FROM Match WHERE away_player_2  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_3  FROM Match WHERE away_player_3  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_4  FROM Match WHERE away_player_4  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_5  FROM Match WHERE away_player_5  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_6  FROM Match WHERE away_player_6  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_7  FROM Match WHERE away_player_7  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_8  FROM Match WHERE away_player_8  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_9  FROM Match WHERE away_player_9  IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_10 FROM Match WHERE away_player_10 IS NOT NULL
    UNION ALL SELECT id, away_team_goal, home_team_goal, away_player_11 FROM Match WHERE away_player_11 IS NOT NULL
),
player_results AS (
    SELECT
        player_id,
        CASE WHEN goals_for > goals_against THEN 'win' ELSE 'loss' END AS result
    FROM all_player_matches
    WHERE goals_for <> goals_against          -- exclude draws
),
player_counts AS (
    SELECT
        player_id,
        SUM(CASE WHEN result = 'win'  THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN result = 'loss' THEN 1 ELSE 0 END) AS losses
    FROM player_results
    GROUP BY player_id
),
max_win AS (
    SELECT player_id, wins
    FROM player_counts
    WHERE wins = (SELECT MAX(wins) FROM player_counts)
),
max_loss AS (
    SELECT player_id, losses
    FROM player_counts
    WHERE losses = (SELECT MAX(losses) FROM player_counts)
)
SELECT 'most_wins'  AS category, p.player_name, mw.wins  AS match_count
FROM max_win  mw
JOIN Player p ON p.player_api_id = mw.player_id

UNION ALL

SELECT 'most_losses', p.player_name, ml.losses AS match_count
FROM max_loss ml
JOIN Player p ON p.player_api_id = ml.player_id

ORDER BY category, player_name;