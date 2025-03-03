WITH t2015 AS (
    SELECT
        SUBSTRING("CoC_Number", 1, 2) AS "State_Abbreviation",
        SUM("Unsheltered_Homeless_Individuals") AS "Unsheltered_Homeless_2015"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" = 2015
    GROUP BY "State_Abbreviation"
),
t2018 AS (
    SELECT
        SUBSTRING("CoC_Number", 1, 2) AS "State_Abbreviation",
        SUM("Unsheltered_Homeless_Individuals") AS "Unsheltered_Homeless_2018"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" = 2018
    GROUP BY "State_Abbreviation"
),
national_totals AS (
    SELECT
        SUM(CASE WHEN "Count_Year" = 2015 THEN "Unsheltered_Homeless_Individuals" ELSE 0 END) AS "Total_Unsheltered_Homeless_2015",
        SUM(CASE WHEN "Count_Year" = 2018 THEN "Unsheltered_Homeless_Individuals" ELSE 0 END) AS "Total_Unsheltered_Homeless_2018"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" IN (2015, 2018)
),
national_percentage_change AS (
    SELECT
        ("Total_Unsheltered_Homeless_2018" - "Total_Unsheltered_Homeless_2015") / "Total_Unsheltered_Homeless_2015" * 100 AS "National_Percentage_Change"
    FROM national_totals
),
state_changes AS (
    SELECT
        t2015."State_Abbreviation",
        ROUND(((t2018."Unsheltered_Homeless_2018" - t2015."Unsheltered_Homeless_2015") / t2015."Unsheltered_Homeless_2015") * 100, 4) AS "State_Percentage_Change",
        ROUND(national_percentage_change."National_Percentage_Change", 4) AS "National_Percentage_Change",
        ABS(
            ROUND(((t2018."Unsheltered_Homeless_2018" - t2015."Unsheltered_Homeless_2015") / t2015."Unsheltered_Homeless_2015") * 100, 4) -
            ROUND(national_percentage_change."National_Percentage_Change", 4)
        ) AS "Difference_From_National"
    FROM t2015
    JOIN t2018 ON t2015."State_Abbreviation" = t2018."State_Abbreviation"
    CROSS JOIN national_percentage_change
)
SELECT
    "State_Abbreviation"
FROM state_changes
ORDER BY "Difference_From_National" ASC
LIMIT 5;