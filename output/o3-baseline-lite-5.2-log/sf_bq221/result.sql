/*  Identify, for every CPC technology area at hierarchy level‑5,
    the year that shows the highest exponential (α = 0.2) moving
    average of patent filings, using only the first CPC code of
    each patent that has a valid filing date and a non‑empty
    application number.                                                */

WITH base AS (   -------------------------------------------------- 1
    SELECT
        "publication_number",
        "application_number",
        "filing_date",
        FLOOR("filing_date"/10000)               AS filing_year,   -- YYYY
        ("cpc")[0]:"code"::STRING                AS cpc_code       -- first CPC
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "filing_date" IS NOT NULL
      AND "filing_date" <> 0
      AND COALESCE(TRIM("application_number"),'') <> ''
      AND ("cpc")[0]:"code" IS NOT NULL
),
mapped AS (      -------------------------------------------------- 2
    /* map every detailed CPC to its level‑5 ancestor                 */
    SELECT
        b."publication_number",
        b.filing_year,
        cd5."symbol"    AS group_code,
        cd5."titleFull" AS group_title
    FROM base b
    JOIN PATENTS.PATENTS.CPC_DEFINITION cd5
      ON  UPPER(b.cpc_code) LIKE UPPER(cd5."symbol") || '%'
     AND cd5."level" = 5
    QUALIFY ROW_NUMBER() OVER              -- keep longest match
            (PARTITION BY b."publication_number"
             ORDER BY LENGTH(cd5."symbol") DESC) = 1
),
yearly_counts AS ( ----------------------------------------------- 3
    SELECT
        group_code,
        MAX(group_title)          AS group_title,
        filing_year               AS yr,
        COUNT(*)                  AS cnt
    FROM mapped
    GROUP BY group_code, filing_year
),
ema_calc AS (    -------------------------------------------------- 4
    /* EMA_yr = Σ cnt_k * α * (1‑α)^(yr‑k) for k ≤ yr                */
    SELECT
        c1.group_code,
        c1.group_title,
        c1.yr,
        SUM(0.2 * c2.cnt * POWER(0.8, c1.yr - c2.yr)) AS ema
    FROM yearly_counts c1
    JOIN yearly_counts c2
      ON  c1.group_code = c2.group_code
     AND c2.yr        <= c1.yr
    GROUP BY c1.group_code, c1.group_title, c1.yr
),
best_years AS (  -------------------------------------------------- 5
    SELECT
        group_code,
        group_title,
        yr        AS best_year,
        ema       AS max_ema,
        ROW_NUMBER() OVER
            (PARTITION BY group_code
             ORDER BY ema DESC, yr ASC) AS rn
    FROM ema_calc
)
SELECT
    group_title,
    group_code,
    best_year,
    max_ema
FROM best_years
WHERE rn = 1
ORDER BY max_ema DESC NULLS LAST, group_code;