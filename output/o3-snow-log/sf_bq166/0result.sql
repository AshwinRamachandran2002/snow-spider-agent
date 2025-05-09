/* ====  Cytoband-level CNV frequencies for TCGA-KIRC  ==== */
WITH total AS (                /* 1. total number of distinct cases */
    SELECT COUNT(DISTINCT "case_gdc_id") AS n_cases
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),
band_max AS (                  /* 2. per-case, per-cytoband maximum copy number */
    SELECT
        s."case_gdc_id"                AS case_id,
        c."cytoband_name"              AS cytoband,
        MAX(s."copy_number")           AS max_cn
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38" c
      ON s."chromosome" = c."chromosome"
     AND s."start_pos"   <= c."hg38_stop"
     AND s."end_pos"     >= c."hg38_start"
    WHERE s."project_short_name" = 'TCGA-KIRC'
    GROUP BY s."case_gdc_id", c."cytoband_name"
),
band_class AS (                /* 3. classify maxima into CNV sub-types */
    SELECT
        case_id,
        cytoband,
        CASE
            WHEN max_cn > 3 THEN 'Amplification'
            WHEN max_cn = 3 THEN 'Gain'
            WHEN max_cn = 2 THEN 'Normal'
            WHEN max_cn = 1 THEN 'Heterozygous Deletion'
            WHEN max_cn = 0 THEN 'Homozygous Deletion'
            ELSE 'Other'
        END AS cnv_type
    FROM band_max
),
band_counts AS (               /* 4. count distinct cases per (band, class) */
    SELECT
        cytoband,
        cnv_type,
        COUNT(DISTINCT case_id) AS case_count
    FROM band_class
    GROUP BY cytoband, cnv_type
)
SELECT                          /* 5. convert counts to % of total cases */
    bc.cytoband,
    bc.cnv_type,
    ROUND(100.0 * bc.case_count / t.n_cases, 2) AS percentage_of_cases
FROM band_counts bc
CROSS JOIN total t
ORDER BY                         /* sort by chromosome then band then class */
    CASE
        WHEN REGEXP_SUBSTR(bc.cytoband, '^[XY]') = 'X' THEN 23
        WHEN REGEXP_SUBSTR(bc.cytoband, '^[XY]') = 'Y' THEN 24
        ELSE TRY_TO_NUMBER(REGEXP_SUBSTR(bc.cytoband, '^[0-9]+'))
    END,
    bc.cytoband,
    bc.cnv_type;