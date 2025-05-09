WITH "FILTERED" AS (   -- all A61 publications with flattened CPC and assignee info
    SELECT
        p."publication_number",
        p."country_code",
        FLOOR(p."publication_date" / 10000)          AS "year",
        ah.value:"name"::STRING                      AS "assignee_name",
        c.value:"code"::STRING                       AS "cpc_code"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."cpc")                c,
         LATERAL FLATTEN(INPUT => p."assignee_harmonized") ah
    WHERE c.value:"code"::STRING ILIKE 'A61%'
),
"TOP_ASSIGNEE" AS (     -- assignee with most A61 patents overall
    SELECT "assignee_name"
    FROM   "FILTERED"
    GROUP  BY "assignee_name"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
),
"BUSIEST_YEAR" AS (     -- year when that assignee filed the most A61 patents
    SELECT "year"
    FROM   "FILTERED" f
    JOIN   "TOP_ASSIGNEE" t
           ON f."assignee_name" = t."assignee_name"
    GROUP  BY "year"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
),
"COUNTRY_COUNTS" AS (   -- top-5 jurisdictions in that busiest year
    SELECT
        f."country_code",
        COUNT(*) AS "patent_count"
    FROM   "FILTERED" f
    JOIN   "TOP_ASSIGNEE" t
           ON f."assignee_name" = t."assignee_name"
    JOIN   "BUSIEST_YEAR"  y
           ON f."year" = y."year"
    GROUP  BY f."country_code"
    ORDER  BY "patent_count" DESC NULLS LAST
    LIMIT  5
)
SELECT LISTAGG("country_code", ',')
         WITHIN GROUP (ORDER BY "patent_count" DESC, "country_code") 
         AS "top_jurisdictions"
FROM   "COUNTRY_COUNTS";