/*  Fewest–wins team per league (all seasons)
    – counts every match where a team scores more goals than its opponent
    – includes teams that never win (0 wins)
    – if several teams tie for the fewest wins, keeps the one with the
      lowest team_api_id (ROW_NUMBER())                                   */

WITH league_teams AS (       -- every team that ever played in the league
    SELECT DISTINCT "league_id", "home_team_api_id"  AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    WHERE  "home_team_api_id" IS NOT NULL

    UNION

    SELECT DISTINCT "league_id", "away_team_api_id"  AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    WHERE  "away_team_api_id" IS NOT NULL
),

wins AS (                    -- winner of every decided match
    SELECT  "league_id",
            CASE
                WHEN "home_team_goal" > "away_team_goal" THEN "home_team_api_id"
                WHEN "away_team_goal" > "home_team_goal" THEN "away_team_api_id"
            END                             AS "winner_team_api_id"
    FROM    EU_SOCCER.EU_SOCCER.MATCH
    WHERE   "home_team_goal" IS NOT NULL
      AND   "away_team_goal" IS NOT NULL
      AND   "home_team_goal" <> "away_team_goal"          -- exclude draws
),

win_counts AS (              -- total wins per team & league
    SELECT  "league_id",
            "winner_team_api_id" AS "team_api_id",
            COUNT(*)             AS wins
    FROM    wins
    WHERE   "winner_team_api_id" IS NOT NULL
    GROUP BY "league_id", "winner_team_api_id"
),

team_wins AS (               -- attach zero for teams with no wins
    SELECT  lt."league_id",
            lt."team_api_id",
            COALESCE(wc.wins, 0) AS wins
    FROM    league_teams lt
    LEFT JOIN win_counts wc
           ON lt."league_id" = wc."league_id"
          AND lt."team_api_id" = wc."team_api_id"
),

fewest_per_league AS (       -- keep one (lowest team_api_id) if tied
    SELECT  tw.*,
            ROW_NUMBER() OVER (PARTITION BY tw."league_id"
                               ORDER BY tw.wins, tw."team_api_id") AS rn
    FROM    team_wins tw
    QUALIFY tw.wins = MIN(tw.wins) OVER (PARTITION BY tw."league_id")
)

SELECT  l."id"            AS league_id,
        l."name"          AS league_name,
        t."team_api_id",
        t."team_long_name",
        f.wins
FROM    fewest_per_league f
JOIN    EU_SOCCER.EU_SOCCER.LEAGUE l
       ON f."league_id" = l."id"
LEFT JOIN EU_SOCCER.EU_SOCCER.TEAM  t
       ON f."team_api_id" = t."team_api_id"
WHERE   f.rn = 1                   -- one team per league
ORDER BY l."id";