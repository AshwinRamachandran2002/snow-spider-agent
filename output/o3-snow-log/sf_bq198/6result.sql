WITH "season_max" AS (
    SELECT 
        "season",
        MAX("wins") AS "max_wins"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS
    WHERE "season" BETWEEN 1900 AND 2000
    GROUP BY "season"
),
"peak_teams" AS (
    SELECT 
        t."market",
        t."season"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS t
    JOIN "season_max" m
      ON t."season" = m."season"
     AND t."wins"   = m."max_wins"
    WHERE t."market" IS NOT NULL
)
SELECT 
    "market"                                   AS "university",
    COUNT(DISTINCT "season")                   AS "peak_performance_seasons"
FROM "peak_teams"
GROUP BY "market"
ORDER BY "peak_performance_seasons" DESC NULLS LAST, "university"
LIMIT 5;