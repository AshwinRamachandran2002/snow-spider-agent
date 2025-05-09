SELECT
    d."country_name",
    cs."region",
    SUM(d."value") AS "total_long_term_external_debt"
FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA        AS d
JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY         AS cs
      ON d."country_code" = cs."country_code"
WHERE d."indicator_code" = 'DT.DOD.DLXF.CD'      -- External debt stocks, long-term (current US$)
  AND d."value" IS NOT NULL
  AND cs."region" IS NOT NULL                   -- exclude countries without a specified region
GROUP BY
    d."country_name",
    cs."region"
ORDER BY
    "total_long_term_external_debt" DESC NULLS LAST
LIMIT 10;