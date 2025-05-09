WITH insured_pct AS (   --  % Insured (Estimated) for 2022-12-31
    SELECT
        "ID_RSSD",
        "VALUE" AS "PCT_INSURED"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "VARIABLE" = 'ESTINS'
      AND "DATE"     = '2022-12-31'
), total_assets AS (    --  Total Assets for the same date
    SELECT
        "ID_RSSD",
        "VALUE" AS "TOTAL_ASSETS_USD"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "VARIABLE" = 'ASSET'
      AND "DATE"     = '2022-12-31'
), combined AS (        --  join insured %, assets, and entity metadata
    SELECT
        e."NAME"                                         AS "BANK_NAME",
        (1 - ip."PCT_INSURED")                           AS "UNINSURED_RATIO",
        ta."TOTAL_ASSETS_USD"
    FROM insured_pct  ip
    JOIN total_assets ta
          ON ta."ID_RSSD" = ip."ID_RSSD"
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
          ON e."ID_RSSD" = ip."ID_RSSD"
    WHERE e."IS_ACTIVE"         = TRUE                -- active banks only
      AND ta."TOTAL_ASSETS_USD" > 10000000000         -- assets > $10 B
)
SELECT
    "BANK_NAME",
    ROUND("UNINSURED_RATIO" * 100, 2) AS "PCT_UNINSURED"
FROM combined
ORDER BY "PCT_UNINSURED" DESC NULLS LAST
LIMIT 10;