/*--------------------------------------------------------------------
  Percentage of stations that had valid temperature, maximum, and
  minimum values (not NULL and not 9999.9) on at least 90 % of the
  calendar days in 2022.

  – Uses only the 2022 GSOD daily table.
  – Counts one row per station-day; GSOD provides at most one per day.
  – A year-length of 365 days is assumed for 2022.
--------------------------------------------------------------------*/
WITH daily_validity AS (                         -- 1.  daily validity flag
    SELECT
        "stn"                           AS station_id,
        /* 1 = this day has valid temperature data, 0 = it does not */
        CASE
            WHEN   "temp" IS NOT NULL AND "temp" <> 9999.9
               AND "max"  IS NOT NULL AND "max"  <> 9999.9
               AND "min"  IS NOT NULL AND "min"  <> 9999.9
            THEN 1 ELSE 0
        END                               AS valid_flag
    FROM NOAA_DATA.NOAA_GSOD.GSOD2022
    WHERE "stn" <> '999999'               -- exclude invalid station id
),

station_day_counts AS (                         -- 2.  aggregate by station
    SELECT
        station_id,
        COUNT(*)                               AS total_days_reported,  -- should be ≤ 365
        SUM(valid_flag)                        AS valid_days
    FROM daily_validity
    GROUP BY station_id
),

station_qualification AS (                      -- 3.  determine qualification
    SELECT
        station_id,
        valid_days,
        /* station qualifies if ≥ 90 % of 365 calendar days are valid */
        CASE WHEN valid_days >= 0.9 * 365 THEN 1 ELSE 0 END AS qualifies
    FROM station_day_counts
)

/*--------------------------------------------------------------------
   4.  final percentage of qualifying stations
--------------------------------------------------------------------*/
SELECT
    ROUND( 100.0 * SUM(qualifies) / COUNT(*), 2 )  AS "PCT_STATIONS_≥90PCT_VALID_2022"
FROM station_qualification;