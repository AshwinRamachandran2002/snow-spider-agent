/* ---------- Top-3 assignees for CPC class A01B3 ---------- */
WITH filtered_pub AS (                       -- publications that contain at least one CPC code A01B3…
    SELECT DISTINCT
           p."application_number"                        AS application_number,
           p."filing_date"                               AS filing_date,
           p."country_code"                              AS country_code,
           COALESCE(a.value:"name"::string,
                    a.value::string)                     AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         ,LATERAL FLATTEN(input => p."cpc")                                   c
         ,LATERAL FLATTEN(input => COALESCE(p."assignee_harmonized",
                                            p."assignee"))                    a
    WHERE c.value:"code"::string LIKE 'A01B3%'      -- CPC class filter
      AND p."application_number" IS NOT NULL
      AND p."filing_date"        IS NOT NULL
      AND a.value                IS NOT NULL
),

/* ----- total number of applications per assignee ----- */
assignee_total AS (
    SELECT  assignee_name,
            COUNT(DISTINCT application_number) AS total_apps
    FROM    filtered_pub
    GROUP BY assignee_name
),

/* ----- yearly application counts per assignee ----- */
assignee_year_counts AS (
    SELECT  assignee_name,
            FLOOR(filing_date / 10000)          AS year,
            COUNT(DISTINCT application_number)  AS apps_in_year
    FROM    filtered_pub
    GROUP BY assignee_name, year
),

/* ----- select the peak year for each assignee ----- */
selected_peak AS (
    SELECT *
    FROM (
        SELECT  assignee_name,
                year                    AS peak_year,
                apps_in_year,
                ROW_NUMBER() OVER (PARTITION BY assignee_name
                                   ORDER BY apps_in_year DESC NULLS LAST, year) AS rn
        FROM    assignee_year_counts
    )
    WHERE rn = 1
),

/* ----- country counts inside each assignee’s peak year ----- */
country_counts AS (
    SELECT  f.assignee_name,
            f.country_code,
            COUNT(DISTINCT f.application_number) AS apps_in_country
    FROM    filtered_pub  f
    JOIN    selected_peak p
           ON f.assignee_name = p.assignee_name
          AND FLOOR(f.filing_date / 10000) = p.peak_year
    GROUP BY f.assignee_name, f.country_code
),

/* ----- top country (highest count) for each assignee in its peak year ----- */
top_country AS (
    SELECT *
    FROM (
        SELECT  assignee_name,
                country_code   AS top_country_code,
                apps_in_country,
                ROW_NUMBER() OVER (PARTITION BY assignee_name
                                   ORDER BY apps_in_country DESC NULLS LAST, country_code) AS rn
        FROM    country_counts
    )
    WHERE rn = 1
),

/* ----- rank assignees by total applications and keep top-3 ----- */
ranked_assignees AS (
    SELECT  assignee_name,
            total_apps,
            ROW_NUMBER() OVER (ORDER BY total_apps DESC NULLS LAST) AS rnk
    FROM    assignee_total
)

SELECT  r.assignee_name                        AS "ASSIGNEE_NAME",
        r.total_apps                           AS "TOTAL_APPLICATIONS",
        p.peak_year                            AS "PEAK_YEAR",
        p.apps_in_year                         AS "APPLICATIONS_IN_PEAK_YEAR",
        c.top_country_code                     AS "TOP_COUNTRY_CODE_IN_PEAK_YEAR"
FROM    ranked_assignees  r
JOIN    selected_peak     p  ON p.assignee_name = r.assignee_name
JOIN    top_country       c  ON c.assignee_name = r.assignee_name
WHERE   r.rnk <= 3
ORDER BY r.total_apps DESC NULLS LAST;