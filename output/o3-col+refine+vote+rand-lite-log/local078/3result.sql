WITH max_per_interest AS (
    /* 1. highest composition value for every interest category */
    SELECT
        "interest_id",
        MAX("composition") AS max_comp
    FROM "interest_metrics"
    GROUP BY "interest_id"
),
max_rows AS (
    /* 2. grab the row(s) where that max occurred                      */
    SELECT
        im."month_year",
        im."interest_id",
        im."composition"
    FROM "interest_metrics" AS im
    JOIN max_per_interest AS mpi
      ON im."interest_id" = mpi."interest_id"
     AND im."composition"  = mpi.max_comp
),
with_names AS (
    /* 3. add readable interest names                                  */
    SELECT
        mr."month_year",
        mp."interest_name",
        mr."composition"
    FROM max_rows AS mr
    JOIN "interest_map" AS mp
      ON mp."id" = mr."interest_id"
),
top_10 AS (
    /* 4a. top-10 categories by their max composition                   */
    SELECT
        "month_year",
        "interest_name",
        "composition"
    FROM with_names
    ORDER BY "composition" DESC
    LIMIT 10
),
bottom_10 AS (
    /* 4b. bottom-10 categories by their max composition                */
    SELECT
        "month_year",
        "interest_name",
        "composition"
    FROM with_names
    ORDER BY "composition" ASC
    LIMIT 10
)
/* 5. deliver the two lists (top first, then bottom)                   */
SELECT * FROM top_10
UNION ALL
SELECT * FROM bottom_10;