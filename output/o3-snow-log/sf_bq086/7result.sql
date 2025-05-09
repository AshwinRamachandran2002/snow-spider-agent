SELECT
    c."country_name",
    c."iso_3166_1_alpha_3"               AS "iso3_country_code",
    c."cumulative_confirmed",
    p."value"                            AS "population_2018",
    ROUND( (c."cumulative_confirmed" / p."value") * 100 , 4) 
                                         AS "percent_population_confirmed"
FROM COVID19_OPEN_WORLD_BANK.COVID19_OPEN_DATA.COVID19_OPEN_DATA        AS c
JOIN COVID19_OPEN_WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA             AS p
      ON p."country_code"   = c."iso_3166_1_alpha_3"
WHERE c."date"               = '2020-06-30'
  AND c."aggregation_level"  = 0               -- country-level rows
  AND p."indicator_code"     = 'SP.POP.TOTL'   -- total population indicator
  AND p."year"               = 2018            -- most recent population year
ORDER BY "percent_population_confirmed" DESC NULLS LAST;