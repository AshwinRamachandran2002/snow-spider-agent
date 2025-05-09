WITH pct_insured AS (   -- quarterly “% Insured (Estimated)” for 2022-12-31
    SELECT
        "ID_RSSD",
        MAX("VALUE") AS "pct_insured"        -- should be only one row, MAX is a safeguard
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "DATE"        = '2022-12-31'
      AND "VARIABLE"    = 'IDDEPINR'         -- quarterly % Insured (Estimated)
    GROUP BY "ID_RSSD"
),
total_assets AS (       -- total assets (USD) for the same date
    SELECT
        "ID_RSSD",
        MAX("VALUE") AS "total_assets_usd"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "DATE" = '2022-12-31'
      AND "UNIT" = 'USD'
      AND "VARIABLE_NAME" ILIKE '%Total Assets%'          -- pick total-asset line …
      AND "VARIABLE_NAME" NOT ILIKE '%Risk Weighted%'     -- … but exclude risk-weighted versions
    GROUP BY "ID_RSSD"
)
SELECT
    e."NAME"                                                      AS "bank_name",
    ROUND( (1 - i."pct_insured") * 100 , 2)                       AS "pct_uninsured_assets"
FROM            pct_insured       i
JOIN            total_assets      a   ON a."ID_RSSD" = i."ID_RSSD"
JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES  e
                                 ON e."ID_RSSD" = i."ID_RSSD"
WHERE a."total_assets_usd" > 10000000000      -- > $10 billion
  AND e."IS_ACTIVE" = TRUE                    -- active institutions
ORDER BY "pct_uninsured_assets" DESC NULLS LAST
LIMIT 10;