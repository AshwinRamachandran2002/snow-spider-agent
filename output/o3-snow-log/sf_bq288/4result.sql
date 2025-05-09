WITH state_asset_sums AS (
    SELECT
        "state_name",
        SUM("total_assets") AS "total_state_assets"
    FROM FDA.FDIC_BANKS.INSTITUTIONS
    WHERE
        "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
        AND "institution_name" ILIKE 'Bank%'
    GROUP BY
        "state_name"
),
top_state AS (
    SELECT
        "state_name"
    FROM
        state_asset_sums
    ORDER BY
        "total_state_assets" DESC NULLS LAST
    LIMIT 1
)
SELECT
    COUNT(DISTINCT "institution_name") AS "total_institutions_in_state"
FROM
    FDA.FDIC_BANKS.INSTITUTIONS
WHERE
    "state_name" = (SELECT "state_name" FROM top_state);