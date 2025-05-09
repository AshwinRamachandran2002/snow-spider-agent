/*  Chi-square statistic for association between histological type
    and reliable CDH1-mutation status in BRCA patients               */

WITH clin AS (               -- clinical BRCA cases with known histology
    SELECT
        c."bcr_patient_barcode"      AS "ParticipantBarcode",
        c."histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    WHERE c."acronym" = 'BRCA'
      AND c."histological_type" IS NOT NULL
),
mut AS (                      -- patients carrying a PASS CDH1 mutation
    SELECT DISTINCT
        m."ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    WHERE m."Study"        = 'BRCA'
      AND m."Hugo_Symbol"  = 'CDH1'
      AND m."FILTER"       = 'PASS'
),
data AS (                     -- build mutation status per patient
    SELECT
        c."ParticipantBarcode",
        c."histological_type",
        IFF(m."ParticipantBarcode" IS NOT NULL,'Mutated','Wildtype') AS "mutation_status"
    FROM clin c
    LEFT JOIN mut m
           ON c."ParticipantBarcode" = m."ParticipantBarcode"
),
-- row/column totals and filters (keep marginals > 10)
row_totals AS (
    SELECT "histological_type", COUNT(*) AS "row_total"
    FROM data
    GROUP BY "histological_type"
),
col_totals AS (
    SELECT "mutation_status",  COUNT(*) AS "col_total"
    FROM data
    GROUP BY "mutation_status"
),
filt_rows AS (
    SELECT * FROM row_totals WHERE "row_total" > 10
),
filt_cols AS (
    SELECT * FROM col_totals WHERE "col_total" > 10
),
filtered_data AS (            -- data after marginal filters
    SELECT d.*
    FROM data d
    JOIN filt_rows r ON d."histological_type" = r."histological_type"
    JOIN filt_cols c ON d."mutation_status"   = c."mutation_status"
),
contingency AS (              -- observed counts nᵢⱼ
    SELECT
        "histological_type",
        "mutation_status",
        COUNT(*) AS "obs"
    FROM filtered_data
    GROUP BY "histological_type", "mutation_status"
),
row_tot2 AS (                 -- row totals after filtering
    SELECT "histological_type", SUM("obs") AS "row_total"
    FROM contingency
    GROUP BY "histological_type"
),
col_tot2 AS (                 -- column totals after filtering
    SELECT "mutation_status",  SUM("obs") AS "col_total"
    FROM contingency
    GROUP BY "mutation_status"
),
grand_tot AS (                -- grand total N
    SELECT SUM("obs") AS "grand_total" FROM contingency
),
chi_parts AS (                -- χ² components per cell
    SELECT
        c."histological_type",
        c."mutation_status",
        POW( c."obs"
           - (rt."row_total" * ct."col_total") / gt."grand_total", 2)
        / ( (rt."row_total" * ct."col_total") / gt."grand_total")   AS "chi_component"
    FROM contingency  c
    JOIN row_tot2    rt USING ("histological_type")
    JOIN col_tot2    ct USING ("mutation_status")
    CROSS JOIN grand_tot gt
)
SELECT SUM("chi_component") AS "chi_square_value"
FROM   chi_parts;