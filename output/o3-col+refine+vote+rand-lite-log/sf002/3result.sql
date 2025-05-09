WITH insured_pct AS (     -- % of deposits that are insured
    SELECT
        t."ID_RSSD",
        MIN(t."VALUE") AS "insured_pct"                     -- take one value if multiple rows exist
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES a
          ON t."VARIABLE" = a."VARIABLE"
    WHERE a."VARIABLE_NAME" ILIKE '%Insured%'               -- "% Insured (Estimated)"
      AND a."VARIABLE_NAME" ILIKE '%Estimated%'
      AND t."UNIT"               = 'Percent'                -- keep the percent form, not USD
      AND t."DATE"               = '2022-12-31'             -- quarter-end requested
    GROUP BY t."ID_RSSD"
),
total_assets AS (         -- total assets for the same date
    SELECT
        t."ID_RSSD",
        t."VALUE" AS "total_assets"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    WHERE t."VARIABLE"          = 'ASSET'                   -- “Total Assets” variable
      AND t."UNIT"              = 'USD'
      AND t."DATE"              = '2022-12-31'
),
combined AS (             -- merge and compute uninsured share
    SELECT
        i."ID_RSSD",
        (1 - i."insured_pct")    AS "uninsured_pct",        -- % of deposits that are uninsured
        a."total_assets"
    FROM insured_pct  i
    JOIN total_assets a
          ON i."ID_RSSD" = a."ID_RSSD"
)
SELECT
    e."NAME"                                                AS "BANK_NAME",
    ROUND(c."uninsured_pct" * 100, 2)                       AS "UNINSURED_ASSETS_PERCENT"
FROM combined c
JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
      ON c."ID_RSSD" = e."ID_RSSD"
WHERE e."IS_ACTIVE" = TRUE                                  -- active institutions only
  AND e."CATEGORY"  = 'Bank'
  AND c."total_assets" > 10000000000                        -- assets > $10 B
ORDER BY "UNINSURED_ASSETS_PERCENT" DESC NULLS LAST
LIMIT 10;