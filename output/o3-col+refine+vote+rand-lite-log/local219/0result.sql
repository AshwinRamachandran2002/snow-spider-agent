WITH all_matches AS (
    SELECT
        "league_id",
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN "home_team_api_id"
            WHEN "away_team_goal" > "home_team_goal" THEN "away_team_api_id"
        END                               AS "winner_team_api_id",
        "home_team_api_id"                AS "team_api_id"
    FROM "Match"

    UNION ALL

    SELECT
        "league_id",
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN "home_team_api_id"
            WHEN "away_team_goal" > "home_team_goal" THEN "away_team_api_id"
        END                               AS "winner_team_api_id",
        "away_team_api_id"                AS "team_api_id"
    FROM "Match"
),
teams_per_league AS (          -- every team that ever played in each league
    SELECT DISTINCT "league_id", "team_api_id"
    FROM all_matches
),
wins_per_team AS (             -- count wins (ignore draws)
    SELECT  "league_id",
            "winner_team_api_id" AS "team_api_id",
            COUNT(*)             AS "wins"
    FROM    all_matches
    WHERE   "winner_team_api_id" IS NOT NULL
    GROUP BY "league_id", "winner_team_api_id"
),
team_wins AS (                 -- attach 0 wins where necessary
    SELECT  tpl."league_id",
            tpl."team_api_id",
            COALESCE(wpt."wins",0) AS "wins"
    FROM    teams_per_league tpl
    LEFT JOIN wins_per_team  wpt
           ON tpl."league_id"  = wpt."league_id"
          AND tpl."team_api_id" = wpt."team_api_id"
),
min_wins AS (                  -- fewest wins per league
    SELECT "league_id", MIN("wins") AS "min_wins"
    FROM   team_wins
    GROUP BY "league_id"
),
fewest_wins AS (               -- the teams that have that minimum
    SELECT tw."league_id",
           tw."team_api_id",
           tw."wins"
    FROM   team_wins tw
    JOIN   min_wins  mw
      ON   tw."league_id" = mw."league_id"
     AND   tw."wins"      = mw."min_wins"
),
one_team AS (                  -- break ties by smallest team_api_id
    SELECT "league_id",
           MIN("team_api_id") AS "team_api_id"
    FROM   fewest_wins
    GROUP BY "league_id"
)
SELECT  lg."name"           AS "league_name",
        tm."team_long_name" AS "team_with_fewest_wins",
        fw."wins"           AS "total_wins"
FROM    one_team     ot
JOIN    fewest_wins  fw  ON fw."league_id" = ot."league_id"
                        AND fw."team_api_id" = ot."team_api_id"
JOIN    "League"     lg  ON lg."id"         = ot."league_id"
JOIN    "Team"       tm  ON tm."team_api_id"= ot."team_api_id"
ORDER BY lg."name";