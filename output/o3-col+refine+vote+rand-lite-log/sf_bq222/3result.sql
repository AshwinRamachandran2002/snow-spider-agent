WITH RECURSIVE
/* 1) CPC groups that appear in German patents granted during December-2016 */
dec16_groups AS (
    SELECT DISTINCT
           SPLIT_PART(c.value:"code"::STRING , '/' , 0) AS "cpc_group"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."cpc") c
    WHERE p."country_code" = 'DE'
      AND p."grant_date"  BETWEEN 20161201 AND 20161231
),

/* 2) Annual publication counts for those groups (all German patents) */
annual_counts AS (
    SELECT
        SPLIT_PART(c.value:"code"::STRING , '/' , 0)  AS "cpc_group",
        FLOOR(p."publication_date" / 10000)           AS "year",
        COUNT(*)                                      AS "filings"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."cpc") c
    WHERE p."country_code" = 'DE'
      AND p."publication_date" IS NOT NULL
      AND SPLIT_PART(c.value:"code"::STRING , '/' , 0)
             IN (SELECT "cpc_group" FROM dec16_groups)
    GROUP BY 1, 2
),

/* 3) Chronological rank within each group */
years_ranked AS (
    SELECT
        "cpc_group",
        "year",
        "filings",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group" ORDER BY "year") AS "rn"
    FROM annual_counts
),

/* 4) Exponential moving average (α = 0.1) */
ema AS (
    -- anchor row
    SELECT
        "cpc_group",
        "year",
        "filings",
        "rn",
        "filings"::FLOAT AS "ema_value"
    FROM years_ranked
    WHERE "rn" = 1

    UNION ALL

    -- recursive step
    SELECT
        n."cpc_group",
        n."year",
        n."filings",
        n."rn",
        0.1 * n."filings" + 0.9 * e."ema_value" AS "ema_value"
    FROM ema e
    JOIN years_ranked n
      ON n."cpc_group" = e."cpc_group"
     AND n."rn"        = e."rn" + 1
),

/* 5) Year of maximum EMA per group */
best_year_per_group AS (
    SELECT
        "cpc_group",
        "year" AS "best_year",
        "ema_value",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group"
                           ORDER BY "ema_value" DESC, "year" ASC) AS "rnk"
    FROM ema
),

/* 6) CPC class (level-4) titles */
class_titles AS (
    SELECT
        "symbol",
        "titleFull",
        ROW_NUMBER() OVER (PARTITION BY "symbol" ORDER BY "symbol") AS rn
    FROM PATENTS.PATENTS.CPC_DEFINITION
    WHERE "level" = 4
    QUALIFY rn = 1
)

/* 7) Final result */
SELECT
    ct."titleFull" AS "title_full",
    b."cpc_group",
    b."best_year"
FROM best_year_per_group b
LEFT JOIN class_titles ct
       ON ct."symbol" = SUBSTR(b."cpc_group", 1, 3)
WHERE b."rnk" = 1
ORDER BY ct."titleFull", b."cpc_group";