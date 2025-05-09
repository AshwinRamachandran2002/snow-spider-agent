SELECT period, label_description, label_count
FROM (
    SELECT
        o.period,
        label.description AS label_description,
        COUNT(*) AS label_count,
        ROW_NUMBER() OVER (PARTITION BY o.period ORDER BY COUNT(*) DESC) AS rank_in_period
    FROM
        `bigquery-public-data.the_met.objects` AS o
    INNER JOIN
        `bigquery-public-data.the_met.vision_api_data` AS v
    ON
        o.object_id = v.object_id
    CROSS JOIN
        UNNEST(v.labelAnnotations) AS label
    WHERE
        o.period IS NOT NULL
    GROUP BY
        o.period, label.description
    HAVING
        COUNT(*) >= 50
)
WHERE rank_in_period <= 3
ORDER BY period, rank_in_period;