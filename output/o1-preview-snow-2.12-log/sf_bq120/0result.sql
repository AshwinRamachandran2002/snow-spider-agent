SELECT
    s."GeoDesc" AS "Region",
    SUM(s."SNAP_All_Participation_Households") AS "Total_SNAP_Participation",
    ROUND(
        (
            c."income_less_10000" + c."income_10000_14999" + c."income_15000_19999"
        )::FLOAT /
        NULLIF(SUM(s."SNAP_All_Participation_Households"), 0),
        4
    ) AS "Ratio_Under_$20k_to_SNAP"
FROM
    "SDOH"."SDOH_SNAP_ENROLLMENT"."SNAP_ENROLLMENT" s
JOIN
    (
        SELECT
            RIGHT("geo_id", 5) AS "FIPS",
            "income_less_10000",
            "income_10000_14999",
            "income_15000_19999"
        FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2017_5YR"
    ) c
    ON s."FIPS" = c."FIPS"
WHERE
    EXTRACT(YEAR FROM s."Date") = 2017
GROUP BY
    s."GeoDesc",
    s."FIPS",
    c."income_less_10000",
    c."income_10000_14999",
    c."income_15000_19999"
ORDER BY
    "Total_SNAP_Participation" DESC NULLS LAST
LIMIT 10;