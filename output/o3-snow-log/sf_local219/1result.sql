WITH
/* every team that ever appeared in a match of a given league              */
teams_in_league AS (
    SELECT "league_id",
           "home_team_api_id"  AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    WHERE  "home_team_api_id" IS NOT NULL

    UNION            -- UNION (not ALL) to avoid duplicates
    SELECT "league_id",
           "away_team_api_id"  AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    WHERE  "away_team_api_id" IS NOT NULL
),

/* one row per win (home or away)                                          */
wins_raw AS (
    /* home-side wins */
    SELECT "league_id",
           "home_team_api_id"  AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    WHERE  "home_team_goal" > "away_team_goal"
      AND  "home_team_api_id" IS NOT NULL

    UNION ALL

    /* away-side wins */
    SELECT "league_id",
           "away_team_api_id"  AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    WHERE  "away_team_goal" > "home_team_goal"
      AND  "away_team_api_id" IS NOT NULL
),

/* aggregate win counts per (league, team)                                 */
wins AS (
    SELECT "league_id",
           "team_api_id",
           COUNT(*) AS "win_count"
    FROM   wins_raw
    GROUP  BY "league_id", "team_api_id"
),

/* attach a zero for the teams that never won                              */
team_wins AS (
    SELECT til."league_id",
           til."team_api_id",
           COALESCE(w."win_count", 0) AS "win_count"
    FROM   teams_in_league til
    LEFT  JOIN wins        w
           ON  til."league_id"  = w."league_id"
           AND til."team_api_id"= w."team_api_id"
),

/* minimum wins per league                                                 */
min_wins AS (
    SELECT "league_id",
           MIN("win_count") AS "min_win_count"
    FROM   team_wins
    GROUP  BY "league_id"
),

/* keep only the (tied) teams with the fewest wins, then pick one via ROW_NUMBER */
fewest_win_teams AS (
    SELECT tw.*,
           ROW_NUMBER() OVER (PARTITION BY tw."league_id"
                              ORDER BY tw."team_api_id") AS rn
    FROM   team_wins tw
    JOIN   min_wins mw
           ON  tw."league_id" = mw."league_id"
           AND tw."win_count" = mw."min_win_count"
)

SELECT  l."id"            AS "league_id",
        l."name"          AS "league_name",
        t."team_api_id",
        t."team_long_name",
        fwt."win_count"   AS "fewest_wins_in_league"
FROM    fewest_win_teams  fwt
JOIN    EU_SOCCER.EU_SOCCER.LEAGUE l
        ON fwt."league_id" = l."id"
JOIN    EU_SOCCER.EU_SOCCER.TEAM   t
        ON fwt."team_api_id" = t."team_api_id"
WHERE   fwt.rn = 1                 -- choose a single team if there is a tie
ORDER BY l."id";