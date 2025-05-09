/*----------------------------------------------------------------
  Chromosome-level CNV summary for TCGA-BRCA (uses available tables)
----------------------------------------------------------------*/

WITH brca_segments AS (                   /* 1 ─ copy-number segments   */
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "segment_mean"                    /* log2-ratio */
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED_R14"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

cytobands AS (                            /* 2 ─ treat whole chromosome */
    SELECT
        "chromosome",
        0              AS "band_start",
        999999999      AS "band_end",     -- arbitrary large end
        "chromosome"   AS "cytoband_name" -- use chromosome as “band”
    FROM ( SELECT DISTINCT "chromosome" FROM brca_segments )
),

band_case_weighted AS (                   /* 3 ─ overlap-weighted mean  */
    SELECT
        c."cytoband_name",
        c."chromosome",
        c."band_start",
        c."band_end",
        s."case_barcode",

        SUM(
              ( LEAST(s."end_pos" , c."band_end")
              - GREATEST(s."start_pos", c."band_start") + 1)
              * s."segment_mean"
        )                                   AS "wt_sum",

        SUM(
              LEAST(s."end_pos" , c."band_end")
            - GREATEST(s."start_pos", c."band_start") + 1
        )                                   AS "ov_len"
    FROM brca_segments  s
    JOIN cytobands      c
      ON  s."chromosome" = c."chromosome"
     AND s."end_pos"   >= c."band_start"
     AND s."start_pos" <= c."band_end"
    GROUP BY
        c."cytoband_name", c."chromosome",
        c."band_start",   c."band_end",
        s."case_barcode"
),

band_case_cnv AS (                        /* 4 ─ absolute copy number   */
    SELECT
        "cytoband_name",
        "chromosome",
        "band_start",
        "band_end",
        "case_barcode",
        ROUND( 2 * POWER( 2 , "wt_sum" / NULLIF("ov_len",0) ) )  AS "copy_number"
    FROM band_case_weighted
),

band_case_class AS (                      /* 5 ─ discrete CNV categories*/
    SELECT
        "cytoband_name",
        "chromosome",
        "band_start",
        "band_end",
        "case_barcode",
        CASE
            WHEN "copy_number" = 0 THEN 'Homozygous Deletion'
            WHEN "copy_number" = 1 THEN 'Heterozygous Deletion'
            WHEN "copy_number" = 2 THEN 'Diploid'
            WHEN "copy_number" = 3 THEN 'Gain'
            WHEN "copy_number" >  3 THEN 'Amplification'
            ELSE                       'Unknown'
        END AS "cnv_type"
    FROM band_case_cnv
),

band_summary AS (                         /* 6 ─ % of cases per CNV type*/
    SELECT
        "cytoband_name",
        "chromosome",
        "band_start",
        "band_end",
        ROUND( 100.0 * SUM( CASE WHEN "cnv_type" = 'Homozygous Deletion'   THEN 1 ELSE 0 END )
               / COUNT(DISTINCT "case_barcode"), 2) AS "homdel_pct",
        ROUND( 100.0 * SUM( CASE WHEN "cnv_type" = 'Heterozygous Deletion' THEN 1 ELSE 0 END )
               / COUNT(DISTINCT "case_barcode"), 2) AS "hetdel_pct",
        ROUND( 100.0 * SUM( CASE WHEN "cnv_type" = 'Diploid'               THEN 1 ELSE 0 END )
               / COUNT(DISTINCT "case_barcode"), 2) AS "diploid_pct",
        ROUND( 100.0 * SUM( CASE WHEN "cnv_type" = 'Gain'                  THEN 1 ELSE 0 END )
               / COUNT(DISTINCT "case_barcode"), 2) AS "gain_pct",
        ROUND( 100.0 * SUM( CASE WHEN "cnv_type" = 'Amplification'         THEN 1 ELSE 0 END )
               / COUNT(DISTINCT "case_barcode"), 2) AS "amp_pct"
    FROM band_case_class
    GROUP BY
        "cytoband_name", "chromosome", "band_start", "band_end"
)

SELECT *
FROM band_summary
ORDER BY
    CASE
        WHEN TRY_TO_NUMBER("chromosome") IS NOT NULL
             THEN TRY_TO_NUMBER("chromosome")
        WHEN "chromosome" = 'X' THEN 100
        WHEN "chromosome" = 'Y' THEN 101
        ELSE 102
    END;