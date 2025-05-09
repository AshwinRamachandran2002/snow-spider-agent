WITH a61_publications AS (
    /* explode CPC and assignee arrays, keep only A61 publications with a filing date */
    SELECT
        p."application_number"                           AS app_num,
        p."filing_date"                                  AS filing_date,
        assignee.value:"name"::STRING                    AS assignee_name
    FROM  "PATENTS"."PATENTS"."PUBLICATIONS"  p
          ,LATERAL FLATTEN(input => p."cpc")            cpc
          ,LATERAL FLATTEN(input => p."assignee_harmonized") assignee
    WHERE  cpc.value:"code"::STRING LIKE 'A61%'        -- patent category
      AND  p."filing_date" IS NOT NULL                 -- need a filing year
),

/* find the assignee with the most A61 applications overall */
assignee_totals AS (
    SELECT
        assignee_name,
        COUNT(DISTINCT app_num) AS total_apps
    FROM a61_publications
    GROUP BY assignee_name
),
top_assignee AS (
    SELECT assignee_name
    FROM   assignee_totals
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_apps DESC NULLS LAST) = 1
),

/* for that assignee, count applications per filing year */
yearly_counts AS (
    SELECT
        FLOOR(filing_date/10000) AS filing_year,   -- extract YYYY from YYYYMMDD
        COUNT(DISTINCT app_num)  AS apps_in_year
    FROM   a61_publications
    WHERE  assignee_name IN (SELECT assignee_name FROM top_assignee)
    GROUP BY filing_year
)

/* return the year with the highest count */
SELECT filing_year
FROM   yearly_counts
ORDER  BY apps_in_year DESC NULLS LAST
LIMIT  1;