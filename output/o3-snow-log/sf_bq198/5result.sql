WITH "SEASON_MAX" AS (  -- 1.  max-wins for every season 1900-2000
    SELECT
        "season",
        MAX("wins") AS "max_wins"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS
    WHERE "season" BETWEEN 1900 AND 2000
    GROUP BY "season"
),
"PEAK_TEAMS" AS (       -- 2.  teams that reached the season’s max wins
    SELECT DISTINCT
        hts."market",          -- university / school name
        hts."season"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS hts
    JOIN "SEASON_MAX" sm
      ON  hts."season" = sm."season"
      AND hts."wins"   = sm."max_wins"
    WHERE hts."market" IS NOT NULL       -- exclude missing team names
      AND hts."name"   IS NOT NULL
)
-- 3.  count how many times each university hit peak wins & show top 5
SELECT
    "market"                             AS "UNIVERSITY",
    COUNT(*)                             AS "PEAK_PERFORMANCE_SEASONS"
FROM "PEAK_TEAMS"
GROUP BY "market"
ORDER BY "PEAK_PERFORMANCE_SEASONS" DESC NULLS LAST,
         "UNIVERSITY"
LIMIT 5;