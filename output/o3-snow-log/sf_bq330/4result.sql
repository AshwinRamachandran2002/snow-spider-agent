WITH colorado_zip_geoms AS (           -- 1. CO ZIP-code geometries
    SELECT
        z."zip_code",
        TO_GEOGRAPHY(z."zip_code_geom")                   AS "zip_geom"
    FROM FDA.GEO_US_BOUNDARIES.ZIP_CODES z
    WHERE z."state_code" = 'CO'
),

colorado_bank_counts AS (              -- 2. # of bank locations in each CO ZIP
    SELECT
        l."zip_code",
        COUNT(*)                                         AS "bank_count"
    FROM FDA.FDIC_BANKS.LOCATIONS l
    WHERE l."state" = 'CO'
    GROUP BY l."zip_code"
),

zip_with_banks AS (                    -- 3. keep only ZIPs that have both geometry & banks
    SELECT
        b."zip_code",
        b."bank_count",
        z."zip_geom"
    FROM colorado_bank_counts  b
    JOIN colorado_zip_geoms    z
      ON b."zip_code" = z."zip_code"
),

zip_blockgroup_overlap AS (            -- 4. area overlap between each ZIP & each BG
    SELECT
        z."zip_code",
        bg."geo_id"                                    AS "blockgroup_id",
        ST_AREA(
            ST_INTERSECTION(
                z."zip_geom",
                TO_GEOGRAPHY(bg."blockgroup_geom")
            )
        )                                              AS "intersect_area",
        ST_AREA(TO_GEOGRAPHY(bg."blockgroup_geom"))    AS "blockgroup_area",
        z."bank_count"
    FROM zip_with_banks z
    JOIN FDA.GEO_CENSUS_BLOCKGROUPS.US_BLOCKGROUPS_NATIONAL bg
      ON ST_INTERSECTS(
             z."zip_geom",
             TO_GEOGRAPHY(bg."blockgroup_geom")
         )
),

distributed_banks AS (                 -- 5. distribute ZIP’s banks to BGs by overlap ratio
    SELECT
        "zip_code",
        "blockgroup_id",
        ("bank_count" * ("intersect_area" / "blockgroup_area"))   AS "banks_in_blockgroup"
    FROM zip_blockgroup_overlap
    WHERE "intersect_area" > 0
),

max_banks_per_zip AS (                 -- 6. highest bank count found in any BG for each ZIP
    SELECT
        "zip_code",
        MAX("banks_in_blockgroup") AS "max_banks_per_blockgroup"
    FROM distributed_banks
    GROUP BY "zip_code"
)

-- 7. Colorado ZIP with greatest concentration (highest banks-per-BG value)
SELECT
    "zip_code",
    ROUND("max_banks_per_blockgroup", 4) AS "max_banks_per_blockgroup"
FROM max_banks_per_zip
ORDER BY "max_banks_per_blockgroup" DESC NULLS LAST
LIMIT 1;