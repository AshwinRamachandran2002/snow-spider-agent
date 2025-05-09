WITH pop_growth AS (      -- ① 2017-18 population growth
    SELECT
        "country_code",
        ("year_2018" - "year_2017") / "year_2017"   AS pop_growth_ratio
    FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION."POPULATION_BY_COUNTRY"
    WHERE "year_2017" IS NOT NULL
      AND "year_2018" IS NOT NULL
      AND "year_2017" <> 0
),                                                           
health_pivot AS (          -- ② per–capita health-expenditure values for 2017 & 2018
    SELECT
        "country_code",
        MAX(CASE WHEN "year" = 2017 THEN "value" END) AS val2017,
        MAX(CASE WHEN "year" = 2018 THEN "value" END) AS val2018
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION."HEALTH_NUTRITION_POPULATION"
    WHERE "indicator_code" = 'SH.XPD.CHEX.PC.PP.CD'              -- PPP, current int. $
    GROUP BY "country_code"
), 
health_growth AS (         -- ③ 2017-18 expenditure growth
    SELECT
        "country_code",
        (val2018 - val2017) / val2017             AS hexp_growth_ratio
    FROM health_pivot
    WHERE val2017 IS NOT NULL
      AND val2018 IS NOT NULL
      AND val2017 <> 0
)
-- ④ count countries whose population AND health-expenditure both grew >1 %
SELECT
    COUNT(*) AS "countries_with_>1pct_growth_in_both"
FROM pop_growth  pg
JOIN health_growth hg
  ON pg."country_code" = hg."country_code"
WHERE pg.pop_growth_ratio  > 0.01
  AND hg.hexp_growth_ratio > 0.01;