## FROM: https://www.weirddatascience.net/index.php/2019/04/08/bayes-vs-the-invaders-part-two-abnormal-distributions/
library('tidyverse')
library('rstan')

file_path <- 'data/'
joined_file <- 'population_sighting_by_year.csv'
# min_chain = 1000
post_sample_n <- 100 # for showing posterior dist 
start_date <- as.Date('1970-01-01')


# Data --------------------------------------------------------------------
d <- read_csv(paste0(file_path, joined_file)) %>% 
  filter(date >= start_date) %>% 
  drop_na()

d %>% 
  ggplot(aes(x = date)) %>% 
  +geom_line(aes(y = population, colour = state))

d %>% 
  ggplot(aes(x = date)) %>% 
  +geom_line(aes(y = n, colour = state))

stan_data <- list(
  obs = dim(d)[1],
  population = d %>% pull(population),
  sightings = d %>% pull(n)
)

