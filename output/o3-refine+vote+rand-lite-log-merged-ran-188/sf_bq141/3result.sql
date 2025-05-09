-- Predict KIRP clinical stage from MT-CO* expression
WITH kirp AS (          -- 1)  Eligible KIRP cases + hash bucket
    SELECT
        "case_barcode",
        "clinical_stage",
        MOD(ABS(HASH("case_barcode")),10)         AS bucket          -- 0-9 buckets
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "project_short_name" = 'TCGA-KIRP'
      AND "disease_code"       = 'KIRP'
      AND "clinical_stage" IS NOT NULL
), expr AS (            -- 2)  Pivot MT-CO1/2/3 FPKM-UQ per case
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name" = 'MT-CO1' THEN "HTSeq__FPKM_UQ" END) AS mtco1,
        MAX(CASE WHEN "gene_name" = 'MT-CO2' THEN "HTSeq__FPKM_UQ" END) AS mtco2,
        MAX(CASE WHEN "gene_name" = 'MT-CO3' THEN "HTSeq__FPKM_UQ" END) AS mtco3
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "project_short_name" = 'TCGA-KIRP'
      AND "gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
    GROUP BY "case_barcode"
), kirp_expr AS (       -- 3)  Combine clinical & expression
    SELECT
        k."case_barcode",
        k."clinical_stage",
        k.bucket,
        e.mtco1, e.mtco2, e.mtco3
    FROM kirp k
    JOIN expr e
      ON k."case_barcode" = e."case_barcode"
), stage_avg AS (       -- 4)  Stage-specific averages from 90 % training set
    SELECT
        "clinical_stage",
        AVG(mtco1) AS avg_mtco1,
        AVG(mtco2) AS avg_mtco2,
        AVG(mtco3) AS avg_mtco3
    FROM kirp_expr
    WHERE bucket <> 0                       -- buckets 1-9  → training (≈90 %)
    GROUP BY "clinical_stage"
), test_patients AS (   -- 5)  10 % hold-out test set
    SELECT *
    FROM kirp_expr
    WHERE bucket = 0                        -- bucket 0 → test (≈10 %)
), test_vs_stage AS (   -- 6)  Distance of each test pt to every stage centroid
    SELECT
        t."case_barcode",
        s."clinical_stage" AS stage_candidate,
        SQRT(
              POWER(COALESCE(t.mtco1,0) - COALESCE(s.avg_mtco1,0),2)
            + POWER(COALESCE(t.mtco2,0) - COALESCE(s.avg_mtco2,0),2)
            + POWER(COALESCE(t.mtco3,0) - COALESCE(s.avg_mtco3,0),2)
        ) AS distance
    FROM test_patients t
    CROSS JOIN stage_avg s
), ranked AS (          -- 7)  Pick nearest stage for each patient
    SELECT
        "case_barcode",
        stage_candidate,
        distance,
        ROW_NUMBER() OVER (PARTITION BY "case_barcode"
                           ORDER BY distance ASC) AS rn
    FROM test_vs_stage
)
-- 8)  Final prediction list
SELECT
    "case_barcode",
    stage_candidate AS "predicted_clinical_stage"
FROM ranked
WHERE rn = 1
ORDER BY "case_barcode";