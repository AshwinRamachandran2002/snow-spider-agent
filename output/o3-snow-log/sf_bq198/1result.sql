WITH season_max_wins AS (
    /* 1.  Determine the maximum number of wins posted by any team in each season (1900-2000) */
    SELECT
        "season",
        MAX("wins") AS max_wins
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS
    WHERE "season" BETWEEN 1900 AND 2000
    GROUP BY "season"
),
peak_teams AS (
    /* 2.  Pick the team(s) that reached that seasonal maximum, excluding rows with missing names */
    SELECT
        t."market",          -- university / school
        t."season"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS t
    JOIN season_max_wins m
          ON t."season" = m."season"
         AND t."wins"   = m.max_wins
    WHERE t."season" BETWEEN 1900 AND 2000
      AND t."market" IS NOT NULL
      AND t."name"   IS NOT NULL
)
SELECT
    "market"                      AS university,
    COUNT(*)                      AS peak_performance_seasons
FROM peak_teams
GROUP BY "market"
ORDER BY peak_performance_seasons DESC NULLS LAST
LIMIT 5;