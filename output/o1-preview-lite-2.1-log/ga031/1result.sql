WITH event_pages AS (
    SELECT
        (SELECT ep.value.int_value FROM UNNEST(events.event_params) ep WHERE ep.key = 'ga_session_id') AS session_id,
        LOWER((SELECT ep.value.string_value FROM UNNEST(events.event_params) ep WHERE ep.key = 'page_title')) AS page_title,
        events.event_timestamp
    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS events
),
sessions_first_page AS (
    SELECT
        session_id,
        page_title
    FROM (
        SELECT
            session_id,
            page_title,
            ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY event_timestamp ASC) AS rn
        FROM
            event_pages
        WHERE
            session_id IS NOT NULL
    )
    WHERE rn = 1
),
sessions_started_with_home AS (
    SELECT
        session_id
    FROM
        sessions_first_page
    WHERE
        page_title = 'home'
),
sessions_with_checkout AS (
    SELECT DISTINCT
        session_id
    FROM
        event_pages
    WHERE
        page_title = 'checkout confirmation'
        AND session_id IS NOT NULL
)

SELECT
    ROUND(
        SAFE_MULTIPLY(
            SAFE_DIVIDE(
                (SELECT COUNT(DISTINCT session_id) FROM sessions_started_with_home WHERE session_id IN (SELECT session_id FROM sessions_with_checkout)),
                (SELECT COUNT(DISTINCT session_id) FROM sessions_started_with_home)
            ),
            100
        ),
        4
    ) AS conversion_rate;