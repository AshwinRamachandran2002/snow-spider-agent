-- Task: Which 5 states had the most storm events in 1980? Please use state abbreviations.
SELECT "state", COUNT("event_id") AS "event_count"
FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1980"
GROUP BY "state"
ORDER BY "event_count" DESC NULLS LAST
LIMIT 5;