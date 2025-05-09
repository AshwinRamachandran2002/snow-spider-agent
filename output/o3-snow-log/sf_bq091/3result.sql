WITH a61_publications AS (          -- publications having at least one CPC code beginning with A61
    SELECT
        p."application_number"                       AS application_number,
        p."filing_date"                              AS filing_date,
        assg.value:"name"::string                    AS assignee_name
    FROM PATENTS.PATENTS."PUBLICATIONS"  AS p
         ,LATERAL FLATTEN (INPUT => p."cpc")                 cpc
         ,LATERAL FLATTEN (INPUT => p."assignee_harmonized") assg
    WHERE cpc.value:"code"::string ILIKE 'A61%'              -- filter on CPC category A61
      AND p."application_number" IS NOT NULL
      AND p."filing_date"          > 0
      AND assg.value:"name"        IS NOT NULL
),
top_assignee AS (                   -- assignee with the highest number of A61 applications
    SELECT
        assignee_name,
        COUNT(DISTINCT application_number) AS app_cnt
    FROM a61_publications
    GROUP BY assignee_name
    ORDER BY app_cnt DESC NULLS LAST
    LIMIT 1
),
yearly_totals AS (                  -- yearly filing counts for that assignee
    SELECT
        FLOOR(filing_date / 10000)               AS filing_year,   -- derive YYYY from YYYYMMDD
        COUNT(DISTINCT application_number)       AS yearly_apps
    FROM a61_publications
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
    GROUP BY filing_year
    ORDER BY yearly_apps DESC NULLS LAST, filing_year              -- most filings; tie-break by earliest year
    LIMIT 1
)
SELECT filing_year AS year_with_most_filings
FROM yearly_totals;