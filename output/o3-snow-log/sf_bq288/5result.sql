WITH bank_assets_by_state AS (
    SELECT
        "state_name",
        SUM(COALESCE("total_assets", 0)) AS sum_assets
    FROM FDA.FDIC_BANKS.INSTITUTIONS
    WHERE
        "institution_name" ILIKE 'Bank%'                      -- names starting with 'Bank'
        AND "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
    GROUP BY
        "state_name"
),
top_state AS (                                                  -- state with highest summed assets
    SELECT
        "state_name"
    FROM bank_assets_by_state
    ORDER BY
        sum_assets DESC NULLS LAST
    LIMIT 1
)
SELECT
    COUNT(DISTINCT i."institution_name") AS total_institutions  -- total institutions in that state
FROM
    FDA.FDIC_BANKS.INSTITUTIONS i
JOIN
    top_state t
ON
    i."state_name" = t."state_name";