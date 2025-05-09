WITH "A61_PUBS" AS (
    SELECT
        p."publication_number"          AS "pub_num",
        p."filing_date"                 AS "filing_date",
        ah.value:"name"::string         AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc")              cpc_elem
         , LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE cpc_elem.value:"code"::string LIKE 'A61%'          -- category A61
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
),
"ASSIGNEE_COUNTS" AS (                            -- find assignee with most A61 applications
    SELECT
        "assignee_name",
        COUNT(DISTINCT "pub_num") AS "app_count"
    FROM "A61_PUBS"
    GROUP BY "assignee_name"
),
"TOP_ASSIGNEE" AS (
    SELECT "assignee_name"
    FROM "ASSIGNEE_COUNTS"
    ORDER BY "app_count" DESC NULLS LAST
    LIMIT 1
),
"ASSIGNEE_YEAR_COUNTS" AS (                       -- yearly counts for that top assignee
    SELECT
        ( "filing_date" / 10000 )::INT AS "year",   -- convert YYYYMMDD to year
        COUNT(DISTINCT "pub_num")     AS "app_count"
    FROM "A61_PUBS"
    WHERE "assignee_name" IN (SELECT "assignee_name" FROM "TOP_ASSIGNEE")
    GROUP BY "year"
)
SELECT "year"
FROM "ASSIGNEE_YEAR_COUNTS"
ORDER BY "app_count" DESC NULLS LAST
LIMIT 1;