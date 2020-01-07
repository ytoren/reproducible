#!/bin/sh
# Download US state-level population datasets from FRED
# State series names are stored in the file 'series_names' (downloaded from fred.stlouisfed.org)
# <https: fred.stlouisfed.org="" release?rid="118">
#
# The per-series requests is included below.</https:>

export IFS=$'\n'

# Download
for state_series in $(cat series_names.txt); do

  echo "https://fred.stlouisfed.org/graph/fredgraph.csv?id=$state_series&cosd=1900-01-01&coed=2018-01-01"
  curl -o "output/$state_series.csv" "https://fred.stlouisfed.org/graph/fredgraph.csv?id=$state_series&cosd=1900-01-01&coed=2018-01-01"

done
