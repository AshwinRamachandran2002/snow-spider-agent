WITH season_max AS (
    /* 1.  For every season between 1900-2000 find the highest win total */
    SELECT 
        "season",
        MAX("wins") AS "max_wins"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TEAMS_SEASONS"
    WHERE "season" BETWEEN 1900 AND 2000
    GROUP BY "season"
), peak_teams AS (
    /* 2.  Keep the teams that reached that season’s max-wins
           (ignore rows that lack a school name/“market”)            */
    SELECT
        s."market",                          -- University / school name
        COUNT(*)        AS "peak_seasons"    -- # seasons with max wins
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TEAMS_SEASONS" s
    JOIN season_max m
      ON  s."season" = m."season"
     AND s."wins"   = m."max_wins"
    WHERE s."market" IS NOT NULL             -- Exclude missing names
      AND s."season" BETWEEN 1900 AND 2000
    GROUP BY s."market"
)
SELECT
    "market"        AS "UNIVERSITY",
    "peak_seasons"  AS "PEAK_SEASONS_COUNT"
FROM peak_teams
ORDER BY "PEAK_SEASONS_COUNT" DESC NULLS LAST,
         "UNIVERSITY"
LIMIT 5;