-- Task: List all level 4 CPC technology areas in Germany associated with patents granted in December 2016. For each CPC group, display the full title, the CPC group code, and the most recent filing year associated with that group.
WITH patent_cpcs AS (
    SELECT
        cd."parents",
        CAST(FLOOR("filing_date" / 10000) AS INT) AS "filing_year"
    FROM (
        SELECT MAX("cpc") AS "cpc", MAX("filing_date") AS "filing_date"
        FROM "PATENTS"."PATENTS"."PUBLICATIONS"
        WHERE "application_number" != ''
          AND "country_code" = 'DE'
          AND "grant_date" >= 20161201
          AND "grant_date" <= 20161231
        GROUP BY "application_number"
    ), LATERAL FLATTEN(INPUT => "cpc") AS cpcs
    JOIN "PATENTS"."PATENTS"."CPC_DEFINITION" cd ON cd."symbol" = cpcs.value:"code"
    WHERE cpcs.value:"first" = TRUE
      AND "filing_date" > 0
),
yearly_counts AS (
    SELECT
        "cpc_group",
        "filing_year",
        COUNT(*) AS "cnt"
    FROM (
        SELECT
            cpc_parent.VALUE AS "cpc_group",
            "filing_year"
        FROM patent_cpcs,
             LATERAL FLATTEN(INPUT => "parents") AS cpc_parent
    )
    GROUP BY "cpc_group", "filing_year"
),
moving_avg AS (
    SELECT
        "cpc_group",
        "filing_year",
        "cnt",
        AVG("cnt") OVER (PARTITION BY "cpc_group" ORDER BY "filing_year" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "moving_avg"
    FROM yearly_counts
)
SELECT 
    c."titleFull",
    REPLACE("cpc_group", '"', '') AS "cpc_group",
    MAX("filing_year") AS "best_filing_year"
FROM moving_avg
JOIN "PATENTS"."PATENTS"."CPC_DEFINITION" c ON "cpc_group" = c."symbol"
WHERE c."level" = 4
GROUP BY c."titleFull", "cpc_group"
ORDER BY c."titleFull", "cpc_group" ASC;