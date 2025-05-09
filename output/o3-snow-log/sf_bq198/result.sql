WITH season_stats AS (
    SELECT 
        S."season",
        S."wins",
        S."team_id",
        COALESCE(S."market", T."market") AS "team_market"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TEAMS_SEASONS"  S
    LEFT JOIN NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_TEAMS"                T
           ON S."team_id" = T."id"
    WHERE S."season" BETWEEN 1900 AND 2000
),
season_max AS (
    SELECT 
        "season",
        MAX("wins") AS "max_wins"
    FROM season_stats
    GROUP BY "season"
),
peak_teams AS (
    SELECT 
        ss."team_market",
        ss."season"
    FROM season_stats ss
    JOIN season_max sm
      ON ss."season" = sm."season"
     AND ss."wins"   = sm."max_wins"
    WHERE ss."team_market" IS NOT NULL
),
team_peak_counts AS (
    SELECT 
        "team_market",
        COUNT(*) AS "peak_seasons"
    FROM peak_teams
    GROUP BY "team_market"
)
SELECT 
    "team_market"   AS "university",
    "peak_seasons"  AS "num_peak_seasons"
FROM team_peak_counts
ORDER BY "peak_seasons" DESC NULLS LAST, "university"
LIMIT 5;