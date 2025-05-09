/*  Top‑3 assignees in CPC class A01B3 and their peak‑year details  */
WITH cpc_filtered AS (          -- publications that have at least one CPC code starting with A01B3
    SELECT
        p."application_number"                    AS app_num,
        p."filing_date"                           AS filing_dt,
        p."publication_date"                      AS pub_dt,
        p."country_code"                          AS country_cd,
        ah.value:"name"::STRING                   AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN (INPUT => p."cpc")  cpc_f,
         LATERAL FLATTEN (INPUT => p."assignee_harmonized") ah
    WHERE cpc_f.value:"code"::STRING LIKE 'A01B3%'        -- class filter
      AND ah.value:"name" IS NOT NULL
),
apps AS (                       -- distinct applications per assignee (one row per application)
    SELECT DISTINCT
        assignee_name,
        app_num,
        COALESCE(NULLIF(filing_dt,0), NULLIF(pub_dt,0))   AS date_num,
        country_cd
    FROM cpc_filtered
    WHERE app_num IS NOT NULL
),
apps2 AS (                      -- add filing / publication year
    SELECT
        assignee_name,
        app_num,
        country_cd,
        CAST(date_num/10000 AS INT) AS yr          -- YYYY from YYYYMMDD
    FROM apps
),
tot_app AS (                    -- total applications per assignee
    SELECT assignee_name,
           COUNT(*) AS total_apps
    FROM apps2
    GROUP BY assignee_name
),
top3 AS (                       -- pick top‑3 assignees
    SELECT *
    FROM tot_app
    ORDER BY total_apps DESC NULLS LAST, assignee_name
    LIMIT 3
),
year_cnt AS (                   -- application count per year for those assignees
    SELECT
        a.assignee_name,
        yr,
        COUNT(*) AS apps_in_year
    FROM apps2 a
    JOIN top3 t USING (assignee_name)
    GROUP BY a.assignee_name, yr
),
peak_year AS (                  -- for each assignee, the year with most applications
    SELECT assignee_name,
           yr           AS peak_year,
           apps_in_year
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY assignee_name
                                  ORDER BY apps_in_year DESC NULLS LAST, yr) AS rn
        FROM year_cnt
    )
    WHERE rn = 1
),
country_cnt AS (                -- country distribution within that peak year
    SELECT
        a.assignee_name,
        a.country_cd,
        COUNT(*) AS apps_in_country
    FROM apps2 a
    JOIN peak_year p
      ON a.assignee_name = p.assignee_name
     AND a.yr            = p.peak_year
    GROUP BY a.assignee_name, a.country_cd
),
peak_country AS (               -- most frequent country in the peak year
    SELECT assignee_name,
           country_cd AS top_country_cd
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY assignee_name
                                  ORDER BY apps_in_country DESC NULLS LAST, country_cd) AS rn
        FROM country_cnt
    )
    WHERE rn = 1
)
SELECT
    t.assignee_name                     AS "ASSIGNEE_NAME",
    t.total_apps                        AS "TOTAL_APPLICATIONS",
    p.peak_year                         AS "PEAK_YEAR",
    p.apps_in_year                      AS "APPLICATIONS_IN_PEAK_YEAR",
    c.top_country_cd                    AS "TOP_COUNTRY_CODE_IN_PEAK_YEAR"
FROM top3            t
JOIN peak_year       p USING (assignee_name)
JOIN peak_country    c USING (assignee_name)
ORDER BY t.total_apps DESC NULLS LAST, t.assignee_name;