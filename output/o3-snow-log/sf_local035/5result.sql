WITH ordered AS (
    /* ------------------------------------------------------------------
       Order every single geolocation row exactly as requested
    ------------------------------------------------------------------ */
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng",
        ROW_NUMBER() OVER (
            ORDER BY
                "geolocation_state",
                "geolocation_city",
                "geolocation_zip_code_prefix",
                "geolocation_lat",
                "geolocation_lng"
        ) AS rn
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_GEOLOCATION
    WHERE "geolocation_lat" IS NOT NULL
      AND "geolocation_lng" IS NOT NULL
), calc AS (
    /* ------------------------------------------------------------------
       For every row, look at its immediate predecessor and
       compute the spherical-law-of-cosines distance
    ------------------------------------------------------------------ */
    SELECT
        /* current row (second city in the pair) */
        curr."geolocation_state"            AS curr_state,
        curr."geolocation_city"             AS curr_city,
        curr."geolocation_zip_code_prefix"  AS curr_zip,
        curr."geolocation_lat"              AS curr_lat,
        curr."geolocation_lng"              AS curr_lng,

        /* previous row (first city in the pair) */
        prev."geolocation_state"            AS prev_state,
        prev."geolocation_city"             AS prev_city,
        prev."geolocation_zip_code_prefix"  AS prev_zip,
        prev."geolocation_lat"              AS prev_lat,
        prev."geolocation_lng"              AS prev_lng,

        /* distance in kilometres */
        6371 *
        ACOS(
            LEAST( 1,
                GREATEST( -1,
                    COS(RADIANS(prev."geolocation_lat")) * COS(RADIANS(curr."geolocation_lat")) *
                    COS(RADIANS(curr."geolocation_lng") - RADIANS(prev."geolocation_lng")) +
                    SIN(RADIANS(prev."geolocation_lat")) * SIN(RADIANS(curr."geolocation_lat"))
                )
            )
        ) AS distance_km
    FROM ordered curr
    JOIN ordered prev
      ON curr.rn = prev.rn + 1         -- immediate predecessor
), max_dist AS (
    /* ------------------------------------------------------------------
       Keep only the pair with the greatest distance
    ------------------------------------------------------------------ */
    SELECT *
    FROM calc
    ORDER BY distance_km DESC NULLS LAST
    LIMIT 1
)
SELECT
    prev_state    AS first_city_state,
    prev_city     AS first_city_name,
    prev_zip      AS first_city_zip_prefix,
    curr_state    AS second_city_state,
    curr_city     AS second_city_name,
    curr_zip      AS second_city_zip_prefix,
    distance_km
FROM max_dist;