/*  Identify, for every CPC technology area at level‑5, the year in which it
    achieves its highest exponential moving average (α = 0.2) of patent
    filings.  Only the first CPC code of each patent is considered and only
    publications that have a valid filing date and a non‑empty application
    number are counted.                                              */
WITH RECURSIVE
/* --- 1) get the first CPC code for every publication ---------------------- */
FIRST_CPC AS (
    SELECT
        "publication_number",
        "filing_date",
        ("cpc")[0]:"code"::STRING      AS full_cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "filing_date" IS NOT NULL
      AND "filing_date" <> 0
      AND "application_number" IS NOT NULL
      AND "application_number" <> ''
      AND "cpc" IS NOT NULL
      AND ARRAY_SIZE("cpc") > 0
),
/* --- 2) aggregate yearly filing counts by CPC group (level‑5) ------------- */
YEARLY_FILINGS AS (
    SELECT
        /* level‑5 group, e.g.  H04L9                                           */
        REGEXP_SUBSTR(full_cpc_code , '^[A-Z][0-9]{2}[A-Z][0-9]+') AS cpc_group5,
        FLOOR("filing_date"/10000)                                  AS filing_year,
        COUNT(DISTINCT "publication_number")                        AS filings
    FROM FIRST_CPC
    GROUP BY 1,2
),
/* --- 3) order the years per group ---------------------------------------- */
ORDERED AS (
    SELECT
        cpc_group5,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group5 ORDER BY filing_year) AS rn
    FROM YEARLY_FILINGS
),
/* --- 4) recursively compute EMA with α = 0.2 ------------------------------ */
EMA AS (
    /*  seed row : first year -> EMA = filings                                 */
    SELECT
        cpc_group5,
        filing_year,
        filings::FLOAT AS ema,
        rn
    FROM ORDERED
    WHERE rn = 1

    UNION ALL

    /*  recursive step                                                         */
    SELECT
        o.cpc_group5,
        o.filing_year,
        0.2 * o.filings + 0.8 * e.ema        AS ema,
        o.rn
    FROM EMA e
    JOIN ORDERED o
      ON o.cpc_group5 = e.cpc_group5
     AND o.rn        = e.rn + 1
),
/* --- 5) pick, for each group, the year with the highest EMA --------------- */
BEST_YEAR AS (
    SELECT
        cpc_group5,
        filing_year          AS best_year,
        ema                  AS max_ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_group5
                           ORDER BY ema DESC, filing_year) AS rn
    FROM EMA
)
/* --- 6) attach full CPC title (level‑5) and return ------------------------ */
SELECT
    b.cpc_group5                       AS "CPC_GROUP_CODE",
    d."titleFull"                      AS "CPC_TITLE",
    b.best_year                        AS "BEST_YEAR",
    b.max_ema                          AS "MAX_EMA"
FROM BEST_YEAR b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON  d."level" = 5
  AND LEFT(d."symbol", LENGTH(b.cpc_group5)) = b.cpc_group5
WHERE b.rn = 1
ORDER BY b.max_ema DESC NULLS LAST,
         b.cpc_group5;