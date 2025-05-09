WITH income_diff AS (
    SELECT
        s18."geo_id" AS "geo_id",
        f."state" AS "State",
        (s18."median_income" - s15."median_income") AS "Median_Income_Difference"
    FROM
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2018_5YR" s18
        JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2015_5YR" s15 ON s18."geo_id" = s15."geo_id"
        JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" f ON LPAD(f."fips",2,'0') = RIGHT(s18."geo_id",2)
),
top_states AS (
    SELECT
        "geo_id",
        "State",
        "Median_Income_Difference"
    FROM
        income_diff
    ORDER BY
        "Median_Income_Difference" DESC NULLS LAST
    LIMIT 5
),
vulnerable_employment AS (
    SELECT
        s17."geo_id" AS "geo_id",
        ((s17."employed_wholesale_trade" * 0.38423645320197042)
        + ((s17."employed_agriculture_forestry_fishing_hunting_mining" + s17."employed_construction") * 0.48071410777129553)
        + (s17."employed_arts_entertainment_recreation_accommodation_food" * 0.89455676291236841)
        + (s17."employed_information" * 0.31315240083507306)
        + (s17."employed_retail_trade" * 0.51)
        ) AS "Average_Vulnerable_Employees"
    FROM
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2017_5YR" s17
)
SELECT
    ts."State",
    ROUND(ts."Median_Income_Difference", 4) AS "Median_Income_Difference",
    ROUND(ve."Average_Vulnerable_Employees", 4) AS "Average_Vulnerable_Employees"
FROM
    top_states ts
    JOIN vulnerable_employment ve ON ts."geo_id" = ve."geo_id"
ORDER BY
    ts."Median_Income_Difference" DESC NULLS LAST;