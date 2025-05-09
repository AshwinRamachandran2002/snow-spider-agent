/* --------------------------------------------------------------------
   In every league, find the single team (include teams with zero wins)
   that has the fewest total victories (home- or away-side wins) across
   all seasons.  If several teams tie for the fewest wins, keep only the
   one with the smallest team_api_id (ROW_NUMBER() handles the tie-break).
---------------------------------------------------------------------*/
WITH "all_teams" AS (          -- every team that ever appeared in a match
    SELECT DISTINCT "league_id",
           "home_team_api_id"  AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_api_id" IS NOT NULL

    UNION                     -- UNION (not ALL) to de-duplicate
     
    SELECT DISTINCT "league_id",
           "away_team_api_id"  AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_api_id" IS NOT NULL
),

"wins_raw" AS (               -- one row per win (home or away)
    /* home wins */
    SELECT "league_id",
           "home_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_goal" > "away_team_goal"
      AND "home_team_api_id" IS NOT NULL

    UNION ALL

    /* away wins */
    SELECT "league_id",
           "away_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_goal" > "home_team_goal"
      AND "away_team_api_id" IS NOT NULL
),

"win_counts" AS (             -- total wins per team & league
    SELECT "league_id",
           "team_api_id",
           COUNT(*) AS "wins"
    FROM "wins_raw"
    GROUP BY "league_id", "team_api_id"
),

"team_wins" AS (              -- attach zero for teams that never won
    SELECT a."league_id",
           a."team_api_id",
           COALESCE(w."wins", 0) AS "wins"
    FROM "all_teams"      a
    LEFT JOIN "win_counts" w
           ON a."league_id"   = w."league_id"
          AND a."team_api_id" = w."team_api_id"
),

"min_team_per_league" AS (    -- pick one team with fewest wins per league
    SELECT "league_id",
           "team_api_id",
           "wins",
           ROW_NUMBER() OVER (PARTITION BY "league_id"
                              ORDER BY "wins" ASC,
                                       "team_api_id" ASC) AS "rn"
    FROM "team_wins"
)

SELECT  l."name"            AS "league_name",
        t."team_long_name"  AS "team_name",
        m."wins"            AS "win_count"
FROM    "min_team_per_league" m
JOIN    EU_SOCCER.EU_SOCCER.LEAGUE l
           ON m."league_id" = l."id"
JOIN    EU_SOCCER.EU_SOCCER.TEAM   t
           ON m."team_api_id" = t."team_api_id"
WHERE   m."rn" = 1           -- keep only one (fewest-wins) team per league
ORDER BY l."name";