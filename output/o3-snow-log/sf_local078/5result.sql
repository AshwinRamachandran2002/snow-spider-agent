WITH ranked_metrics AS (
    /* 1.  For every interest_id choose the row that contains its
           highest "composition" value (ties broken by earliest month)  */
    SELECT 
        m."interest_id",
        m."month_year",
        m."composition",
        ROW_NUMBER() OVER (
            PARTITION BY m."interest_id" 
            ORDER BY m."composition" DESC NULLS LAST, m."month_year"
        ) AS rn
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_METRICS" m
),
best_metrics AS (
    /* 2. Keep only the “best” (highest-composition) row for each category */
    SELECT 
        "interest_id",
        "month_year",
        "composition"
    FROM ranked_metrics
    WHERE rn = 1
),
best_with_name AS (
    /* 3. Join to INTEREST_MAP to get the readable interest name            */
    SELECT
        imap."interest_name",
        bm."interest_id",
        bm."month_year",
        bm."composition"
    FROM best_metrics bm
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_MAP" imap
           ON imap."id" = bm."interest_id"
),
ordered_best AS (
    /* 4. Rank categories by their maximum composition (high→low & low→high) */
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY "composition" DESC NULLS LAST) AS r_desc,
        DENSE_RANK() OVER (ORDER BY "composition" ASC  NULLS LAST) AS r_asc
    FROM best_with_name
)
/* 5.  Return the top-10 and bottom-10 categories                      */
SELECT
    'TOP 10'                                                AS "group",
    TO_CHAR(TO_DATE("month_year", 'MM-YYYY'), 'MM-YYYY')    AS "time",
    "interest_name",
    ROUND("composition", 4)                                 AS "composition"
FROM ordered_best
WHERE r_desc <= 10

UNION ALL

SELECT
    'BOTTOM 10'                                             AS "group",
    TO_CHAR(TO_DATE("month_year", 'MM-YYYY'), 'MM-YYYY')    AS "time",
    "interest_name",
    ROUND("composition", 4)                                 AS "composition"
FROM ordered_best
WHERE r_asc <= 10
ORDER BY "group", "composition" DESC NULLS LAST;