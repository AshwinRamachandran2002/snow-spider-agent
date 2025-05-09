SELECT
    se_max."Region",
    se_max."Total_SNAP_Participation",
    ROUND(
        (
            ci."income_less_10000" + ci."income_10000_14999" + ci."income_15000_19999"
        )::FLOAT / NULLIF(se_max."Total_SNAP_Participation", 0),
        4
    ) AS "Ratio_Under_$20k_to_SNAP"
FROM
    (
        SELECT
            "FIPS",
            "GeoDesc" AS "Region",
            MAX("SNAP_All_Participation_Households") AS "Total_SNAP_Participation"
        FROM
            "SDOH"."SDOH_SNAP_ENROLLMENT"."SNAP_ENROLLMENT"
        WHERE
            "Date" BETWEEN '2017-01-01' AND '2017-12-31'
                AND "SNAP_All_Participation_Households" > 0
        GROUP BY
            "FIPS",
            "GeoDesc"
    ) se_max
JOIN
    "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2017_5YR" ci
        ON se_max."FIPS" = ci."geo_id"
ORDER BY
    se_max."Total_SNAP_Participation" DESC NULLS LAST
LIMIT 10;