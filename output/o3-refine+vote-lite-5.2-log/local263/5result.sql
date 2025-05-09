WITH stack_vs_nonstack AS (
    /* 1. For every (name, version, step) keep the best non‑Stack score and the Stack score */
    SELECT
        name,
        version,
        step,
        MAX(CASE WHEN model = 'Stack'      THEN test_score END) AS stack_score,
        MAX(CASE WHEN model <> 'Stack'     THEN test_score END) AS best_nonstack_score
    FROM model_score
    GROUP BY name, version, step
),
model_level_status AS (
    /* 2. Classify every (name, version) as strong or soft */
    SELECT
        name,
        version,
        CASE
            WHEN MAX(CASE WHEN stack_score > best_nonstack_score THEN 1 END) = 1
                 THEN 'strong'
            WHEN MAX(CASE WHEN stack_score = best_nonstack_score THEN 1 END) = 1
                 THEN 'soft'
        END AS status
    FROM stack_vs_nonstack
    GROUP BY name, version
),
l1_by_model AS (
    /* 3. Get the (usually unique) L1_model for every (name, version) */
    SELECT DISTINCT
        name,
        version,
        L1_model
    FROM model
),
l1_with_status AS (
    /* 4. Attach the status to each L1_model occurrence */
    SELECT
        l1.L1_model,
        ms.status
    FROM l1_by_model AS l1
    JOIN model_level_status AS ms USING (name, version)
    WHERE ms.status IS NOT NULL
),
l1_status_count AS (
    /* 5. Count how many times each L1_model appears in every status */
    SELECT
        status,
        L1_model,
        COUNT(*) AS cnt
    FROM l1_with_status
    GROUP BY status, L1_model
),
ranked AS (
    /* 6. Rank the L1_models by frequency per status */
    SELECT
        status,
        L1_model,
        cnt,
        RANK() OVER (PARTITION BY status ORDER BY cnt DESC) AS rk
    FROM l1_status_count
)
SELECT
    status,
    L1_model,
    cnt
FROM ranked
WHERE rk = 1          -- highest occurrence per status; ties are kept
ORDER BY status, L1_model;