/* -----------------------------------------------------------
   Highest EMA (α = 0.2) patent-filing year for each
   CPC level-5 group – Snowflake SQL
----------------------------------------------------------- */
WITH RECURSIVE
/* 1. First CPC code per publication with a valid filing date */
first_cpc AS (
    SELECT
        p."publication_number",
        f.value:"code"::STRING                                      AS "cpc_code",
        TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD')             AS filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc") f
    WHERE f.value:"first"::BOOLEAN = TRUE
      AND p."application_number" IS NOT NULL
      AND p."filing_date"        IS NOT NULL
      AND TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY p."publication_number"
                               ORDER BY f.index) = 1
),
/* 2. Yearly filing counts per CPC level-5 group (first 4 chars) */
year_counts AS (
    SELECT
        SUBSTR("cpc_code",1,4)                    AS group_symbol,
        YEAR(filing_dt)                           AS yr,
        COUNT(*)                                  AS year_count
    FROM first_cpc
    GROUP BY group_symbol, yr
),
/* 3. Order years within each group                          */
ordered AS (
    SELECT
        group_symbol,
        yr,
        year_count,
        ROW_NUMBER() OVER (PARTITION BY group_symbol ORDER BY yr) AS rn
    FROM year_counts
),
/* 4. Recursive EMA (α = 0.2) calculation                    */
ema_calc AS (
        /* anchor row: first year of each group */
        SELECT
            group_symbol,
            yr,
            year_count,
            year_count * 0.2                       AS ema,
            rn
        FROM ordered
        WHERE rn = 1

        UNION ALL

        /* recursion over subsequent years */
        SELECT
            o.group_symbol,
            o.yr,
            o.year_count,
            0.2 * o.year_count + 0.8 * e.ema       AS ema,
            o.rn
        FROM ema_calc e
        JOIN ordered o
          ON  o.group_symbol = e.group_symbol
         AND o.rn         = e.rn + 1
),
/* 5. Select the year with the highest EMA for each group     */
best_year AS (
    SELECT
        group_symbol,
        yr                         AS best_year,
        ema,
        ROW_NUMBER() OVER (PARTITION BY group_symbol
                           ORDER BY ema DESC, yr ASC) AS rk
    FROM ema_calc
)
/* 6. Attach CPC titles and present results                   */
SELECT
    b.group_symbol               AS "cpc_group",
    d."titleFull"                AS "cpc_title",
    b.best_year                  AS "best_year",
    ROUND(b.ema,4)               AS "max_ema"
FROM best_year b
JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON d."symbol" = b.group_symbol
WHERE d."level" = 5
  AND b.rk = 1
ORDER BY "max_ema" DESC NULLS LAST;