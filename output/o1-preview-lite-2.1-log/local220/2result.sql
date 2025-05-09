SELECT p."player_api_id" AS Player_ID, p."player_name" AS Player_Name, COUNT(*) AS Number_of_Wins
FROM (
    SELECT m."home_player_1" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_1" IS NOT NULL
    UNION ALL
    SELECT m."home_player_2" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_2" IS NOT NULL
    UNION ALL
    SELECT m."home_player_3" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_3" IS NOT NULL
    UNION ALL
    SELECT m."home_player_4" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_4" IS NOT NULL
    UNION ALL
    SELECT m."home_player_5" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_5" IS NOT NULL
    UNION ALL
    SELECT m."home_player_6" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_6" IS NOT NULL
    UNION ALL
    SELECT m."home_player_7" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_7" IS NOT NULL
    UNION ALL
    SELECT m."home_player_8" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_8" IS NOT NULL
    UNION ALL
    SELECT m."home_player_9" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_9" IS NOT NULL
    UNION ALL
    SELECT m."home_player_10" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_10" IS NOT NULL
    UNION ALL
    SELECT m."home_player_11" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_11" IS NOT NULL
    UNION ALL
    SELECT m."away_player_1" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_1" IS NOT NULL
    UNION ALL
    SELECT m."away_player_2" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_2" IS NOT NULL
    UNION ALL
    SELECT m."away_player_3" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_3" IS NOT NULL
    UNION ALL
    SELECT m."away_player_4" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_4" IS NOT NULL
    UNION ALL
    SELECT m."away_player_5" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_5" IS NOT NULL
    UNION ALL
    SELECT m."away_player_6" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_6" IS NOT NULL
    UNION ALL
    SELECT m."away_player_7" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_7" IS NOT NULL
    UNION ALL
    SELECT m."away_player_8" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_8" IS NOT NULL
    UNION ALL
    SELECT m."away_player_9" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_9" IS NOT NULL
    UNION ALL
    SELECT m."away_player_10" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_10" IS NOT NULL
    UNION ALL
    SELECT m."away_player_11" AS player_id
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_11" IS NOT NULL
) AS player_wins
JOIN "Player" p ON player_wins.player_id = p."player_api_id"
GROUP BY p."player_api_id", p."player_name"
ORDER BY Number_of_Wins DESC
LIMIT 1;