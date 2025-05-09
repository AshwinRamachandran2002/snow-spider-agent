WITH exp_status AS (                      -- classify each experiment (name,version)
    SELECT
        "name",
        "version",
        CASE
            WHEN MAX(CASE WHEN "model" NOT LIKE '%Stack%' THEN "test_score" END)
                 <  MAX(CASE WHEN "model"     LIKE '%Stack%' THEN "test_score" END) THEN 'strong'
            WHEN MAX(CASE WHEN "model" NOT LIKE '%Stack%' THEN "test_score" END)
                 =  MAX(CASE WHEN "model"     LIKE '%Stack%' THEN "test_score" END) THEN 'soft'
        END AS status
    FROM "model_score"
    GROUP BY "name", "version"
),
status_model AS (                         -- link status to the distinct L1_model used in the experiment
    SELECT DISTINCT
        es.status,
        es."name",
        es."version",
        m."L1_model"
    FROM exp_status AS es
    JOIN "model"  AS m
      ON es."name"    = m."name"
     AND es."version" = m."version"
    WHERE es.status IN ('strong','soft')   -- keep only classified experiments
),
model_counts AS (                          -- count experiments per (status,L1_model)
    SELECT
        status,
        "L1_model",
        COUNT(*) AS occurrences
    FROM status_model
    GROUP BY status, "L1_model"
)
SELECT
    status,
    "L1_model",
    occurrences
FROM model_counts
WHERE occurrences = (
        SELECT MAX(occurrences)
        FROM model_counts AS mc2
        WHERE mc2.status = model_counts.status
      )
ORDER BY status;