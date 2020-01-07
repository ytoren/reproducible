## FROM: https://www.weirddatascience.net/index.php/2019/04/17/bayes-vs-the-invaders-part-three-the-parallax-view/
library('tidyverse')
library('tidybayes')
library('rstan')
library('bayesplot')
library('loo')

path <- 'stan-example-ufo/'
joined_file <- 'population_sighting_by_year.csv'
# min_chain = 1000
post_sample_n <- 100 # for showing posterior dist 
start_date <- as.Date('1970-01-01')
source(paste0(path, 'stan_aux_funs.R'))

# Data --------------------------------------------------------------------
d <- read_csv(paste0(file_path, 'data/', joined_file)) %>% 
  filter(date >= start_date) %>% 
  drop_na()

stan_data <- list(
  n_obs = dim(d)[1],
  n_states = n_distinct(d$state),
  state = as_factor(d$state) %>% as.numeric(),
  population = d$population,
  sightings = d$n
)

# Normal Hier -------------------------------------------------------
stan_hier_normal <- stan(
  file = paste0(path, 'normal_hier_model.stan'), 
  data = stan_data, 
  cores = 4
)

## diagnostics 
stan_hier_normal %>% traceplot(pars = c('alpha_mu', 'beta', 'sigma'), ncol = 1) # 'alpha_sd'

## posterior dist
stan_hier_normal %>% 
  summary(pars = c('alpha', 'alpha', 'beta', 'sigma')) %>% #_mu', 'alpha_sd
  .['summary']

stan_plot_overlay(stan_hier_normal, 'sightings_pred', y = d %>% pull(n))
stan_plot_model_fit(stan_hier_normal, par = 'mu', population = d$population, sightings = d$n)


# Negative Binomial Hier -------------------------------------------------------
stan_hier_nb <- stan(
  file = paste0(path, 'neg_binomial_hier_model.stan'), 
  data = stan_data, 
  cores = 4
)

## diagnostics 
stan_hier_nb %>% traceplot(pars = c('alpha_mu', 'alpha_sd','beta', 'phi'), ncol = 1)

## posterior dist
stan_hier_nb %>% 
  summary(pars = c('alpha', 'beta', 'sigma')) %>% 
  .['summary']

stan_plot_overlay(stan_nb, 'sightings_pred', y = d %>% pull(n))
stan_plot_model_fit(stan_nb, par = 'mu', population = d$population, sightings = d$n)

# Model Comparison --------------------------------------------------------
compare(stan_loo(stan_hier_normal), stan_loo(stan_hier_nb))
