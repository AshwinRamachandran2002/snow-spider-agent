WITH winning_players AS (
    SELECT m."home_player_1" AS player_id
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_1" IS NOT NULL
    UNION ALL
    SELECT m."home_player_2"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_2" IS NOT NULL
    UNION ALL
    SELECT m."home_player_3"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_3" IS NOT NULL
    UNION ALL
    SELECT m."home_player_4"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_4" IS NOT NULL
    UNION ALL
    SELECT m."home_player_5"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_5" IS NOT NULL
    UNION ALL
    SELECT m."home_player_6"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_6" IS NOT NULL
    UNION ALL
    SELECT m."home_player_7"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_7" IS NOT NULL
    UNION ALL
    SELECT m."home_player_8"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_8" IS NOT NULL
    UNION ALL
    SELECT m."home_player_9"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_9" IS NOT NULL
    UNION ALL
    SELECT m."home_player_10"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_10" IS NOT NULL
    UNION ALL
    SELECT m."home_player_11"
    FROM "Match" m
    WHERE m."home_team_goal" > m."away_team_goal" AND m."home_player_11" IS NOT NULL
    UNION ALL
    SELECT m."away_player_1"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_1" IS NOT NULL
    UNION ALL
    SELECT m."away_player_2"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_2" IS NOT NULL
    UNION ALL
    SELECT m."away_player_3"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_3" IS NOT NULL
    UNION ALL
    SELECT m."away_player_4"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_4" IS NOT NULL
    UNION ALL
    SELECT m."away_player_5"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_5" IS NOT NULL
    UNION ALL
    SELECT m."away_player_6"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_6" IS NOT NULL
    UNION ALL
    SELECT m."away_player_7"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_7" IS NOT NULL
    UNION ALL
    SELECT m."away_player_8"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_8" IS NOT NULL
    UNION ALL
    SELECT m."away_player_9"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_9" IS NOT NULL
    UNION ALL
    SELECT m."away_player_10"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_10" IS NOT NULL
    UNION ALL
    SELECT m."away_player_11"
    FROM "Match" m
    WHERE m."away_team_goal" > m."home_team_goal" AND m."away_player_11" IS NOT NULL
)
SELECT 
    p."player_api_id" AS "Player_ID",
    p."player_name" AS "Player_Name",
    COUNT(*) AS "Number_of_Wins"
FROM 
    winning_players wp
JOIN
    "Player" p
ON wp.player_id = p."player_api_id"
GROUP BY
    p."player_api_id",
    p."player_name"
ORDER BY
    "Number_of_Wins" DESC
LIMIT 1;