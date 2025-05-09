WITH filtered_banks AS (
    SELECT 
        "state"               AS state_abbr ,
        "total_assets"
    FROM FDA.FDIC_BANKS.INSTITUTIONS
    WHERE "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
      AND "institution_name" ILIKE 'Bank%'          -- names starting with 'Bank'
      AND "total_assets" IS NOT NULL                -- ensure assets available
),
state_asset_sums AS (                               -- sum assets per state
    SELECT 
        state_abbr,
        SUM("total_assets") AS sum_assets
    FROM filtered_banks
    GROUP BY state_abbr
),
top_state AS (                                      -- state with highest summed assets
    SELECT 
        state_abbr
    FROM state_asset_sums
    ORDER BY sum_assets DESC NULLS LAST
    LIMIT 1
)
SELECT 
    COUNT(*) AS total_institutions                  -- total number of institutions in that state
FROM FDA.FDIC_BANKS.INSTITUTIONS
WHERE "state" IN (SELECT state_abbr FROM top_state);