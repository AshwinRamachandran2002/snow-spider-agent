/*--------------------------------------------------------------------
  1.  Identify every ZIP code whose internal point lies within
      a 5-mile geodesic radius of the reference point 
      ( 47.685833 N , –122.191667 W ).

  2.  Attach 2015-5YR ACS demographic measures that already contain
      (a)  total population and
      (b)  per-capita income for each ZIP code.

  3.  Return, for every qualifying ZIP code, the required statistics
      and order them by average individual income (per-capita income)
      in descending order.
--------------------------------------------------------------------*/
WITH params AS (
    SELECT
        /* Reference point expressed as a GEOGRAPHY object               */
        ST_MAKEPOINT(-122.191667 , 47.685833)    AS "center_geom",
        /* 5 miles expressed in metres ( 1 mile ≈ 1 609.344 m )          */
        5 * 1609.344                             AS "radius_m"
)
SELECT
    z."zip_code"                                                   AS "zip_code",
    /* Population is already stored at ZIP level in the ACS table  */
    acs."total_pop"::NUMBER                                        AS "total_population",
    /* Per-capita income = average individual income               */
    ROUND(acs."income_per_capita"::NUMBER , 1)                     AS "average_individual_income"
FROM
    CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES.ZIP_CODES               z
JOIN
    CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR      acs
      ON acs."geo_id" = z."zip_code"
CROSS JOIN
    params
/* Keep only ZIP codes whose internal point is within 5 mi radius */
WHERE
    ST_DISTANCE(
        ST_MAKEPOINT(z."internal_point_lon", z."internal_point_lat"),
        params."center_geom"
    ) <= params."radius_m"
/* Highest average income first, omit any NULL values              */
ORDER BY
    "average_individual_income" DESC NULLS LAST;