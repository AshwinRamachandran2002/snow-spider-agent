WITH a61_publications AS (
    /* All publications whose CPC symbol starts with 'A61' */
    SELECT
        UPPER(a.value:"name"::string)                    AS assignee_name,
        p."publication_number"                           AS pub_num,
        TO_NUMBER(SUBSTR(p."filing_date"::string, 1, 4)) AS filing_year
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                c,   -- explode CPC array
         LATERAL FLATTEN(input => p."assignee_harmonized") a   -- explode assignee array
    WHERE c.value:"code"::string LIKE 'A61%'              -- keep only A61 category
      AND p."filing_date" IS NOT NULL
),
top_assignee AS (
    /* Identify the assignee with the most A61 applications */
    SELECT
        assignee_name,
        COUNT(DISTINCT pub_num) AS total_apps
    FROM a61_publications
    GROUP BY assignee_name
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_apps DESC NULLS LAST) = 1
),
year_counts AS (
    /* Count that assignee's applications per filing year */
    SELECT
        ap.filing_year,
        COUNT(DISTINCT ap.pub_num) AS apps_in_year
    FROM a61_publications ap
    JOIN top_assignee ta
      ON ap.assignee_name = ta.assignee_name
    GROUP BY ap.filing_year
    QUALIFY ROW_NUMBER() OVER (
                ORDER BY apps_in_year DESC NULLS LAST,
                         filing_year   ASC              -- earliest year if tie
            ) = 1
)
SELECT filing_year AS year
FROM year_counts;