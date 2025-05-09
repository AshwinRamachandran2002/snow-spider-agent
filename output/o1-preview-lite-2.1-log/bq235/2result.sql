SELECT
    inpatient.provider_id,
    inpatient.provider_name,
    ROUND((inpatient.total_inpatient_payments + outpatient.total_outpatient_payments), 4) AS combined_total_payments
FROM
    (
        SELECT
            provider_id,
            provider_name,
            SUM(total_discharges * average_total_payments) AS total_inpatient_payments
        FROM
            `bigquery-public-data.cms_medicare.inpatient_charges_2014`
        GROUP BY
            provider_id,
            provider_name
    ) AS inpatient
JOIN
    (
        SELECT
            provider_id,
            SUM(outpatient_services * average_total_payments) AS total_outpatient_payments
        FROM
            `bigquery-public-data.cms_medicare.outpatient_charges_2014`
        GROUP BY
            provider_id
    ) AS outpatient
ON
    inpatient.provider_id = outpatient.provider_id
ORDER BY
    combined_total_payments DESC
LIMIT 1;