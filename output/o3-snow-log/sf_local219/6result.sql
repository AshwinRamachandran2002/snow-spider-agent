WITH
/* every (league, team) pair that appeared in at least one match */
team_league AS (
    SELECT DISTINCT
           "league_id"          AS LEAGUE_ID,
           "home_team_api_id"   AS TEAM_API_ID
    FROM EU_SOCCER.EU_SOCCER.MATCH
    UNION
    SELECT DISTINCT
           "league_id"          AS LEAGUE_ID,
           "away_team_api_id"   AS TEAM_API_ID
    FROM EU_SOCCER.EU_SOCCER.MATCH
),

/* wins by (league, team): count both home-side and away-side victories */
wins AS (
    SELECT
        LEAGUE_ID,
        TEAM_API_ID,
        COUNT(*) AS WINS
    FROM (
        /* home wins */
        SELECT
            "league_id"        AS LEAGUE_ID,
            "home_team_api_id" AS TEAM_API_ID
        FROM EU_SOCCER.EU_SOCCER.MATCH
        WHERE "home_team_goal" > "away_team_goal"
        UNION ALL
        /* away wins */
        SELECT
            "league_id"        AS LEAGUE_ID,
            "away_team_api_id" AS TEAM_API_ID
        FROM EU_SOCCER.EU_SOCCER.MATCH
        WHERE "away_team_goal" > "home_team_goal"
    )
    GROUP BY LEAGUE_ID, TEAM_API_ID
),

/* attach win counts (default 0) to every team in each league */
team_league_wins AS (
    SELECT
        tl.LEAGUE_ID,
        tl.TEAM_API_ID,
        COALESCE(w.WINS, 0) AS WINS
    FROM team_league tl
    LEFT JOIN wins w
           ON tl.LEAGUE_ID  = w.LEAGUE_ID
          AND tl.TEAM_API_ID = w.TEAM_API_ID
),

/* rank teams in each league by fewest wins, tie-broken by smallest TEAM_API_ID */
ranked AS (
    SELECT
        LEAGUE_ID,
        TEAM_API_ID,
        WINS,
        ROW_NUMBER() OVER (PARTITION BY LEAGUE_ID
                           ORDER BY WINS ASC, TEAM_API_ID ASC) AS RN
    FROM team_league_wins
)

/* pick the single team with the fewest wins in each league */
SELECT
    l."name"            AS league_name,
    t."team_long_name"  AS team_name,
    r.WINS              AS total_wins
FROM ranked r
JOIN EU_SOCCER.EU_SOCCER.LEAGUE l
  ON r.LEAGUE_ID = l."id"
JOIN EU_SOCCER.EU_SOCCER.TEAM t
  ON r.TEAM_API_ID = t."team_api_id"
WHERE r.RN = 1
ORDER BY l."id";