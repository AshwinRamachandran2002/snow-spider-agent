WITH cat_counts AS (      -- 1. count every cause(category) per year
    SELECT  CI."db_year"            AS "year",
            C."pcf_violation_category"  AS "category",
            COUNT(*)                 AS "cnt"
    FROM    CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"  C
    JOIN    CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"    CI
           ON C."case_id" = CI."case_id"
    WHERE   C."pcf_violation_category" IS NOT NULL
      AND   C."pcf_violation_category" <> ''
    GROUP BY CI."db_year", C."pcf_violation_category"
),
ranked AS (                -- 2. rank the causes by frequency within each year
    SELECT  "year",
            "category",
            "cnt",
            ROW_NUMBER() OVER (PARTITION BY "year"
                               ORDER BY "cnt" DESC NULLS LAST, "category") AS "rnk"
    FROM    cat_counts
),
top2 AS (                  -- 3. keep only the two most frequent causes each year
    SELECT  "year",
            LISTAGG("category", '|') WITHIN GROUP (ORDER BY "rnk") AS "top2_pair"
    FROM    ranked
    WHERE   "rnk" <= 2
    GROUP BY "year"
    HAVING  COUNT(*) = 2              -- ensure the year actually has two causes
),
pair_freq AS (             -- 4. how many years share the same top-2 pair
    SELECT  "top2_pair",
            COUNT(*) AS "year_occurrences"
    FROM    top2
    GROUP BY "top2_pair"
),
distinct_year AS (         -- 5. years whose top-2 pair occurs only once
    SELECT  t."year"
    FROM    top2 t
    JOIN    pair_freq p
      ON    t."top2_pair" = p."top2_pair"
    WHERE   p."year_occurrences" = 1
)
SELECT  DISTINCT "year"
FROM    distinct_year
ORDER BY "year";