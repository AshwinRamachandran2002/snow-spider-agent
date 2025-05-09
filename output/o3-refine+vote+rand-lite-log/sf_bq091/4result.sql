WITH 

/* ---  A61‑classified publications via CPC  --- */
cpc_a61 AS (
    SELECT
        p."publication_number",
        p."filing_date",
        f_assignee.value:"name"::STRING      AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN (INPUT => COALESCE(p."assignee_harmonized", p."assignee"))   f_assignee
         ,LATERAL FLATTEN (INPUT => p."cpc")                                           f_cpc
    WHERE f_cpc.value:"code"::STRING ILIKE 'A61%'                       -- CPC class starts with A61
),

/* ---  A61‑classified publications via IPC  --- */
ipc_a61 AS (
    SELECT
        p."publication_number",
        p."filing_date",
        f_assignee.value:"name"::STRING      AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN (INPUT => COALESCE(p."assignee_harmonized", p."assignee"))   f_assignee
         ,LATERAL FLATTEN (INPUT => p."ipc")                                           f_ipc
    WHERE f_ipc.value:"code"::STRING ILIKE 'A61%'                       -- IPC class starts with A61
),

/* ---  All A61 publications (deduplicated on publication number) --- */
all_a61 AS (
    SELECT DISTINCT * FROM cpc_a61
    UNION
    SELECT DISTINCT * FROM ipc_a61
),

/* ---  Find the assignee with the greatest number of A61 applications --- */
top_assignee AS (
    SELECT assignee_name,
           COUNT(DISTINCT "publication_number") AS app_cnt
    FROM all_a61
    GROUP BY assignee_name
    ORDER BY app_cnt DESC NULLS LAST, assignee_name
    LIMIT 1
),

/* ---  Yearly filings for that top assignee --- */
yearly_filings AS (
    SELECT
        YEAR(TO_DATE("filing_date"::STRING, 'YYYYMMDD')) AS filing_year,
        COUNT(DISTINCT "publication_number")             AS apps_in_year
    FROM all_a61
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
          AND "filing_date" IS NOT NULL
          AND "filing_date" <> 0
    GROUP BY filing_year
)

/* ---  Year with the maximum number of filings --- */
SELECT filing_year
FROM yearly_filings
ORDER BY apps_in_year DESC NULLS LAST, filing_year DESC
LIMIT 1;