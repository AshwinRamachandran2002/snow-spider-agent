WITH
state_codes AS (
    SELECT 1 AS state_code, 'Alabama' AS state_name UNION ALL
    SELECT 2,'Alaska' UNION ALL
    SELECT 4,'Arizona' UNION ALL
    SELECT 5,'Arkansas' UNION ALL
    SELECT 6,'California' UNION ALL
    SELECT 8,'Colorado' UNION ALL
    SELECT 9,'Connecticut' UNION ALL
    SELECT 10,'Delaware' UNION ALL
    SELECT 12,'Florida' UNION ALL
    SELECT 13,'Georgia' UNION ALL
    SELECT 15,'Hawaii' UNION ALL
    SELECT 16,'Idaho' UNION ALL
    SELECT 17,'Illinois' UNION ALL
    SELECT 18,'Indiana' UNION ALL
    SELECT 19,'Iowa' UNION ALL
    SELECT 20,'Kansas' UNION ALL
    SELECT 21,'Kentucky' UNION ALL
    SELECT 22,'Louisiana' UNION ALL
    SELECT 23,'Maine' UNION ALL
    SELECT 24,'Maryland' UNION ALL
    SELECT 25,'Massachusetts' UNION ALL
    SELECT 26,'Michigan' UNION ALL
    SELECT 27,'Minnesota' UNION ALL
    SELECT 28,'Mississippi' UNION ALL
    SELECT 29,'Missouri' UNION ALL
    SELECT 30,'Montana' UNION ALL
    SELECT 31,'Nebraska' UNION ALL
    SELECT 32,'Nevada' UNION ALL
    SELECT 33,'New Hampshire' UNION ALL
    SELECT 34,'New Jersey' UNION ALL
    SELECT 35,'New Mexico' UNION ALL
    SELECT 36,'New York' UNION ALL
    SELECT 37,'North Carolina' UNION ALL
    SELECT 38,'North Dakota' UNION ALL
    SELECT 39,'Ohio' UNION ALL
    SELECT 40,'Oklahoma' UNION ALL
    SELECT 41,'Oregon' UNION ALL
    SELECT 42,'Pennsylvania' UNION ALL
    SELECT 44,'Rhode Island' UNION ALL
    SELECT 45,'South Carolina' UNION ALL
    SELECT 46,'South Dakota' UNION ALL
    SELECT 47,'Tennessee' UNION ALL
    SELECT 48,'Texas' UNION ALL
    SELECT 49,'Utah' UNION ALL
    SELECT 50,'Vermont' UNION ALL
    SELECT 51,'Virginia' UNION ALL
    SELECT 53,'Washington' UNION ALL
    SELECT 54,'West Virginia' UNION ALL
    SELECT 55,'Wisconsin' UNION ALL
    SELECT 56,'Wyoming' UNION ALL
    SELECT 60,'American Samoa' UNION ALL
    SELECT 66,'Guam' UNION ALL
    SELECT 69,'Northern Mariana Islands' UNION ALL
    SELECT 72,'Puerto Rico' UNION ALL
    SELECT 78,'US Virgin Islands'
),
latest_timberland_evaluations AS (
    SELECT
        pe.state_code,
        MAX(pe.end_inventory_year) AS latest_year
    FROM
        `bigquery-public-data.usfs_fia.population_evaluation` AS pe
    WHERE
        pe.timberland_only = 'Y'
    GROUP BY
        pe.state_code
),
latest_timberland_evaluations_with_seq AS (
    SELECT
        pe.state_code,
        pe.evaluation_sequence_number,
        pe.evaluation_group_sequence_number AS evaluation_group,
        pe.end_inventory_year
    FROM
        `bigquery-public-data.usfs_fia.population_evaluation` AS pe
    JOIN
        latest_timberland_evaluations AS lte
        ON pe.state_code = lte.state_code
            AND pe.end_inventory_year = lte.latest_year
    WHERE
        pe.timberland_only = 'Y'
),
latest_forestland_evaluations AS (
    SELECT
        pe.state_code,
        MAX(pe.end_inventory_year) AS latest_year
    FROM
        `bigquery-public-data.usfs_fia.population_evaluation` AS pe
    WHERE
        pe.land_only = 'Y'
    GROUP BY
        pe.state_code
),
latest_forestland_evaluations_with_seq AS (
    SELECT
        pe.state_code,
        pe.evaluation_sequence_number,
        pe.evaluation_group_sequence_number AS evaluation_group,
        pe.end_inventory_year
    FROM
        `bigquery-public-data.usfs_fia.population_evaluation` AS pe
    JOIN
        latest_forestland_evaluations AS lfe
    ON pe.state_code = lfe.state_code
        AND pe.end_inventory_year = lfe.latest_year
    WHERE
        pe.land_only = 'Y'
),
timberland_total_acres AS (
    SELECT
        ltews.state_code,
        ltews.evaluation_group,
        SUM(peu.land_area_within_the_estimation_unit) AS total_acres
    FROM
        latest_timberland_evaluations_with_seq AS ltews
    JOIN
        `bigquery-public-data.usfs_fia.population_estimation_unit` AS peu
    ON
        ltews.evaluation_sequence_number = peu.evaluation_sequence_number
    GROUP BY
        ltews.state_code, ltews.evaluation_group
),
forestland_total_acres AS (
    SELECT
        lfe.state_code,
        lfe.evaluation_group,
        SUM(peu.land_area_within_the_estimation_unit) AS total_acres
    FROM
        latest_forestland_evaluations_with_seq AS lfe
    JOIN
        `bigquery-public-data.usfs_fia.population_estimation_unit` AS peu
    ON
        lfe.evaluation_sequence_number = peu.evaluation_sequence_number
    GROUP BY
        lfe.state_code, lfe.evaluation_group
),
timberland_top_state AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_acres DESC) AS rn
    FROM
        timberland_total_acres
),
forestland_top_state AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_acres DESC) AS rn
    FROM
        forestland_total_acres
)
SELECT
    CAST(t.state_code AS INT64) AS state_code,
    CAST(t.evaluation_group AS INT64) AS evaluation_group,
    s.state_name,
    ROUND(t.total_acres, 4) AS total_acres
FROM
    timberland_top_state AS t
JOIN
    state_codes AS s
ON t.state_code = s.state_code
WHERE t.rn = 1
UNION ALL
SELECT
    CAST(f.state_code AS INT64) AS state_code,
    CAST(f.evaluation_group AS INT64) AS evaluation_group,
    s.state_name,
    ROUND(f.total_acres, 4) AS total_acres
FROM
    forestland_top_state AS f
JOIN
    state_codes AS s
ON f.state_code = s.state_code
WHERE f.rn = 1;