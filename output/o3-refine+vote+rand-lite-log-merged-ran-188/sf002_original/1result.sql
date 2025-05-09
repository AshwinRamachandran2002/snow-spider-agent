WITH insured_pct AS (  -- % Insured (Estimated) as of 2022‑12‑31
    SELECT
        "ID_RSSD",
        "VALUE" AS "insured_val"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "DATE" = '2022-12-31'
      AND "VARIABLE_NAME" ILIKE '%Insured (Estimated)%'
),
total_assets AS (      -- Total assets as of 2022‑12‑31
    SELECT
        "ID_RSSD",
        "VALUE" AS "assets_usd"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "DATE" = '2022-12-31'
      AND "VARIABLE_NAME" ILIKE 'Total Assets%'
),
calc AS (              -- Derive uninsured‑asset ratio
    SELECT
        a."ID_RSSD",
        a."assets_usd",
        CASE
            WHEN i."insured_val" IS NULL THEN NULL
            WHEN i."insured_val" > 1 THEN 1 - i."insured_val" / 100  -- value stored 0‑100
            ELSE 1 - i."insured_val"                                 -- value stored 0‑1
        END AS "uninsured_ratio"
    FROM total_assets a
    JOIN insured_pct i
      ON a."ID_RSSD" = i."ID_RSSD"
),
active_banks AS (      -- Restrict to active banks
    SELECT
        "ID_RSSD",
        "NAME" AS "bank_name"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES
    WHERE "IS_ACTIVE" = TRUE
      AND "CATEGORY"  = 'Bank'
)
SELECT
    b."bank_name"                              AS "Bank",
    ROUND(c."uninsured_ratio" * 100, 2)        AS "Uninsured Assets %"
FROM calc         c
JOIN active_banks b ON b."ID_RSSD" = c."ID_RSSD"
WHERE c."assets_usd" > 10000000000             -- assets > $10 B
ORDER BY c."uninsured_ratio" DESC NULLS LAST
LIMIT 10;