WITH t2015 AS (
    SELECT 
        SUBSTRING("geo_id", 1, 2) AS "state_code",
        SUM("not_in_labor_force") AS "Not_in_Labor_Force_2015",
        SUM("total_pop") AS "Total_Population_2015",
        AVG("median_income") AS "Median_Income_2015"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2015_5YR"
    WHERE "not_in_labor_force" IS NOT NULL AND "total_pop" > 0
    GROUP BY "state_code"
),
t2018 AS (
    SELECT 
        SUBSTRING("geo_id", 1, 2) AS "state_code",
        SUM("not_in_labor_force") AS "Not_in_Labor_Force_2018",
        SUM("total_pop") AS "Total_Population_2018",
        AVG("median_income") AS "Median_Income_2018"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR"
    WHERE "not_in_labor_force" IS NOT NULL AND "total_pop" > 0
    GROUP BY "state_code"
)
SELECT 
    sf."state" AS "State",
    t2015."Not_in_Labor_Force_2015",
    ROUND((t2015."Not_in_Labor_Force_2015" / t2015."Total_Population_2015") * 100, 4) AS "Proportion_2015 (%)",
    t2018."Not_in_Labor_Force_2018",
    ROUND((t2018."Not_in_Labor_Force_2018" / t2018."Total_Population_2018") * 100, 4) AS "Proportion_2018 (%)",
    ROUND(t2015."Median_Income_2015", 4) AS "Median_Income_2015",
    ROUND(t2018."Median_Income_2018", 4) AS "Median_Income_2018",
    ROUND(t2018."Median_Income_2018" - t2015."Median_Income_2015", 4) AS "Median_Income_Increase"
FROM t2015
JOIN t2018 ON t2015."state_code" = t2018."state_code"
JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" sf 
    ON LPAD(TO_VARCHAR(sf."fips"), 2, '0') = t2015."state_code"
ORDER BY t2015."Not_in_Labor_Force_2015" ASC
LIMIT 3;