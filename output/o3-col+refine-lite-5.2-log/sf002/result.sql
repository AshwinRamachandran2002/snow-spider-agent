/*  Top‑10 active U.S. banks (assets > $10 B) with the largest share of uninsured
    deposits as of 2022‑12‑31.

    ‑ “% Insured (Estimated)” variables are identified dynamically:
        · VARIABLE_NAME contains both ‘insured’ and ‘estimated’
        · UNIT = 'Percent'   (excludes dollar‑amount versions)

    ‑ “Total Assets” uses VARIABLE_NAME that contains ‘total assets’
      but not ‘average’, and UNIT = 'USD'.

    ‑ Uninsured % = 1 – Insured %.

    ‑ Banks are required to be active (IS_ACTIVE = TRUE, CATEGORY = 'Bank').
*/
WITH insured_pct AS (          -- quarterly % insured, 2022‑12‑31
    SELECT
        t."ID_RSSD",
        t."VALUE" AS "PCT_INSURED"
    FROM "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES"  t
    JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_ATTRIBUTES"  a
      ON a."VARIABLE" = t."VARIABLE"
    WHERE a."UNIT" = 'Percent'
      AND a."VARIABLE_NAME" ILIKE '%insured%'
      AND a."VARIABLE_NAME" ILIKE '%estimated%'
      AND t."DATE" = '2022-12-31'
      AND t."VALUE" IS NOT NULL
),
assets AS (                    -- total assets, 2022‑12‑31
    SELECT
        t."ID_RSSD",
        t."VALUE" AS "TOTAL_ASSETS"
    FROM "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES"  t
    JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_ATTRIBUTES"  a
      ON a."VARIABLE" = t."VARIABLE"
    WHERE a."UNIT" = 'USD'
      AND a."VARIABLE_NAME" ILIKE '%total assets%'
      AND a."VARIABLE_NAME" NOT ILIKE '%average%'      -- exclude averages
      AND t."DATE" = '2022-12-31'
      AND t."VALUE" IS NOT NULL
),
combined AS (                  -- merge & compute uninsured %
    SELECT
        a."ID_RSSD",
        a."TOTAL_ASSETS",
        1 - i."PCT_INSURED"              AS "PCT_UNINSURED"
    FROM assets   a
    JOIN insured_pct i USING ("ID_RSSD")
    WHERE a."TOTAL_ASSETS" > 10000000000        -- > $10 B
),
ranked AS (                    -- pick one observation per bank (max uninsured %)
    SELECT
        "ID_RSSD",
        MAX("PCT_UNINSURED") AS "PCT_UNINSURED"
    FROM combined
    GROUP BY "ID_RSSD"
)
SELECT
    e."NAME"                          AS "BANK_NAME",
    r."PCT_UNINSURED"
FROM ranked r
JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_ENTITIES" e
  ON e."ID_RSSD" = r."ID_RSSD"
WHERE e."CATEGORY" = 'Bank'
  AND e."IS_ACTIVE" = TRUE
ORDER BY r."PCT_UNINSURED" DESC NULLS LAST,
         e."NAME"
LIMIT 10;