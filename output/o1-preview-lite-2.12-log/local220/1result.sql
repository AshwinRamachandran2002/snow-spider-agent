SELECT 
    p.player_api_id AS Player_ID, 
    p.player_name AS Player_Name, 
    pw.win_count AS Number_of_Wins
FROM (
    SELECT player_id, COUNT(*) AS win_count
    FROM (
        SELECT home_player_1 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_2 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_3 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_4 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_5 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_6 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_7 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_8 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_9 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_10 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT home_player_11 AS player_id FROM Match WHERE home_team_goal > away_team_goal UNION ALL
        SELECT away_player_1 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_2 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_3 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_4 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_5 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_6 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_7 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_8 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_9 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_10 AS player_id FROM Match WHERE away_team_goal > home_team_goal UNION ALL
        SELECT away_player_11 AS player_id FROM Match WHERE away_team_goal > home_team_goal
    ) AS WinningPlayers
    WHERE player_id IS NOT NULL
    GROUP BY player_id
) AS pw
JOIN Player p ON p.player_api_id = pw.player_id
ORDER BY pw.win_count DESC
LIMIT 1;