WITH pubs AS (
    /* all publications that have at least one CPC code starting with 'A61' */
    SELECT DISTINCT
           p."publication_number",
           p."filing_date",
           assignee.value:"name"::TEXT         AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."assignee_harmonized") AS assignee,
         LATERAL FLATTEN(input => p."cpc")                 AS cpc_flat
    WHERE cpc_flat.value:"code"::TEXT LIKE 'A61%'          -- category A61
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
      AND assignee.value:"name" IS NOT NULL
), assignee_rank AS (
    /* find the assignee with the most A61-category applications */
    SELECT
        assignee_name,
        COUNT(*) AS total_apps,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS rn
    FROM pubs
    GROUP BY assignee_name
), top_assignee AS (
    SELECT assignee_name
    FROM assignee_rank
    WHERE rn = 1                             -- the single top assignee
), year_counts AS (
    /* count that assignee’s filings per year */
    SELECT
        FLOOR(pubs."filing_date" / 10000) AS filing_year,
        COUNT(*)                          AS apps_in_year
    FROM pubs
    JOIN top_assignee USING (assignee_name)
    GROUP BY filing_year
)
/* year in which that assignee filed the most A61 applications */
SELECT filing_year
FROM year_counts
ORDER BY apps_in_year DESC NULLS LAST
LIMIT 1;