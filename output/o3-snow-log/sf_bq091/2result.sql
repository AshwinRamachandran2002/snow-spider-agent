WITH a61_apps AS (     -- all publications whose classification code starts with 'A61'
    SELECT  DISTINCT
            p."publication_number",
            assignee.value:"name"::string      AS assignee_name,
            p."filing_date"                    AS filing_date
    FROM    PATENTS.PATENTS.PUBLICATIONS p,
            LATERAL FLATTEN(input => p."cpc")               cpc,
            LATERAL FLATTEN(input => p."assignee_harmonized") assignee
    WHERE   cpc.value:"code"::string LIKE 'A61%'            -- patent category A61
      AND   p."filing_date" IS NOT NULL
),

assignee_totals AS (   -- find the assignee with the most A61 applications
    SELECT  assignee_name,
            COUNT(*)                                   AS total_apps,
            RANK()  OVER (ORDER BY COUNT(*) DESC)      AS rnk
    FROM    a61_apps
    GROUP BY assignee_name
),

top_assignee AS (      -- keep only the top‐ranked assignee (or assignees, in case of ties)
    SELECT assignee_name
    FROM   assignee_totals
    WHERE  rnk = 1
),

yearly_counts AS (     -- count that assignee’s applications by filing year
    SELECT  TO_NUMBER(SUBSTR(filing_date::string,1,4)) AS filing_year,
            COUNT(*)                                   AS apps_in_year
    FROM    a61_apps
    WHERE   assignee_name IN (SELECT assignee_name FROM top_assignee)
    GROUP BY TO_NUMBER(SUBSTR(filing_date::string,1,4))
)

-- year in which the top assignee filed the most A61 applications
SELECT  filing_year
FROM    yearly_counts
ORDER BY apps_in_year DESC NULLS LAST
LIMIT 1;