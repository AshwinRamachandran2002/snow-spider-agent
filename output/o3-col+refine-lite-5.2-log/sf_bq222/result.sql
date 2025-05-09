/*  CPC level‑4 technology areas (Germany) that exhibit the highest
    exponential moving average (α = 0.1) of annual patent‑filing
    counts, computed only from patents that were granted in Dec‑2016   */

WITH RECURSIVE
base_pub AS (          -- 1) German patents granted in December‑2016
    SELECT DISTINCT
        p."publication_number",
        p."filing_date",
        f.value::VARIANT:"code"::STRING               AS "cpc_code"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN ( INPUT => p."cpc" ) f
    WHERE p."country_code" = 'DE'
      AND p."grant_date"   BETWEEN 20161201 AND 20161231
      AND p."cpc"          IS NOT NULL
      AND p."filing_date"  IS NOT NULL
),                     -- 2) derive CPC level‑4 group (“A01”, “H04”, …)
cpc_grouped AS (
    SELECT
        "publication_number",
        FLOOR("filing_date" / 10000)                             AS "filing_year",
        REGEXP_SUBSTR("cpc_code", '^[A-Z][0-9]{2}')              AS "cpc_group"
    FROM base_pub
    WHERE REGEXP_SUBSTR("cpc_code", '^[A-Z][0-9]{2}') IS NOT NULL
),                     -- 3) one row per (publication, group, year)
distinct_pub_group AS (
    SELECT DISTINCT
        "cpc_group",
        "publication_number",
        "filing_year"
    FROM cpc_grouped
    WHERE "filing_year" > 0
),                     -- 4) annual filing counts
filing_counts AS (
    SELECT
        "cpc_group",
        "filing_year",
        COUNT(DISTINCT "publication_number")          AS "filing_count"
    FROM distinct_pub_group
    GROUP BY 1, 2
),                     -- 5) order rows per group (needed for recursion)
ordered_counts AS (
    SELECT
        "cpc_group",
        "filing_year",
        "filing_count",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group"
                           ORDER BY "filing_year")    AS "rn"
    FROM filing_counts
),                     -- 6) recursive EMA calculation  (EMA0 = filing_count0)
ema_calc (cpc_group, filing_year, filing_count, rn, ema) AS (
    -- seed (earliest year for each group)
    SELECT
        oc."cpc_group",
        oc."filing_year",
        oc."filing_count",
        oc."rn",
        CAST(oc."filing_count" AS FLOAT)              AS ema
    FROM ordered_counts oc
    WHERE oc."rn" = 1
    UNION ALL
    -- subsequent years:  EMA_t = 0.1 * x_t + 0.9 * EMA_(t‑1)
    SELECT
        oc."cpc_group",
        oc."filing_year",
        oc."filing_count",
        oc."rn",
        0.1 * oc."filing_count" + 0.9 * ec.ema        AS ema
    FROM ema_calc ec
    JOIN ordered_counts oc
      ON oc."cpc_group" = ec.cpc_group
     AND oc."rn"        = ec.rn + 1
),                     -- 7) pick best‑EMA year per CPC group
best_ema AS (
    SELECT
        cpc_group,
        filing_year                                   AS best_year,
        ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_group
                           ORDER BY ema DESC,
                                    filing_year DESC) AS rk
    FROM ema_calc
)
SELECT
    d."titleFull"              AS title_full,
    b.cpc_group,
    b.best_year
FROM best_ema b
JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON d."symbol" = b.cpc_group
WHERE d."level" = 4    -- level‑4 titles
  AND b.rk = 1          -- highest EMA per group
ORDER BY b.ema DESC NULLS LAST, b.cpc_group;