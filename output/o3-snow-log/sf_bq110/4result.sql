WITH ny_cocs AS (
    SELECT
        "CoC_Number",
        "CoC_Name",
        "Count_Year",
        "Homeless_Veterans"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "CoC_Number" ILIKE 'NY-%'               -- New York CoCs
      AND "Count_Year" IN (2012, 2018)            -- years of interest
)

SELECT
    "CoC_Number",
    MAX("CoC_Name")                                          AS "CoC_Name",
    SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END) AS "Homeless_Veterans_2012",
    SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END) AS "Homeless_Veterans_2018",
    COALESCE(SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END), 0)
      - COALESCE(SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END), 0)
                                                              AS "Change_in_Homeless_Veterans"
FROM ny_cocs
GROUP BY "CoC_Number"
HAVING COUNT(DISTINCT "Count_Year") = 2                      -- ensure data exists for both years
ORDER BY "Change_in_Homeless_Veterans" DESC NULLS LAST;