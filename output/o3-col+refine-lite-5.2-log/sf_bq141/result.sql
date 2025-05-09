/*---------------------------------------------------------------
  Predict TCGA‑KIRP clinical stage from MT‑CO1/2/3 expression
  -------------------------------------------------------------*/
WITH kirp_clin AS (   -- 1.  KIRP patients with a recorded stage
    SELECT
        "case_barcode",
        "clinical_stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "disease_code" = 'KIRP'
      AND "clinical_stage" IS NOT NULL
),
kirp_expr AS (        -- 2.  Expression rows for the three genes
    SELECT
        "case_barcode",
        "gene_name",
        "HTSeq__FPKM_UQ"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "gene_name" IN ('MT-CO3','MT-CO1','MT-CO2')
),
feat AS (             -- 3.  Pivot → one row / patient
    SELECT
        c."case_barcode",
        c."clinical_stage",
        MIN(CASE WHEN e."gene_name"='MT-CO1' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO1",
        MIN(CASE WHEN e."gene_name"='MT-CO2' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO2",
        MIN(CASE WHEN e."gene_name"='MT-CO3' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM kirp_clin c
    JOIN kirp_expr e
      ON c."case_barcode" = e."case_barcode"
    GROUP BY c."case_barcode", c."clinical_stage"
),
split AS (            -- 4.  90 / 10 split via HASH (stand‑in for FARM_FINGERPRINT)
    SELECT
        *,
        CASE WHEN MOD(ABS(HASH("case_barcode")),10) < 9 THEN 1 ELSE 0 END AS "is_train"
    FROM feat
),
centroid AS (         -- 5.  Stage‑specific average expression (training only)
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS "avg_MT_CO1",
        AVG("MT_CO2") AS "avg_MT_CO2",
        AVG("MT_CO3") AS "avg_MT_CO3"
    FROM split
    WHERE "is_train" = 1
    GROUP BY "clinical_stage"
),
test_pts AS (         -- 6.  Test‑set patients
    SELECT *
    FROM split
    WHERE "is_train" = 0
),
dists AS (            -- 7.  Distance of every test patient to every centroid
    SELECT
        t."case_barcode",
        s."clinical_stage"                                          AS "centroid_stage",
        SQRT(
              NVL(POWER(t."MT_CO1" - s."avg_MT_CO1",2),0)
            + NVL(POWER(t."MT_CO2" - s."avg_MT_CO2",2),0)
            + NVL(POWER(t."MT_CO3" - s."avg_MT_CO3",2),0)
        )                                                          AS "distance"
    FROM test_pts t
    CROSS JOIN centroid s
)
-- 8.  Pick closest centroid → predicted stage
SELECT
    "case_barcode",
    FIRST_VALUE("centroid_stage") 
        OVER (PARTITION BY "case_barcode" ORDER BY "distance")     AS "predicted_clinical_stage"
FROM dists
QUALIFY ROW_NUMBER() OVER (PARTITION BY "case_barcode" ORDER BY "distance") = 1
ORDER BY "case_barcode";