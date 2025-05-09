WITH season_max AS (
    SELECT
        "season",
        MAX("wins") AS max_wins
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS
    WHERE "season" BETWEEN 1900 AND 2000
    GROUP BY "season"
),
peak_seasons AS (
    SELECT
        hts."market",          -- university / school name
        hts."season"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS hts
    JOIN season_max sm
      ON  hts."season" = sm."season"
     AND hts."wins"    = sm.max_wins            -- achieved season-high wins
    WHERE hts."season" BETWEEN 1900 AND 2000
      AND hts."name"   IS NOT NULL              -- exclude missing team names
      AND hts."market" IS NOT NULL              -- exclude missing universities
),
team_counts AS (
    SELECT
        "market" AS university,
        COUNT(DISTINCT "season") AS peak_season_count
    FROM peak_seasons
    GROUP BY "market"
)
SELECT
    university,
    peak_season_count
FROM team_counts
ORDER BY peak_season_count DESC NULLS LAST, university
LIMIT 5;