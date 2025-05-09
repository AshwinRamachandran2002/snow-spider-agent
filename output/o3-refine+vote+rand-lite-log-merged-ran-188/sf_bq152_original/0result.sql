/*--------------------------------------------------------------------
  Copy‑number‑variant landscape of TCGA‑BRCA (GDC release 23)
  --------------------------------------------------------------------
  CN‑segments table:  TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.COPY_NUMBER_SEGMENT_MASKED
  NOTE:
       A ready‑made cytoband reference table is not available in   
       this environment, therefore each entire chromosome is used  
       as one “pseudo‑cytoband”.  Start = 1, End = max‑coordinate   
       observed for that chromosome in the CN‑segments table.      
--------------------------------------------------------------------*/
WITH brca_seg AS (                        /* TCGA‑BRCA segments */
    SELECT  "case_barcode",
            REPLACE("chromosome",'chr','')       AS "chromosome",   -- 1‑22,X,Y
            "start_pos",
            "end_pos",
            "segment_mean"
    FROM  TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.COPY_NUMBER_SEGMENT_MASKED
    WHERE "project_short_name" = 'TCGA-BRCA'
),                                                                  
cytobands AS (                    /* one “band” per chromosome  */
    SELECT  "chromosome",
            'chr'||"chromosome"          AS "cytoband",
            1                            AS "band_start",
            MAX("end_pos")               AS "band_end"
    FROM    brca_seg
    GROUP  BY "chromosome"
),                                                                  
overlap AS (                     /* bp overlap (segment × band) */
    SELECT  s."case_barcode",
            c."cytoband",
            LEAST(s."end_pos",c."band_end")
          - GREATEST(s."start_pos",c."band_start") + 1  AS "ov_len",
            POWER(2, s."segment_mean" + 1)              AS "cn_val"
    FROM   brca_seg  s
    JOIN   cytobands c
       ON  c."chromosome" = s."chromosome"
),                                                                  
band_case_avg AS (               /* weighted‑mean CN per band   */
    SELECT  "case_barcode",
            "cytoband",
            SUM("cn_val"* "ov_len") / SUM("ov_len")  AS "avg_cn"
    FROM    overlap
    GROUP  BY "case_barcode","cytoband"
),                                                                  
band_case_class AS (             /* round & classify CN state   */
    SELECT  "case_barcode",
            "cytoband",
            ROUND("avg_cn")                       AS "cn_round",
            CASE ROUND("avg_cn")
                 WHEN 0 THEN 'HOMDEL'
                 WHEN 1 THEN 'HETDEL'
                 WHEN 2 THEN 'DIPLOID'
                 WHEN 3 THEN 'GAIN'
                 ELSE        'AMP'
            END                                   AS "cnv_type"
    FROM    band_case_avg
),                                                                  
tot AS (                          /* number of BRCA cases       */
    SELECT COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM   brca_seg
),                                                                  
band_freq AS (                    /* % of cases per CNV class   */
    SELECT  c."cytoband",
            c."band_start",
            c."band_end",
            ROUND(100*COUNT_IF(b."cnv_type"='HOMDEL')/t."n_cases",2) AS "pct_homdel",
            ROUND(100*COUNT_IF(b."cnv_type"='HETDEL')/t."n_cases",2) AS "pct_hetdel",
            ROUND(100*COUNT_IF(b."cnv_type"='DIPLOID')/t."n_cases",2) AS "pct_diploid",
            ROUND(100*COUNT_IF(b."cnv_type"='GAIN')  /t."n_cases",2) AS "pct_gain",
            ROUND(100*COUNT_IF(b."cnv_type"='AMP')   /t."n_cases",2) AS "pct_amp"
    FROM   cytobands       c
    JOIN   band_case_class b  ON b."cytoband" = c."cytoband"
    CROSS  JOIN tot         t
    GROUP  BY c."cytoband", c."band_start", c."band_end", t."n_cases"
)
SELECT  "cytoband"    AS "CYTOBAND",
        "band_start"  AS "BAND_START",
        "band_end"    AS "BAND_END",
        "pct_homdel"  AS "HOMO_DEL_%",
        "pct_hetdel"  AS "HETERO_DEL_%",
        "pct_diploid" AS "DIPLOID_%",
        "pct_gain"    AS "GAIN_%",
        "pct_amp"     AS "AMPLIFICATION_%"
FROM    band_freq
ORDER BY TRY_TO_NUMBER(REGEXP_REPLACE("cytoband",'[^0-9]','')),   -- chrom #
         "band_start";