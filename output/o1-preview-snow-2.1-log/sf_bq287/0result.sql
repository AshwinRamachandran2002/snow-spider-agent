SELECT
  ROUND((c."employed_pop" / c."pop_16_over") * 100, 4) AS "employment_rate"
FROM
  (
    SELECT "zip_code"
    FROM FEC.FDIC_BANKS.LOCATIONS
    WHERE "state" = 'UT'
    GROUP BY "zip_code"
    ORDER BY COUNT(*) ASC, "zip_code" ASC
    LIMIT 1
  ) l
JOIN
  (
    SELECT
      RIGHT("geo_id", 5) AS "zip_code",
      "pop_16_over",
      "employed_pop"
    FROM
      FEC.CENSUS_BUREAU_ACS.ZCTA5_2017_5YR
    WHERE "pop_16_over" > 0
  ) c
  ON l."zip_code" = c."zip_code"
LIMIT 1;