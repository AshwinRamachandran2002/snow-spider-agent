/*======================================================================
  Identify, for every level‑5 CPC technology area, the year in which
  the exponential moving average (α = 0.2) of patent filings reaches
  its maximum.  Result includes CPC symbol, full CPC title, best year,
  and the corresponding EMA value.
======================================================================*/
WITH RECURSIVE

/*--------------------------------------------------------------------
  1.  Extract first CPC code, build level‑5 CPC symbol, and filing year
----------------------------------------------------------------------*/
base AS (
    SELECT
        /* first CPC code in the list */
        ( "cpc"[0]:"code" )::STRING                                           AS "FIRST_CPC_CODE",

        /* derive level‑5 CPC group symbol (main group, e.g. G06F17/00) */
        IFF(
            POSITION('/' IN ( "cpc"[0]:"code" )::STRING ) > 0,
            CONCAT( SPLIT_PART( ( "cpc"[0]:"code" )::STRING , '/', 1 ), '/00' ),
            ( "cpc"[0]:"code" )::STRING
        )                                                                     AS "CPC_GROUP_CODE",

        /* convert filing date  YYYYMMDD → YYYY */
        FLOOR( "filing_date" / 10000 )                                        AS "FILING_YEAR"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "filing_date"       IS NOT NULL
      AND "application_number" IS NOT NULL
      AND "application_number" <> ''
      AND "cpc"[0] IS NOT NULL
),

/*--------------------------------------------------------------------
  2.  Yearly filing counts per CPC group
----------------------------------------------------------------------*/
year_counts AS (
    SELECT
        "CPC_GROUP_CODE",
        "FILING_YEAR",
        COUNT(*)                                          AS "YEAR_COUNT"
    FROM base
    GROUP BY
        "CPC_GROUP_CODE",
        "FILING_YEAR"
),

/*--------------------------------------------------------------------
  3.  Chronological ordering within each CPC group
----------------------------------------------------------------------*/
ordered_counts AS (
    SELECT
        "CPC_GROUP_CODE",
        "FILING_YEAR",
        "YEAR_COUNT",
        ROW_NUMBER() OVER (
            PARTITION BY "CPC_GROUP_CODE"
            ORDER BY      "FILING_YEAR"
        )                                                 AS rn
    FROM year_counts
),

/*--------------------------------------------------------------------
  4.  Recursive computation of EMA (α = 0.2)
      EMA₁ = YEAR_COUNT₁
      EMAₜ = 0.2·YEAR_COUNTₜ + 0.8·EMA₍ₜ₋₁₎
----------------------------------------------------------------------*/
ema AS (
      /* seed row: first year in each group */
      SELECT
          oc."CPC_GROUP_CODE",
          oc."FILING_YEAR",
          oc."YEAR_COUNT",
          CAST(oc."YEAR_COUNT" AS DOUBLE)                AS "EMA_VALUE",
          oc.rn
      FROM ordered_counts oc
      WHERE oc.rn = 1

      UNION ALL

      /* recursive step */
      SELECT
          oc."CPC_GROUP_CODE",
          oc."FILING_YEAR",
          oc."YEAR_COUNT",
          0.2 * oc."YEAR_COUNT" + 0.8 * e."EMA_VALUE"    AS "EMA_VALUE",
          oc.rn
      FROM ema e
      JOIN ordered_counts oc
        ON  oc."CPC_GROUP_CODE" = e."CPC_GROUP_CODE"
       AND oc.rn               = e.rn + 1
),

/*--------------------------------------------------------------------
  5.  Select the year with the highest EMA for each CPC group
----------------------------------------------------------------------*/
best_year_per_group AS (
    SELECT
        e."CPC_GROUP_CODE",
        e."FILING_YEAR"                                   AS "BEST_YEAR",
        e."EMA_VALUE"                                    AS "MAX_EMA",
        ROW_NUMBER() OVER (
            PARTITION BY e."CPC_GROUP_CODE"
            ORDER BY e."EMA_VALUE" DESC NULLS LAST,
                     e."FILING_YEAR"                     /* tie‑breaker */
        )                                                AS rn_best
    FROM ema e
)

/*--------------------------------------------------------------------
  6.  Final output with CPC full title
----------------------------------------------------------------------*/
SELECT
    b."CPC_GROUP_CODE"                                   AS "CPC_SYMBOL_L5",
    d."titleFull"                                        AS "CPC_FULL_TITLE",
    b."BEST_YEAR",
    b."MAX_EMA"
FROM best_year_per_group b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b."CPC_GROUP_CODE"
      AND d."level"  = 5                                  /* level‑5 only */
WHERE b.rn_best = 1
ORDER BY
    "MAX_EMA"        DESC NULLS LAST,
    "CPC_SYMBOL_L5";