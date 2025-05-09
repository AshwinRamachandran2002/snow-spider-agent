/*  Highest exponential-moving-average (α = 0.1) filing year
    for each German CPC sub-class that appears in patents
    granted during December-2016                                    */

WITH dec16_pub AS (          -- German publications granted in Dec-2016
    SELECT "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'DE'
      AND "grant_date" BETWEEN 20161201 AND 20161231
),

dec16_cls AS (               -- relevant CPC sub-classes (first 4 chars)
    SELECT DISTINCT SUBSTRING(f.value:"code"::STRING, 1, 4) AS "cpc_subclass"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    JOIN dec16_pub d
      ON p."publication_number" = d."publication_number"
    CROSS JOIN LATERAL FLATTEN(input => p."cpc") f
),

per_year AS (                -- yearly DE publication counts for those classes
    SELECT
        SUBSTRING(f.value:"code"::STRING, 1, 4)              AS "cpc_subclass",
        FLOOR(p."publication_date" / 10000)                  AS "pub_year",
        COUNT(DISTINCT p."publication_number")               AS "pub_count"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    CROSS JOIN LATERAL FLATTEN(input => p."cpc") f
    WHERE p."country_code" = 'DE'
      AND SUBSTRING(f.value:"code"::STRING, 1, 4) IN (SELECT "cpc_subclass" FROM dec16_cls)
      AND p."publication_date" IS NOT NULL
    GROUP BY 1, 2
    HAVING "pub_year" > 0
),

ordered AS (                 -- impose an order within each sub-class
    SELECT
        "cpc_subclass",
        "pub_year",
        "pub_count",
        ROW_NUMBER() OVER (PARTITION BY "cpc_subclass" ORDER BY "pub_year") AS rn
    FROM per_year
),

/*  Recursive EMA:
    EMA_1 = pub_count_1
    EMA_n = 0.1*pub_count_n + 0.9*EMA_{n-1}                                */
recursive_ema AS (
    -- seed row (first year for each sub-class)
    SELECT
        "cpc_subclass",
        "pub_year",
        "pub_count",
        rn,
        "pub_count"::FLOAT AS ema_val
    FROM ordered
    WHERE rn = 1

    UNION ALL

    -- subsequent years
    SELECT
        o."cpc_subclass",
        o."pub_year",
        o."pub_count",
        o.rn,
        0.1 * o."pub_count" + 0.9 * r.ema_val    AS ema_val
    FROM ordered        o
    JOIN recursive_ema  r
      ON  o."cpc_subclass" = r."cpc_subclass"
     AND o.rn           = r.rn + 1
),

best_year AS (               -- pick the year with the highest EMA for each sub-class
    SELECT
        "cpc_subclass",
        "pub_year"  AS best_year,
        ROW_NUMBER() OVER (PARTITION BY "cpc_subclass"
                           ORDER BY ema_val DESC, "pub_year") AS rn
    FROM recursive_ema
)

SELECT
    cd."titleFull"                  AS technology_area_title,
    b."cpc_subclass"                AS cpc_group,
    b.best_year
FROM best_year b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = b."cpc_subclass"
WHERE b.rn = 1
ORDER BY b."cpc_subclass";