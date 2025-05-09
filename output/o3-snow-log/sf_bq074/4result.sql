/*  Count counties whose 5–year-ACS unemployment rose from 2015→2018
    AND whose dual-eligible Public_Total fell between 01-Dec-2015 → 01-Dec-2018  */

WITH unemp_by_county AS (          -- 1. unemployment in 2015 vs 2018
    SELECT
        "geo_id"                                                    AS county_id,
        SUM(CASE WHEN EXTRACT(year FROM "do_date") = 2015
                 THEN "unemployed_pop" END)                         AS unemp_2015,
        SUM(CASE WHEN EXTRACT(year FROM "do_date") = 2018
                 THEN "unemployed_pop" END)                         AS unemp_2018
    FROM SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
    WHERE EXTRACT(year FROM "do_date") IN (2015, 2018)
    GROUP BY "geo_id"
),

unemp_increase AS (               -- 2. keep counties with unemployment increase
    SELECT county_id
    FROM   unemp_by_county
    WHERE  unemp_2015 IS NOT NULL
       AND unemp_2018 IS NOT NULL
       AND unemp_2018 > unemp_2015
),

dual_totals AS (                  -- 3. Public_Total on the two required dates
    SELECT
        UPPER(TRIM("County_Name"))                                   AS county_name,
        MAX(CASE WHEN "Date" = '2015-12-01'
                 THEN "Public_Total" END)                            AS total_2015,
        MAX(CASE WHEN "Date" = '2018-12-01'
                 THEN "Public_Total" END)                            AS total_2018
    FROM SDOH.SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT."DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM"
    WHERE "Date" IN ('2015-12-01', '2018-12-01')
    GROUP BY UPPER(TRIM("County_Name"))
),

dual_decrease AS (               -- 4. keep counties with Public_Total decrease
    SELECT county_name
    FROM   dual_totals
    WHERE  total_2015 IS NOT NULL
       AND total_2018 IS NOT NULL
       AND total_2018 < total_2015
)

-- 5. final answer: intersection of the two county sets
SELECT COUNT(*) AS counties_with_unemp_up_and_dual_down
FROM   unemp_increase  ui
JOIN   dual_decrease   dd
       ON ui.county_id = dd.county_name;