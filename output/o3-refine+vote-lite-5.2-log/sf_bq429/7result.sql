WITH geo_zip AS (   -- ZIP‑code → state lookup
    SELECT
        "zip_code"   AS zip,
        "state_code" AS state_cd
    FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES
),

/*------------------ 2015 median income ------------------*/
income_2015 AS (
    SELECT
        z15."geo_id"                    AS zip,
        g.state_cd,
        z15."median_income"             AS med_inc_2015
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR z15
           JOIN geo_zip g
             ON g.zip = z15."geo_id"
    WHERE  z15."median_income" IS NOT NULL
),

/*------------------ 2018 median income ------------------*/
income_2018 AS (
    SELECT
        z18."geo_id"        AS zip,
        z18."median_income" AS med_inc_2018
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR z18
    WHERE  z18."median_income" IS NOT NULL
),

/*----------- income change 2018 – 2015 per ZIP ----------*/
inc_diff AS (
    SELECT
        i15.zip,
        i15.state_cd,
        i18.med_inc_2018 - i15.med_inc_2015 AS income_diff
    FROM   income_2015 i15
           JOIN income_2018 i18
             ON i18.zip = i15.zip
),

/*----------- 2017 vulnerable‑employee metric ------------*/
emp_2017 AS (
    SELECT
        z17."geo_id" AS zip,
        (  COALESCE(z17."employed_wholesale_trade",0)                                    * 0.38423645320197042
         + ( COALESCE(z17."employed_agriculture_forestry_fishing_hunting_mining",0)
           + COALESCE(z17."employed_construction",0) )                                   * 0.48071410777129553
         + COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0)  * 0.89455676291236841
         + COALESCE(z17."employed_information",0)                                       * 0.31315240083507306
         + COALESCE(z17."employed_retail_trade",0)                                      * 0.51
        ) AS vuln_emp_2017
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR z17
),

/*----------- combine income change with vulnerability ----*/
zip_combined AS (
    SELECT
        d.state_cd,
        d.income_diff,
        e.vuln_emp_2017
    FROM   inc_diff d
           JOIN emp_2017 e
             ON e.zip = d.zip
    WHERE  e.vuln_emp_2017 IS NOT NULL
),

/*----------- state‑level averages -----------------------*/
state_avgs AS (
    SELECT
        state_cd,
        AVG(income_diff)   AS avg_income_diff,
        AVG(vuln_emp_2017) AS avg_vuln_emp_2017
    FROM   zip_combined
    GROUP BY state_cd
),

/*----------- attach state names & rank ------------------*/
ranked AS (
    SELECT
        f."state"             AS state_name,
        s.avg_income_diff,
        s.avg_vuln_emp_2017,
        ROW_NUMBER() OVER (ORDER BY s.avg_income_diff DESC NULLS LAST,
                                     s.state_cd) AS rn
    FROM   state_avgs s
           LEFT JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS f
                  ON f."postal_code" = s.state_cd
)

/*-------------------- final result ----------------------*/
SELECT
    state_name,
    avg_income_diff,
    avg_vuln_emp_2017
FROM   ranked
WHERE  rn <= 5
ORDER BY avg_income_diff DESC NULLS LAST,
         state_name;