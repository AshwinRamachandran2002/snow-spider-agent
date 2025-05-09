WITH latest_week AS (               -- most recent week in the dataset
    SELECT MAX("week") AS latest_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
target_week AS (                    -- closest available week ≤ one-year-prior
    SELECT MAX("week") AS target_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN latest_week lw
      ON tr."week" <= DATEADD(year, -1, lw.latest_week)
),
ranked AS (                          -- rank terms for the target week
    SELECT
        tr."term",
        tr."rank",
        tr."percent_gain",
        tr."week",
        tr."dma_name",
        ROW_NUMBER() OVER (
            ORDER BY tr."rank" ASC,
                     tr."percent_gain" DESC NULLS LAST
        ) AS rn
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN target_week tw
      ON tr."week" = tw.target_week
)
SELECT "term",
       "rank",
       "percent_gain",
       "week",
       "dma_name"
FROM ranked
WHERE rn = 1;