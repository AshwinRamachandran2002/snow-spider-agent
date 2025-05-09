WITH filtered_pub AS (         -- publications that have CPC code A01B3…
    SELECT
        P."publication_number",
        P."application_number",
        P."filing_date",
        P."country_code"                                  AS COUNTRY_CODE,
        AH.value:"name"::string                           AS ASSIGNEE_NAME,
        FLOOR(P."filing_date" / 10000)                    AS FILING_YEAR   -- yyyymmdd → yyyy
    FROM PATENTS.PATENTS."PUBLICATIONS"  P,
         LATERAL FLATTEN (INPUT => P."cpc")               C,               -- explode CPC codes
         LATERAL FLATTEN (INPUT => P."assignee_harmonized") AH             -- explode assignees
    WHERE C.value:"code"::string LIKE 'A01B3%'                            -- restrict to class A01B3
      AND AH.value:"name" IS NOT NULL
      AND P."filing_date" IS NOT NULL
      AND P."filing_date" > 0
),

-- total applications per assignee
assignee_totals AS (
    SELECT
        ASSIGNEE_NAME,
        COUNT(*) AS TOTAL_APPLICATIONS
    FROM filtered_pub
    GROUP BY ASSIGNEE_NAME
),

-- top‑3 assignees
top3 AS (
    SELECT *
    FROM assignee_totals
    ORDER BY TOTAL_APPLICATIONS DESC NULLS LAST, ASSIGNEE_NAME
    LIMIT 3
),

-- application counts per (assignee, year)
year_counts AS (
    SELECT
        f.ASSIGNEE_NAME,
        f.FILING_YEAR,
        COUNT(*) AS APPS_IN_YEAR
    FROM filtered_pub f
    JOIN top3        t ON t.ASSIGNEE_NAME = f.ASSIGNEE_NAME
    GROUP BY f.ASSIGNEE_NAME, f.FILING_YEAR
),

-- pick the peak year for each assignee
peak_year AS (
    SELECT
        yc.ASSIGNEE_NAME,
        yc.FILING_YEAR  AS PEAK_YEAR,
        yc.APPS_IN_YEAR,
        ROW_NUMBER() OVER (PARTITION BY yc.ASSIGNEE_NAME
                           ORDER BY yc.APPS_IN_YEAR DESC,
                                    yc.FILING_YEAR        ) AS RN
    FROM year_counts yc
),
chosen_peak AS (
    SELECT ASSIGNEE_NAME, PEAK_YEAR, APPS_IN_YEAR
    FROM   peak_year
    WHERE  RN = 1
),

-- within the peak year, find the country with most filings
country_counts AS (
    SELECT
        f.ASSIGNEE_NAME,
        f.COUNTRY_CODE,
        COUNT(*) AS APPS_IN_COUNTRY
    FROM filtered_pub f
    JOIN chosen_peak cp
         ON  cp.ASSIGNEE_NAME = f.ASSIGNEE_NAME
        AND cp.PEAK_YEAR      = f.FILING_YEAR
    GROUP BY f.ASSIGNEE_NAME, f.COUNTRY_CODE
),
top_country AS (
    SELECT
        cc.ASSIGNEE_NAME,
        cc.COUNTRY_CODE                       AS TOP_COUNTRY_CODE,
        ROW_NUMBER() OVER (PARTITION BY cc.ASSIGNEE_NAME
                           ORDER BY cc.APPS_IN_COUNTRY DESC,
                                    cc.COUNTRY_CODE           ) AS RN
    FROM country_counts cc
)

-- final result -----------------------------------------------------
SELECT
    t.ASSIGNEE_NAME                                        AS "ASSIGNEE_NAME",
    t.TOTAL_APPLICATIONS                                   AS "TOTAL_APPLICATIONS",
    cp.PEAK_YEAR                                           AS "PEAK_YEAR",
    cp.APPS_IN_YEAR                                        AS "APPLICATIONS_IN_PEAK_YEAR",
    tc.TOP_COUNTRY_CODE                                    AS "TOP_COUNTRY_CODE_IN_PEAK_YEAR"
FROM top3             t
JOIN chosen_peak      cp ON cp.ASSIGNEE_NAME = t.ASSIGNEE_NAME
JOIN top_country      tc ON tc.ASSIGNEE_NAME = t.ASSIGNEE_NAME
WHERE tc.RN = 1                                               -- keep only best country per assignee
ORDER BY t.TOTAL_APPLICATIONS DESC NULLS LAST,
         t.ASSIGNEE_NAME;