WITH data_2015 AS (
    SELECT 
        s."state" AS "State",
        SUM(t2015."not_in_labor_force") AS "Not_in_Labor_Force_2015",
        SUM(t2015."total_pop") AS "Total_Pop_2015",
        AVG(t2015."median_income") AS "Median_Income_2015"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR AS t2015
    INNER JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS AS s
        ON LEFT(t2015."geo_id", 2) = LPAD(s."fips"::VARCHAR, 2, '0')
    WHERE t2015."not_in_labor_force" IS NOT NULL
        AND t2015."total_pop" IS NOT NULL
        AND t2015."median_income" IS NOT NULL
        AND t2015."total_pop" > 0
    GROUP BY s."state"
),
data_2018 AS (
    SELECT 
        s."state" AS "State",
        SUM(t2018."not_in_labor_force") AS "Not_in_Labor_Force_2018",
        SUM(t2018."total_pop") AS "Total_Pop_2018",
        AVG(t2018."median_income") AS "Median_Income_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR AS t2018
    INNER JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS AS s
        ON LEFT(t2018."geo_id", 2) = LPAD(s."fips"::VARCHAR, 2, '0')
    WHERE t2018."not_in_labor_force" IS NOT NULL
        AND t2018."total_pop" IS NOT NULL
        AND t2018."median_income" IS NOT NULL
        AND t2018."total_pop" > 0
    GROUP BY s."state"
)
SELECT
    d2015."State",
    d2015."Not_in_Labor_Force_2015",
    ROUND((d2015."Not_in_Labor_Force_2015" / d2015."Total_Pop_2015") * 100, 4) AS "Proportion_2015 (%)",
    d2018."Not_in_Labor_Force_2018",
    ROUND((d2018."Not_in_Labor_Force_2018" / d2018."Total_Pop_2018") * 100, 4) AS "Proportion_2018 (%)",
    ROUND(d2015."Median_Income_2015", 4) AS "Median_Income_2015",
    ROUND(d2018."Median_Income_2018", 4) AS "Median_Income_2018",
    ROUND((d2018."Median_Income_2018" - d2015."Median_Income_2015"), 4) AS "Median_Income_Increase"
FROM data_2015 AS d2015
JOIN data_2018 AS d2018 ON d2015."State" = d2018."State"
ORDER BY d2015."Not_in_Labor_Force_2015" ASC
LIMIT 3;