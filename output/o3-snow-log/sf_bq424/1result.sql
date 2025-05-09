SELECT
    cs."short_name"                                  AS "country",
    SUM(id."value")                                  AS "total_long_term_external_debt"
FROM
    WORLD_BANK.WORLD_BANK_INTL_DEBT.INTERNATIONAL_DEBT  id
JOIN
    WORLD_BANK.WORLD_BANK_INTL_DEBT.COUNTRY_SUMMARY     cs
      ON id."country_code" = cs."country_code"
WHERE
    id."indicator_code" = 'DT.DOD.DLXF.CD'   -- External debt stocks, long-term (current US$)
    AND cs."region" IS NOT NULL             -- exclude economies without a specified region
GROUP BY
    cs."short_name"
ORDER BY
    "total_long_term_external_debt" DESC NULLS LAST
LIMIT 10;