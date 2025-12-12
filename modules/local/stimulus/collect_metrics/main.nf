process COLLECT_METRICS {
    tag "collect_metrics"
    label 'process_low'

    input:
    path(metrics_files)

    output:
    path("combined_metrics.csv"), emit: combined

    script:
    """
    # Get header from first file
    head -1 \$(ls *.csv | head -1) > combined_metrics.csv
    # Append data rows from all files (skip headers)
    tail -q -n +2 *.csv >> combined_metrics.csv
    """

    stub:
    """
    echo "transform_id,loss,accuracy" > combined_metrics.csv
    """
}
