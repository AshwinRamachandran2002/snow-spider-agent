WITH a61_pub AS (   -- publications that have at least one CPC code beginning with 'A61'
    SELECT DISTINCT
           p."application_number"         AS application_num,
           p."filing_date"                AS filing_date,
           p."assignee_harmonized"        AS assignee_json
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."cpc") f
    WHERE f.value:"code"::STRING LIKE 'A61%'          -- keep only A61 category
),

assignee_app AS (    -- explode the assignee array
    SELECT
        LOWER(TRIM(a.value:"name"::STRING))  AS assignee_name,
        application_num,
        filing_date
    FROM a61_pub,
         LATERAL FLATTEN(INPUT => assignee_json) a
    WHERE a.value:"name" IS NOT NULL
),

top_assignee AS (    -- assignee with the most A61 applications
    SELECT assignee_name,
           COUNT(DISTINCT application_num) AS apps_total
    FROM assignee_app
    GROUP BY assignee_name
    ORDER BY apps_total DESC NULLS LAST
    LIMIT 1
),

year_counts AS (     -- yearly counts for that top assignee
    SELECT 
        CAST(filing_date / 10000 AS INT)     AS year,   -- filing_date format YYYYMMDD
        COUNT(DISTINCT application_num)      AS apps_in_year
    FROM assignee_app aa
    JOIN top_assignee ta
      ON aa.assignee_name = ta.assignee_name
    WHERE filing_date IS NOT NULL
    GROUP BY year
)

SELECT year
FROM year_counts
ORDER BY apps_in_year DESC NULLS LAST
LIMIT 1;