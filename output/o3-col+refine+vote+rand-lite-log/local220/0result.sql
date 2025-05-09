WITH player_match_result AS (
    /* -------- home team players -------- */
    SELECT "home_player_1" AS player_api_id,
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END AS result
    FROM "Match" WHERE "home_player_1" IS NOT NULL
    UNION ALL SELECT "home_player_2",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_2" IS NOT NULL
    UNION ALL SELECT "home_player_3",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_3" IS NOT NULL
    UNION ALL SELECT "home_player_4",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_4" IS NOT NULL
    UNION ALL SELECT "home_player_5",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_5" IS NOT NULL
    UNION ALL SELECT "home_player_6",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_6" IS NOT NULL
    UNION ALL SELECT "home_player_7",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_7" IS NOT NULL
    UNION ALL SELECT "home_player_8",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_8" IS NOT NULL
    UNION ALL SELECT "home_player_9",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_9" IS NOT NULL
    UNION ALL SELECT "home_player_10",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_10" IS NOT NULL
    UNION ALL SELECT "home_player_11",
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'win'
                WHEN "home_team_goal" < "away_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "home_player_11" IS NOT NULL

    /* -------- away team players -------- */
    UNION ALL SELECT "away_player_1",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_1" IS NOT NULL
    UNION ALL SELECT "away_player_2",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_2" IS NOT NULL
    UNION ALL SELECT "away_player_3",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_3" IS NOT NULL
    UNION ALL SELECT "away_player_4",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_4" IS NOT NULL
    UNION ALL SELECT "away_player_5",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_5" IS NOT NULL
    UNION ALL SELECT "away_player_6",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_6" IS NOT NULL
    UNION ALL SELECT "away_player_7",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_7" IS NOT NULL
    UNION ALL SELECT "away_player_8",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_8" IS NOT NULL
    UNION ALL SELECT "away_player_9",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_9" IS NOT NULL
    UNION ALL SELECT "away_player_10",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_10" IS NOT NULL
    UNION ALL SELECT "away_player_11",
           CASE WHEN "away_team_goal" > "home_team_goal" THEN 'win'
                WHEN "away_team_goal" < "home_team_goal" THEN 'loss'
                ELSE 'draw' END
    FROM "Match" WHERE "away_player_11" IS NOT NULL
),
aggregate AS (
    SELECT player_api_id,
           SUM(result = 'win')  AS wins,
           SUM(result = 'loss') AS losses
    FROM   player_match_result
    WHERE  result <> 'draw'          -- ignore draws
    GROUP  BY player_api_id
),
most_wins  AS (SELECT player_api_id, wins   AS matches FROM aggregate ORDER BY wins   DESC LIMIT 1),
most_loss  AS (SELECT player_api_id, losses AS matches FROM aggregate ORDER BY losses DESC LIMIT 1)

SELECT 'Most Wins'  AS category,
       p."player_name",
       mw.matches
FROM   most_wins mw
JOIN   "Player" p ON p."player_api_id" = mw.player_api_id

UNION ALL

SELECT 'Most Losses',
       p."player_name",
       ml.matches
FROM   most_loss ml
JOIN   "Player" p ON p."player_api_id" = ml.player_api_id;