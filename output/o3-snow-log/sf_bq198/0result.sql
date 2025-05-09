WITH season_max AS (
    SELECT
        "market",
        "season",
        "wins",
        MAX("wins") OVER (PARTITION BY "season") AS "max_wins_season"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS
    WHERE
        "season" BETWEEN 1900 AND 2000
        AND "market" IS NOT NULL            -- exclude entries with missing university names
        AND "wins"   IS NOT NULL            -- ensure win totals are present
)
SELECT
    "market" AS "university",
    COUNT(DISTINCT "season") AS "peak_performance_seasons"
FROM season_max
WHERE "wins" = "max_wins_season"          -- keep teams that hit the season-high wins
GROUP BY "market"
ORDER BY "peak_performance_seasons" DESC NULLS LAST
LIMIT 5;