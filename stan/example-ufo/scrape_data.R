## FROM: 
library('tidyverse')

file_path <- 'data/'
cencsus_file_dir <- 'output/'
population_file <- 'population.csv'
sighting_file <- 'ufo_sighting.csv'
joined_file <- 'population_sighting_by_year.csv'

# Adjust population data ----------------------------------------------------

# Read all CSV files
census_files <- list.files(paste0(file_path, cencsus_file_dir), full.names=TRUE)

# Join all data into a single table
census_data <- census_files %>%  map(read_csv, progress = FALSE)

census_data <- census_data %>%
  .[census_data %>% map_dbl(function(x) {dim(x)[1]}) > 0] %>%
  reduce(full_join, by="DATE") %>%                                               # Reduce (left to right) running a full join
  dplyr::arrange( DATE ) %>%                                                     # Sort by date
  gather(key="state", value="population", -DATE ) %>%                           # Gather to long format
  transmute( date=DATE, state=str_replace( state, "POP", "" ), population ) %>%  # Rename and tidy variables and names
  write_csv(paste0(file_path, population_file))


# Scrape UFO sightings ----------------------------------------------------
library(jsonlite)
library(rvest)

website_prefix <- 'http://www.nuforc.org/webreports/'
page_event_by_date <- 'ndxevent.html'

## Read all links to pages by date (only ##/#### links)
html_nodes <- paste0(website_prefix, page_event_by_date) %>% 
  read_html() %>% 
  html_nodes(xpath = '//table') %>% 
  html_nodes(xpath = '//a')

## Pull URLs for processing
links <- tibble(
  date = html_nodes %>% html_text(), 
  link = html_nodes %>% html_attr('href')
) %>% 
  filter(grepl('[0-9]{2}[/][0-9]{4}', date)) %>% 
  pull(link)

## It's actually faster to append to disk (and watch the progress)
pb <- txtProgressBar(min = 1, max = length(links), title = 'Processing updates', width = 50)

for (i in 1:length(links)) {
  setTxtProgressBar(pb, value = i)
  
  ## Extract the table
  y <- paste0(website_prefix, links[[i]]) %>% 
    read_html() %>% 
    html_nodes(xpath = '//table') %>% 
    html_table() %>% 
    .[[1]]
  
  ## Convert colnames to something readable
  colnames(y) <- gsub('[^A-Za-z0-9]+', '_', colnames(y)) %>% tolower()
  
  ## Write to disk (append if not i==1)
  y %>% 
    write_csv(
      paste0(file_path, 'ufo_sighting.csv'),
      append = (i!=1),
      col_names = (i==1)
  )
}

## Fix dates / times 
d <- read_csv('data/ufo_sighting.csv')
print(dim(d))
d$timestamp <- d$date_time %>% lubridate::mdy_hm()
d$timestamp[is.na(d$timestamp)] <- d$date_time[is.na(d$timestamp)] %>% lubridate::mdy()
d$posted <- d$posted %>% lubridate::mdy()

## Test: years before 1970
tibble(
  before = d$timestamp[d$timestamp > Sys.time()],
  after =  d$timestamp[d$timestamp > Sys.time()] - (99*365 + 25)*24*60*60
) %>% 
  mutate(diff = as.numeric(before - after)) %>% 
  pull(diff) %>% 
  summary()

d$timestamp[d$timestamp > Sys.time()] <- d$timestamp[d$timestamp > Sys.time()] - (99*365 + 25)*24*60*60

d %>% pull(timestamp) %>% hist(breaks = 50)
d %>% pull(posted) %>% hist(breaks = 50)

## Write to disk
d %>% 
  select(-date_time) %>% 
  write_csv('data/ufo_sighting.csv')

## Cleanup
rm(d, html_nodes, pb, x, y, i, links, page_event_by_date, website_prefix)

# Join data on states -----------------------------------------------------

d <- read_csv('data/population.csv') %>% 
  inner_join(
    read_csv('data/ufo_sighting.csv') %>% 
      select(timestamp, state) %>% 
      mutate(year = timestamp %>% strftime('%Y-01-01') %>% as.Date()) %>% 
      count(year, state),
    by = c('date' = 'year', 'state' = 'state')
  )

d %>% ggplot(aes(x = date, y = n, color = state)) %>% +geom_point()

d %>% write_csv(paste0(file_path, joined_file))

## Visualisation
d %>% 
  ggplot(aes(x = population, y = n)) %>% 
  +geom_point(aes(color = state)) %>% 
  +geom_smooth( method="lm" )
