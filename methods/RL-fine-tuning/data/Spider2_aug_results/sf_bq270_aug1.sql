-- Task: List the unique action types and their counts from flattened hits data on January 1, 2017.
WITH sessions AS (
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170101
),
flattened_hits AS (
    SELECT
        TO_DATE(t."date", 'YYYYMMDD') AS "event_date",
        t."fullVisitorId",
        f.value:"eCommerceAction":"action_type"::STRING AS "action_type"
    FROM sessions t,
    LATERAL FLATTEN(input => t."hits") f
)
SELECT
    "action_type",
    COUNT(*) AS "count"
FROM flattened_hits
WHERE "event_date" = '2017-01-01'
GROUP BY "action_type";