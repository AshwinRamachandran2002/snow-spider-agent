SELECT 
    sf."state" AS "State",
    t2015."total_not_in_labor_force_2015",
    ROUND(t2015."proportion_not_in_labor_force_2015", 4) AS "Proportion_2015 (%)",
    t2018."total_not_in_labor_force_2018",
    ROUND(t2018."proportion_not_in_labor_force_2018", 4) AS "Proportion_2018 (%)",
    t2015."average_median_income_2015" AS "Median_Income_2015",
    t2018."average_median_income_2018" AS "Median_Income_2018",
    ROUND((t2018."average_median_income_2018" - t2015."average_median_income_2015"), 4) AS "Median_Income_Increase"
FROM 
    (SELECT 
        SUBSTRING("geo_id", 10, 2) AS "state_fips",
        SUM("not_in_labor_force") AS "total_not_in_labor_force_2015",
        SUM("pop_16_over") AS "total_pop_16_over_2015",
        (SUM("not_in_labor_force") / NULLIF(SUM("pop_16_over"), 0)) * 100 AS "proportion_not_in_labor_force_2015",
        AVG("median_income") AS "average_median_income_2015"
    FROM 
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2015_5YR"
    WHERE 
        "median_income" IS NOT NULL 
        AND "not_in_labor_force" IS NOT NULL
        AND "pop_16_over" > 0
    GROUP BY 
        "state_fips") t2015
JOIN
    (SELECT 
        SUBSTRING("geo_id", 10, 2) AS "state_fips",
        SUM("not_in_labor_force") AS "total_not_in_labor_force_2018",
        SUM("pop_16_over") AS "total_pop_16_over_2018",
        (SUM("not_in_labor_force") / NULLIF(SUM("pop_16_over"), 0)) * 100 AS "proportion_not_in_labor_force_2018",
        AVG("median_income") AS "average_median_income_2018"
    FROM 
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR"
    WHERE 
        "median_income" IS NOT NULL 
        AND "not_in_labor_force" IS NOT NULL
        AND "pop_16_over" > 0
    GROUP BY 
        "state_fips") t2018
ON t2015."state_fips" = t2018."state_fips"
JOIN
    "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" sf
ON TO_NUMBER(t2015."state_fips") = sf."fips"
ORDER BY t2018."total_not_in_labor_force_2018" ASC
LIMIT 3;