-- 1) pick KIRP cases with known stage
WITH kirp_cases AS (
    SELECT 
        "case_barcode",
        "clinical_stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "disease_code" = 'KIRP'
      AND "clinical_stage" IS NOT NULL
),

-- 2) pull their MT-CO* expression values
expr AS (
    SELECT
        r."case_barcode",
        r."gene_name",
        r."HTSeq__FPKM_UQ"                             AS expr_val
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    WHERE r."gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
),

-- 3) pivot to one row per case
case_vectors AS (
    SELECT
        c."case_barcode",
        c."clinical_stage",
        MAX( CASE WHEN e."gene_name" = 'MT-CO1' THEN e.expr_val END ) AS "MT_CO1",
        MAX( CASE WHEN e."gene_name" = 'MT-CO2' THEN e.expr_val END ) AS "MT_CO2",
        MAX( CASE WHEN e."gene_name" = 'MT-CO3' THEN e.expr_val END ) AS "MT_CO3"
    FROM kirp_cases       c
    JOIN expr             e  ON e."case_barcode" = c."case_barcode"
    GROUP BY c."case_barcode", c."clinical_stage"
),

-- 4) deterministic 90 ∕ 10 split with HASH(case_barcode)
flagged AS (
    SELECT
        *,
        ABS( MOD( HASH("case_barcode"), 10) )          AS bucket          -- 0-9
    FROM case_vectors
),

train AS (
    SELECT * FROM flagged WHERE bucket <> 0            -- ~90 %
),
test  AS (
    SELECT * FROM flagged WHERE bucket  = 0            -- ~10 %
),

-- 5) centroid (stage-specific mean) in train set
centroids AS (
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS c1,
        AVG("MT_CO2") AS c2,
        AVG("MT_CO3") AS c3
    FROM train
    GROUP BY "clinical_stage"
),

-- 6) distance of every test case to every centroid
distances AS (
    SELECT
        t."case_barcode",
        c."clinical_stage",
        SQRT(   POWER(t."MT_CO1" - c.c1, 2)
              + POWER(t."MT_CO2" - c.c2, 2)
              + POWER(t."MT_CO3" - c.c3, 2) )          AS dist,
        ROW_NUMBER() OVER (PARTITION BY t."case_barcode"
                           ORDER BY SQRT( POWER(t."MT_CO1" - c.c1,2)
                                          + POWER(t."MT_CO2" - c.c2,2)
                                          + POWER(t."MT_CO3" - c.c3,2) ) ) AS rn
    FROM test t
    CROSS JOIN centroids c
)

-- 7) choose nearest centroid → predicted stage
SELECT
    "case_barcode",
    "clinical_stage"  AS "predicted_clinical_stage"
FROM distances
WHERE rn = 1
ORDER BY "case_barcode";