/*  Highest-EMA year (α = 0.20) for each CPC subclass (level-5)   */
WITH RECURSIVE
/* 1) first CPC code + filing year                                 */
first_codes AS (
    SELECT
        SUBSTR(f.value:"code"::STRING, 1, 4)      AS "cpc_subclass",
        FLOOR(p."filing_date" / 10000)            AS "year"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") f
    WHERE f.index = 0
      AND p."filing_date" IS NOT NULL
      AND p."application_number" IS NOT NULL
),
/* 2) annual counts                                                */
yearly_counts AS (
    SELECT
        "cpc_subclass",
        "year",
        COUNT(*)                                   AS "filings"
    FROM first_codes
    GROUP BY "cpc_subclass", "year"
),
/* 3) rank years within each subclass                              */
ranked_years AS (
    SELECT
        yc.*,
        ROW_NUMBER() OVER (PARTITION BY "cpc_subclass"
                           ORDER BY "year")        AS "rn"
    FROM yearly_counts yc
),
/* 4) smoothing factor                                             */
params AS (SELECT 0.2::FLOAT AS "alpha"),
/* 5) recursive EMA                                                */
ema_calc AS (
    /* anchor row                                                  */
    SELECT
        r."cpc_subclass",
        r."year",
        r."filings",
        r."filings"::FLOAT                       AS "ema",
        r."rn"
    FROM ranked_years r
    WHERE r."rn" = 1

    UNION ALL

    /* recursive rows                                              */
    SELECT
        nxt."cpc_subclass",
        nxt."year",
        nxt."filings",
        params."alpha" * nxt."filings"
          + (1 - params."alpha") * prv."ema"     AS "ema",
        nxt."rn"
    FROM ema_calc prv
    JOIN ranked_years nxt
      ON nxt."cpc_subclass" = prv."cpc_subclass"
     AND nxt."rn"          = prv."rn" + 1
    CROSS JOIN params
),
/* 6) best EMA year per subclass                                   */
best_years AS (
    SELECT
        ec."cpc_subclass",
        ec."year"                                 AS "best_year",
        ec."ema",
        ROW_NUMBER() OVER (PARTITION BY ec."cpc_subclass"
                           ORDER BY ec."ema" DESC) AS "rnk"
    FROM ema_calc ec
),
top_years AS (
    SELECT
        "cpc_subclass",
        "best_year",
        "ema"
    FROM best_years
    WHERE "rnk" = 1
)
/* 7) attach CPC titles                                            */
SELECT
    cd."symbol"        AS "cpc_code",
    cd."titleFull"     AS "cpc_title",
    ty."best_year",
    ty."ema"           AS "highest_ema"
FROM top_years ty
JOIN PATENTS.PATENTS.CPC_DEFINITION cd
  ON cd."symbol" = ty."cpc_subclass"
WHERE cd."level" = 5
ORDER BY cd."symbol" NULLS LAST;