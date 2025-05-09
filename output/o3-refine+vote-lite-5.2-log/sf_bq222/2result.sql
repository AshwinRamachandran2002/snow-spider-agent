WITH RECURSIVE

/* ------------------------------------------------------------------ */
/* 1.  German patent publications dated December 2016 (grant          */
/*     or publication in that month)                                  */
/* ------------------------------------------------------------------ */
de_dec2016 AS (
    SELECT  p."publication_number",
            p."filing_date",               -- YYYYMMDD as NUMBER
            p."cpc"
    FROM    PATENTS.PATENTS.PUBLICATIONS p
    WHERE   p."country_code" = 'DE'
      AND  (p."grant_date"       BETWEEN 20161201 AND 20161231
            OR
            p."publication_date" BETWEEN 20161201 AND 20161231)
      AND   p."cpc" IS NOT NULL
      AND   p."filing_date" IS NOT NULL
),

/* ------------------------------------------------------------------ */
/* 2.  Split CPC list into rows                                        */
/* ------------------------------------------------------------------ */
cpc_flat AS (
    SELECT  d."publication_number",
            d."filing_date",
            TRIM(f.value:"code"::string) AS full_cpc_code
    FROM    de_dec2016 d,
            LATERAL FLATTEN (INPUT => d."cpc") f
),

/* ------------------------------------------------------------------ */
/* 3.  Collapse to level‑4 CPC group  (e.g. H04L9/0844 → H04L9/00)     */
/* ------------------------------------------------------------------ */
level4 AS (
    SELECT  "publication_number",
            "filing_date",
            REGEXP_REPLACE(
                full_cpc_code,
                '^([A-Z][0-9]{2}[A-Z][0-9]+)/.*$',
                '\\1/00'
            ) AS cpc_group
    FROM    cpc_flat
),

/* ------------------------------------------------------------------ */
/* 4.  Attach CPC group title (if available)                           */
/* ------------------------------------------------------------------ */
with_title AS (
    SELECT  l."publication_number",
            l."filing_date",
            l.cpc_group,
            d."titleFull" AS title_full
    FROM    level4 l
    LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
           ON d."symbol" = l.cpc_group
),

/* ------------------------------------------------------------------ */
/* 5.  Yearly counts of filings per CPC group                          */
/* ------------------------------------------------------------------ */
year_counts AS (
    SELECT  cpc_group,
            COALESCE(title_full, 'N/A') AS title_full,
            FLOOR("filing_date" / 10000)        AS filing_year,  -- YYYY
            COUNT(DISTINCT "publication_number") AS filings
    FROM    with_title
    GROUP BY cpc_group, title_full, filing_year
),

ordered AS (
    SELECT  cpc_group,
            title_full,
            filing_year,
            filings,
            ROW_NUMBER() OVER (PARTITION BY cpc_group
                               ORDER BY filing_year) AS rn
    FROM    year_counts
),

/* ------------------------------------------------------------------ */
/* 6.  Recursive EMA computation  (α = 0.1)                            */
/* ------------------------------------------------------------------ */
ema_calc AS (
    /* anchor row (first year per CPC group) */
    SELECT  o.cpc_group,
            o.title_full,
            o.filing_year,
            o.filings,
            o.rn,
            o.filings * 0.1 AS ema
    FROM    ordered o
    WHERE   o.rn = 1

    UNION ALL

    /* recursive step */
    SELECT  o.cpc_group,
            o.title_full,
            o.filing_year,
            o.filings,
            o.rn,
            0.1 * o.filings + 0.9 * r.ema AS ema
    FROM    ordered  o
    JOIN    ema_calc r
          ON o.cpc_group = r.cpc_group
         AND o.rn        = r.rn + 1
),

/* ------------------------------------------------------------------ */
/* 7.  Identify best year per CPC group                                */
/* ------------------------------------------------------------------ */
best_years AS (
    SELECT  cpc_group,
            title_full,
            filing_year  AS best_year,
            ema,
            ROW_NUMBER() OVER (PARTITION BY cpc_group
                               ORDER BY ema DESC, filing_year) AS rk
    FROM    ema_calc
)

/* ------------------------------------------------------------------ */
/* 8.  Final result                                                    */
/* ------------------------------------------------------------------ */
SELECT  title_full      AS "TITLE_FULL",
        cpc_group       AS "CPC_GROUP",
        best_year       AS "YEAR_WITH_HIGHEST_EMA"
FROM    best_years
WHERE   rk = 1
ORDER BY ema DESC NULLS LAST, cpc_group;