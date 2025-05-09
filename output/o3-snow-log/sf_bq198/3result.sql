WITH season_peak_wins AS (
    /* 1.  Maximum number of wins recorded by any team in each season (1900-2000) */
    SELECT
        "season",
        MAX("wins") AS max_wins
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TEAMS_SEASONS"
    WHERE "season" BETWEEN 1900 AND 2000
    GROUP BY "season"
),
teams_with_peak_wins AS (
    /* 2.  Teams that matched the season-high wins, excluding missing school names */
    SELECT
        hts."team_id",
        hts."market",               -- school / university name
        hts."season"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TEAMS_SEASONS" hts
    JOIN season_peak_wins spw
          ON hts."season" = spw."season"
         AND hts."wins"   = spw.max_wins
    WHERE hts."market" IS NOT NULL
      AND TRIM(hts."market") <> ''
)
SELECT
    "market"       AS university,
    COUNT(*)       AS peak_performance_seasons
FROM teams_with_peak_wins
GROUP BY "market"
ORDER BY peak_performance_seasons DESC NULLS LAST,
         university
LIMIT 5;