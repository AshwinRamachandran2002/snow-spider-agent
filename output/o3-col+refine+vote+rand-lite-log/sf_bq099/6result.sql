WITH cpc_filtered AS (              -- all publications having a CPC that starts with A01B3
    SELECT
        pub."application_number",
        a.value:"name"::STRING               AS "assignee_name",
        TO_NUMBER(LEFT(pub."filing_date",4)) AS "filing_year",
        pub."country_code"
    FROM PATENTS.PATENTS.PUBLICATIONS pub,
         LATERAL FLATTEN(input => pub."cpc")                c,
         LATERAL FLATTEN(input => pub."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A01B3%'
),
assignee_totals AS (                -- total apps for every assignee, keep the top-3
    SELECT
        "assignee_name",
        COUNT(DISTINCT "application_number") AS "total_apps"
    FROM cpc_filtered
    GROUP BY "assignee_name"
    ORDER BY "total_apps" DESC NULLS LAST
    LIMIT 3
),
base AS (                           -- restrict subsequent work to those top-3 assignees
    SELECT f.*
    FROM cpc_filtered f
    JOIN assignee_totals t
      ON f."assignee_name" = t."assignee_name"
),
year_counts AS (                    -- per-year application counts
    SELECT
        "assignee_name",
        "filing_year",
        COUNT(DISTINCT "application_number") AS "year_apps",
        ROW_NUMBER() OVER (PARTITION BY "assignee_name"
                           ORDER BY COUNT(DISTINCT "application_number") DESC,
                                    "filing_year" ASC) AS rn
    FROM base
    GROUP BY "assignee_name","filing_year"
),
peak_year AS (                      -- identify the single peak year for each assignee
    SELECT
        "assignee_name",
        "filing_year"  AS "peak_year",
        "year_apps"    AS "apps_in_peak_year"
    FROM year_counts
    WHERE rn = 1
),
country_counts AS (                 -- country counts within each (assignee,year)
    SELECT
        b."assignee_name",
        b."filing_year",
        b."country_code",
        COUNT(DISTINCT b."application_number") AS "country_apps",
        ROW_NUMBER() OVER (PARTITION BY b."assignee_name",b."filing_year"
                           ORDER BY COUNT(DISTINCT b."application_number") DESC,
                                    b."country_code" ASC) AS rn
    FROM base b
    GROUP BY b."assignee_name",b."filing_year",b."country_code"
),
peak_country AS (                   -- top country for the peak year
    SELECT
        c."assignee_name",
        c."country_code"
    FROM country_counts c
    JOIN peak_year p
      ON c."assignee_name" = p."assignee_name"
     AND c."filing_year"   = p."peak_year"
    WHERE c.rn = 1
)
SELECT
    p."assignee_name",
    t."total_apps",
    p."peak_year",
    p."apps_in_peak_year",
    pc."country_code" AS "top_country_code_in_peak_year"
FROM peak_year        p
JOIN assignee_totals  t  ON p."assignee_name" = t."assignee_name"
JOIN peak_country     pc ON p."assignee_name" = pc."assignee_name"
ORDER BY t."total_apps" DESC NULLS LAST;