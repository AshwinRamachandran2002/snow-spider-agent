/*  Digital slide‑level metadata for TCGA‑LUAD / TCGA‑LUSC frozen‑section
    SM‑modality volume images that
      • are JPEG or JPEG‑2000 compressed
      • have “Embedding medium = Tissue freezing medium”
      • contain either normal (SCT 17621005) or tumour (SCT 86049000) tissue
*/

WITH selected AS (
    SELECT
        a."SOPInstanceUID"                                       AS instance_id,
        a."SeriesInstanceUID"                                    AS digital_slide_id,
        a."StudyInstanceUID"                                     AS case_id,
        a."PatientID"                                            AS patient_id,
        a."collection_id"                                        AS collection_id,
        a."gcs_url"                                              AS gcs_url,
        a."Columns"                                              AS width,
        a."Rows"                                                 AS height,
        /* pixel spacing : try PixelSpacing first, fall back to NominalScannedPixelSpacing */
        COALESCE(
            NULLIF(REGEXP_REPLACE(TO_VARCHAR(a."PixelSpacing"),              '[\\[\\]\\s]',''), ''),
            NULLIF(REGEXP_REPLACE(TO_VARCHAR(a."NominalScannedPixelSpacing"),'[\\[\\]\\s]',''), '')
        )                                                        AS pixel_spacing_mm_per_px,
        /* map transfer‑syntax → compression type */
        CASE 
            WHEN a."TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.90',
                                           '1.2.840.10008.1.2.4.91')        THEN 'jpeg2000'
            ELSE                                                             'jpeg'
        END                                                      AS compression_type,
        /* physical slide identifier extracted from the specimen block */
        PARSE_JSON(sds.value)::OBJECT:"SpecimenIdentifier"::STRING AS physical_slide_id,
        /* tissue type based on modifier code */
        CASE
            WHEN sds.value::STRING ILIKE '%"86049000"%'           THEN 'tumor'
            ELSE                                                   'normal'
        END                                                      AS tissue_type,
        /* cancer sub‑type derived from collection */
        CASE a."collection_id"
            WHEN 'tcga_luad' THEN 'luad'
            ELSE                'lscc'
        END                                                      AS cancer_subtype
    FROM  "IDC"."IDC_V17"."DICOM_ALL"    a,
          LATERAL FLATTEN(input => a."SpecimenDescriptionSequence") sds
    WHERE a."Modality"             =  'SM'
      AND a."VolumetricProperties" =  'VOLUME'
      AND a."collection_id"       IN ('tcga_luad','tcga_lusc')
      /* JPEG & JPEG‑2000 transfer syntaxes only */
      AND a."TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.50',    -- JPEG baseline
                                    '1.2.840.10008.1.2.4.51',    -- JPEG extended
                                    '1.2.840.10008.1.2.4.57',    -- JPEG lossless
                                    '1.2.840.10008.1.2.4.70',    -- JPEG lossless SV1
                                    '1.2.840.10008.1.2.4.80',    -- JPEG‑LS lossless
                                    '1.2.840.10008.1.2.4.81',    -- JPEG‑LS near‑lossless
                                    '1.2.840.10008.1.2.4.90',    -- JPEG‑2000 lossless
                                    '1.2.840.10008.1.2.4.91')    -- JPEG‑2000
      /* “Embedding medium : Tissue freezing medium” must be present              */
      AND LOWER(sds.value::STRING) LIKE '%embedding medium%'
      AND LOWER(sds.value::STRING) LIKE '%tissue freezing medium%'
      /* modifier code for normal or tumour only                                   */
      AND (sds.value::STRING LIKE '%"17621005"%' OR sds.value::STRING LIKE '%"86049000"%')
)

SELECT DISTINCT
       digital_slide_id            AS "digital_slide_id",
       case_id                     AS "case_id",
       physical_slide_id           AS "physical_slide_id",
       patient_id                  AS "patient_id",
       collection_id               AS "collection_id",
       instance_id                 AS "instance_id",
       gcs_url                     AS "gcs_url",
       width                       AS "width",
       height                      AS "height",
       pixel_spacing_mm_per_px     AS "pixel_spacing_mm_per_px",
       compression_type            AS "compression_type",
       tissue_type                 AS "tissue_type",
       cancer_subtype              AS "cancer_subtype"
FROM   selected
ORDER BY instance_id ASC;