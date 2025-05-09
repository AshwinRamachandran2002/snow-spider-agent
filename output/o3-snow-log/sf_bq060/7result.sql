SELECT 
    br."country_name",
    br."net_migration"
FROM CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."BIRTH_DEATH_GROWTH_RATES" br
JOIN CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."COUNTRY_NAMES_AREA" ca
  ON br."country_code" = ca."country_code"
WHERE br."year" = 2017
  AND ca."country_area" > 500
  AND br."net_migration" IS NOT NULL
ORDER BY br."net_migration" DESC NULLS LAST
LIMIT 3;