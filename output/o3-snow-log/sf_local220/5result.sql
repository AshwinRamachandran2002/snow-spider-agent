WITH unpivoted AS (          -- one row per (match , player) appearance
    SELECT
        "match_api_id",
        "home_team_goal",
        "away_team_goal",
        up."player_api_id"::NUMBER AS "player_api_id",
        up."pos"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    UNPIVOT ( "player_api_id" FOR "pos" IN (                -- list every player column
        "home_player_1","home_player_2","home_player_3","home_player_4","home_player_5",
        "home_player_6","home_player_7","home_player_8","home_player_9","home_player_10","home_player_11",
        "away_player_1","away_player_2","away_player_3","away_player_4","away_player_5",
        "away_player_6","away_player_7","away_player_8","away_player_9","away_player_10","away_player_11"
    )) up
    WHERE up."player_api_id" IS NOT NULL                 -- player actually appeared
      AND "home_team_goal" <> "away_team_goal"           -- exclude draws
),
player_outcome AS (        -- flag each appearance as win / loss
    SELECT
        "player_api_id",
        CASE
            WHEN ( "pos" ILIKE 'home%' AND "home_team_goal" > "away_team_goal")
              OR ( "pos" ILIKE 'away%' AND "home_team_goal" < "away_team_goal") THEN 1 ELSE 0
        END AS "is_win",
        CASE
            WHEN ( "pos" ILIKE 'home%' AND "home_team_goal" < "away_team_goal")
              OR ( "pos" ILIKE 'away%' AND "home_team_goal" > "away_team_goal") THEN 1 ELSE 0
        END AS "is_loss"
    FROM unpivoted
),
aggregated AS (            -- total wins / losses per player
    SELECT
        "player_api_id",
        SUM("is_win")  AS "wins",
        SUM("is_loss") AS "losses"
    FROM player_outcome
    GROUP BY "player_api_id"
),
top_winner AS (            -- player with most wins
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY "wins" DESC NULLS LAST, "player_api_id") AS rn
    FROM aggregated
),
top_loser AS (             -- player with most losses
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY "losses" DESC NULLS LAST, "player_api_id") AS rn
    FROM aggregated
)
-- final result: top winner and top loser
SELECT  p."player_name",
        w."wins"      AS "match_count",
        'MOST_WINS'   AS "category"
FROM    top_winner w
JOIN    EU_SOCCER.EU_SOCCER."PLAYER" p
        ON p."player_api_id" = w."player_api_id"
WHERE   w.rn = 1

UNION ALL

SELECT  p."player_name",
        l."losses"    AS "match_count",
        'MOST_LOSSES' AS "category"
FROM    top_loser l
JOIN    EU_SOCCER.EU_SOCCER."PLAYER" p
        ON p."player_api_id" = l."player_api_id"
WHERE   l.rn = 1;