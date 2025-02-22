-- Task: Find the top 5 states with the highest total number of storm events from 1980 to 1995 inclusive, based on the sum of event counts across these years. Please use state abbreviations.
WITH per_year_top_states AS (

  SELECT "state", COUNT("event_id") AS "event_count", '1980' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1980"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1981' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1981"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1982' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1982"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1983' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1983"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1984' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1984"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1985' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1985"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1986' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1986"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1987' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1987"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1988' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1988"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1989' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1989"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1990' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1990"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1991' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1991"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1992' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1992"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1993' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1993"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1994' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1994"
  GROUP BY "state"

  UNION ALL

  SELECT "state", COUNT("event_id") AS "event_count", '1995' AS "year"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1995"
  GROUP BY "state"

)

SELECT "state", SUM("event_count") AS "total_events"
FROM per_year_top_states
GROUP BY "state"
ORDER BY "total_events" DESC NULLS LAST
LIMIT 5;