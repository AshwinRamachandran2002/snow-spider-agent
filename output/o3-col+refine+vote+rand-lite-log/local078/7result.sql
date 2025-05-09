/*  Top-10 and Bottom-10 interest categories by their peak (highest) composition
    value across all months.                                          */

WITH peaks AS (
    /* pick the month where each interest_id reaches its maximum composition
       (if several months tie, keep the earliest month_year) */
    SELECT  im."interest_id",
            mp."interest_name",
            im."month_year",
            im."composition",
            ROW_NUMBER() OVER (
                PARTITION BY im."interest_id"
                ORDER BY im."composition" DESC,       -- highest first
                         im."month_year"              -- earliest month if tie
            ) AS rn
    FROM    "interest_metrics"  AS im
    JOIN    "interest_map"      AS mp
           ON mp."id" = im."interest_id"
),
peak_per_interest AS (
    /* one record per interest category (its peak month & value) */
    SELECT  "interest_id",
            "interest_name",
            "month_year",
            "composition"
    FROM    peaks
    WHERE   rn = 1
),
ranked AS (
    /* simultaneously rank peaks from highest → lowest and vice-versa */
    SELECT  *,
            RANK() OVER (ORDER BY "composition" DESC) AS desc_rank,
            RANK() OVER (ORDER BY "composition" ASC)  AS asc_rank
    FROM    peak_per_interest
)
SELECT  "month_year"  AS "time_MM-YYYY",
        "interest_name",
        "composition"
FROM    ranked
WHERE   desc_rank <= 10        -- top 10 peaks
    OR  asc_rank  <= 10        -- bottom 10 peaks
ORDER BY "composition" DESC;   -- shows TOP-10 first then BOTTOM-10