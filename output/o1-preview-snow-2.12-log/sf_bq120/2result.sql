SELECT
    t1."GeoDesc" AS "Region",
    t1."SNAP_All_Participation_Households" AS "Total_SNAP_Participation",
    ROUND(
        (
            COALESCE(t2."income_less_10000", 0) +
            COALESCE(t2."income_10000_14999", 0) +
            COALESCE(t2."income_15000_19999", 0)
        )::FLOAT
        / NULLIF(t1."SNAP_All_Participation_Households", 0),
        4
    ) AS "Ratio_Under_$20k_to_SNAP"
FROM SDOH.SDOH_SNAP_ENROLLMENT.SNAP_ENROLLMENT t1
JOIN SDOH.CENSUS_BUREAU_ACS.COUNTY_2017_5YR t2
    ON t1."FIPS" = t2."geo_id"
WHERE t1."Date" = '2017-01-01'
  AND t1."SNAP_All_Participation_Households" > 0
ORDER BY t1."SNAP_All_Participation_Households" DESC NULLS LAST
LIMIT 10;