-- Task: Find the number of patent filings per CPC group per filing year for patents granted in December 2016 in Germany. For each CPC group, show the CPC group, the filing year, and the number of filings.
WITH patent_cpcs AS (
    SELECT
        cd."parents",
        CAST(FLOOR(app_data."filing_date" / 10000) AS INT) AS "filing_year"
    FROM (
        SELECT pub."application_number", MAX(pub."cpc") AS "cpc", MAX(pub."filing_date") AS "filing_date"
        FROM "PATENTS"."PATENTS"."PUBLICATIONS" pub
        WHERE pub."application_number" != ''
          AND pub."country_code" = 'DE'
          AND pub."grant_date" >= 20161201
          AND pub."grant_date" <= 20161231
        GROUP BY pub."application_number"
    ) app_data,
    LATERAL FLATTEN(INPUT => app_data."cpc") AS cpcs
    JOIN "PATENTS"."PATENTS"."CPC_DEFINITION" cd ON cd."symbol" = cpcs.value:"code"
    WHERE cpcs.value:"first" = TRUE
      AND app_data."filing_date" > 0
),
yearly_counts AS (
    SELECT
        cpc_parent.VALUE AS "cpc_group",
        "filing_year",
        COUNT(*) AS "cnt"
    FROM patent_cpcs,
         LATERAL FLATTEN(INPUT => "parents") AS cpc_parent
    GROUP BY "cpc_group", "filing_year"
)
SELECT "cpc_group", "filing_year", "cnt"
FROM yearly_counts
ORDER BY "cnt" DESC;