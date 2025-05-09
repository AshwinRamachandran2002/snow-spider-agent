/*  Per-city “hurricane” activity using the Storm-Data tables
    ---------------------------------------------------------
    • Every Storm-Data table listed in the catalog is UNIONed.
    • A “hurricane” row is any record whose EVENT_TYPE contains the
      word “hurricane” (case-insensitive).
    • The county/zone FIPS (CZ_FIPS_CODE) is used here as a ZIP-code
      surrogate and CZ_NAME is treated as the city/area description.
    • Each unique EPISODE_ID is regarded as one named hurricane
      affecting that locality; the list of those IDs is returned.
*/

WITH hurricanes AS (

    /* ---------------- 1956 ---------------- */
    SELECT  "state",
            "cz_fips_code"  AS "zip_code",
            "cz_name"       AS "city",
            "episode_id"    AS "hurricane_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1956"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 1960 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1960"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 1962 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1962"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 1964 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1964"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 1968 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1968"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 1985 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1985"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 2000 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2000"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 2002 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2002"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 2011 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2011"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 2019 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 2021 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
    WHERE   "event_type" ILIKE '%hurricane%'

    UNION ALL
    /* ---------------- 2023 ---------------- */
    SELECT  "state", "cz_fips_code", "cz_name", "episode_id"
    FROM    "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
    WHERE   "event_type" ILIKE '%hurricane%'
)

SELECT
    "city",
    "zip_code",
    "state",
    COUNT( DISTINCT "hurricane_id" )                                        AS "hurricane_count",
    LISTAGG( DISTINCT "hurricane_id", ', ' )
        WITHIN GROUP ( ORDER BY "hurricane_id" )                            AS "hurricane_names"
FROM   hurricanes
GROUP BY
    "city",
    "zip_code",
    "state"
ORDER BY
    "hurricane_count" DESC NULLS LAST;